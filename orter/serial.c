#ifdef __MACH__
#define ORTER_PLATFORM_UNIX
#endif
#ifdef __unix__
/* to get CRTSCTS */
#define _DEFAULT_SOURCE
#define ORTER_PLATFORM_UNIX
#endif

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef __linux__
#include <sys/file.h>
#endif
#include <fcntl.h>
#include <getopt.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>

#include "io.h"
#include "serial.h"

/* opts */
static int            echo = 0;
static int            icrnl = 0;
static int            ocrnl = 0;
static int            olfcr = 0;
static int            odelbs = 0;

/* serial port */
static int            serial_fd = -1;
static struct termios serial_attr;
static struct termios serial_attr_save;
static int            serial_attr_saved = 0;

/* stdin */
static struct termios in_attr;
static struct termios in_attr_save;
static int            in_attr_saved = 0;

/* stdout */

/* ACK received */
static char           ack = 0;

/* EOF timer */
static char           wai = 0;
static int            wai_wait = 1;
static time_t         wai_timer = 0;

/* buffers */
static char           in_buf[256];
static size_t         in_pending = 0;
static char *         in_offset = in_buf;

static char           omap_buf[256];
static size_t         omap_pending = 0;
static char *         omap_offset = omap_buf;

static char           mapped_buf[256];
static size_t         mapped_pending = 0;
static char *         mapped_offset = mapped_buf;

static char           out_buf[256];
static size_t         out_pending = 0;
static char *         out_offset = out_buf;

static void serial_makeraw(struct termios *attr)
{
  /* raw mode, read, no echo */
  cfmakeraw(attr);
  attr->c_lflag &= ~(ECHO|ICANON);
  attr->c_cflag |= CREAD;

  /* 8N1 */
  attr->c_cflag &= ~CSIZE;
  attr->c_cflag |= CS8;
  attr->c_iflag |= IGNPAR;
  attr->c_iflag &= ~PARMRK;
  attr->c_cflag &= ~(PARENB|PARODD);
  attr->c_cflag &= ~CSTOPB;

  /* rtscts */
  attr->c_cflag |= CRTSCTS;

  /* options */
  if (echo) {
    attr->c_lflag |= ECHO;
  }
  if (icrnl) {
    attr->c_iflag |= ICRNL;
  }
  if (ocrnl) {
    attr->c_oflag |= OCRNL;
  }

  /* timing */
  attr->c_cc[VTIME] = 5;
  attr->c_cc[VMIN]  = 1;
}

int orter_serial_open(char *name, int baud)
{
  speed_t br;

  /* open fd */
  if ((serial_fd = open(name, O_RDWR|O_NDELAY|O_NOCTTY|O_NONBLOCK)) < 0) {
    perror("serial open failed");
    return errno;
  }
  /* get lock */  
  if (flock(serial_fd, LOCK_EX) < 0) {
    perror("serial flock failed");
    return errno;
  }
  /* check it's a tty */  
  if (!isatty(serial_fd)) {
    perror("serial not a tty");
    return -1;
  }
  /* get attr */  
  if (tcgetattr(serial_fd, &serial_attr_save) < 0) {
    perror("serial tcgetattr failed");
    return errno;
  }
  serial_attr_saved = 1;
  /* raw mode */
  serial_makeraw(&serial_attr);
  /* baud */
  switch (baud) {
    case 50: br = B50; break;
    case 75: br = B75; break;
    case 110: br = B110; break;
    case 134: br = B134; break;
    case 150: br = B150; break;
    case 200: br = B200; break;
    case 300: br = B300; break;
    case 600: br = B600; break;
    case 1200: br = B1200; break;
    case 1800: br = B1800; break;
    case 2400: br = B2400; break;
    case 4800: br = B4800; break;
#ifdef B7200
    case 7200: br = B7200; break;
#endif
    case 9600: br = B9600; break;
#ifdef B14400
    case 14400: br = B14400; break;
#endif
    case 19200: br = B19200; break;
#ifdef B28800
    case 28800: br = B28800; break;
#endif
    case 38400: br = B38400; break;
    case 57600: br = B57600; break;
#ifdef B76800
    case 76800: br = B76800; break;
#endif
    case 115200: br = B115200; break;
    case 230400: br = B230400; break;
    default: perror("invalid baud rate"); return -1; break;
  }
  if (cfsetispeed(&serial_attr, br)) {
    perror("serial cfsetispeed failed");
    return errno;
  }
  if (cfsetospeed(&serial_attr, br)) {
    perror("serial cfsetospeed failed");
    return errno;
  }
  /* apply settings */
  if (tcsetattr(serial_fd, TCSADRAIN, &serial_attr)) {
    perror("serial tcsetattr failed");
    return errno;
  }
  /* flush */
  if (tcflush(serial_fd, TCIOFLUSH)) {
    perror("serial tcflush failed");
    return errno;
  }

  return 0;
}

int orter_serial_close(void)
{
  /* ignore if not opened */
  if (serial_fd < 0) {
    return 0;
  }
  /* drain anything pending */
  if (tcdrain(serial_fd)) {
    perror("serial tcdrain failed");
  }
  /* restore if set */
  if (serial_attr_saved && tcsetattr(serial_fd, TCSANOW, &serial_attr_save)) {
    perror("serial tcsetattr failed");
  }
  serial_attr_saved = 0;
  /* close it */
  if (close(serial_fd)) {
    perror("serial close failed");
  }
  /* deref the fd */
  serial_fd = -1;

  return 0;
}

static size_t omap_rd(char *off, size_t len)
{
  char c;
  int n = 0;

  /* no op if empty buffer */
  if (!omap_pending) {
    return 0;
  }

  /* copy into buffer */
  while (omap_pending && len) {

    /* read char */
    c = *(omap_offset++);

    /* olfcr */
    /* TODO rename to onlcrx? */
    if (c == 10 && olfcr) {
      c = 13;
    }

    /* odelbs */
    if (odelbs && c == 127) {
      c = 8;
    }

    /* write char */
    *(off++) = c;

    /* advance counters */
    omap_pending--;
    len--;
    n++;
  }

  return n;
}

static size_t omap_wr(char *off, size_t len)
{
  /* need empty buffer */
  if (omap_pending) {
    return 0;
  }

  /* copy into buffer */
  memcpy(omap_buf, off, len);
  omap_offset = omap_buf;
  omap_pending = len;

  return len;
}

static int std_close(void)
{
  /* stdin */
  if (in_attr_saved && isatty(0)) {
    if (tcsetattr(0, TCSANOW, &in_attr_save)) {
      perror("stdin tcsetattr failed");
    }
    in_attr_saved = 0;
  }

  /* stdout */
  /* currently no op */

  return 0;
}

static void restore(void)
{
  /* serial port */
  if (orter_serial_close()) {
    perror("serial close failed");
  }

  /* stdin/stdout */
  if (std_close()) {
    perror("stdin/stdout close failed");
  }
}

size_t orter_serial_rd(char *off, size_t len)
{
  return orter_io_fd_rd(serial_fd, off, len);
}

size_t orter_serial_wr(char *off, size_t len)
{
  return orter_io_fd_wr(serial_fd, off, len);
}

static int std_open(void)
{
  /* make stdin nonblocking */
  if (fcntl(0, F_SETFL, O_NONBLOCK)) {
    perror("stdin fcntl failed");
    return errno;
  }
  /* modify stdin attr */
  if (isatty(0)) {
    /* save current stdin attr */
    if (tcgetattr(0, &in_attr_save)) {
      perror("stdin tcgetattr failed");
      return errno;
    }
    in_attr_saved = 1;
    /* modify stdin attr */
    in_attr = in_attr_save;
    /* no echo, non canonical */
    in_attr.c_lflag &= ~(ECHO|ICANON);
    /* VTIME/VMIN */
    in_attr.c_cc[VTIME] = 0;
    in_attr.c_cc[VMIN] = 1;
    /* BRKINT */
    in_attr.c_iflag |= BRKINT;
    if (tcsetattr(0, TCSANOW, &in_attr)) {
      perror("stdin tcsetattr failed");
      return errno;
    }
  }
  /* make stdout nonblocking */
  if (fcntl(1, F_SETFL, O_NONBLOCK)) {
    perror("stdout fcntl failed");
    return errno;
  }

  return 0;
}

/* usage message */
static int usage(void)
{
  fprintf(stderr, "Usage: orter serial <options> <name> <baud>\n\n"
                  "                    -a        : terminate after 0x06 (ACK) read\n"
                  "                    -e <wait> : wait <wait> s after EOF\n"
                  "                    -o echo   : write 0x0a->0x0d\n"
                  "                    -o icrnl  : read  0x0d->0x0a\n"
                  "                    -o olfcr  : write 0x0a->0x0d\n"
                  "                    -o ocrnl  : write 0x0d->0x0a\n"
                  "                    -o odelbs : write 0x7f->0x08\n");
  return 1;
}

static void opts(int argc, char **argv)
{
  int c;

  /* getopt */
  while ((c = getopt(argc, argv, "ae:ho:")) != -1) {
    switch (c) {
      case 'a':
        ack = 1;
        break;
      case 'e':
        wai = 1;
        wai_wait = atoi(optarg);
        break;
      case 'h': usage(); break;
      case 'o':
        if (!strcmp(optarg, "echo")) {
          echo = 1;
        }
        if (!strcmp(optarg, "icrnl")) {
          icrnl = 1;
        }
        if (!strcmp(optarg, "odelbs")) {
          odelbs = 1;
        }
        if (!strcmp(optarg, "olfcr")) {
          olfcr = 1;
        }
        if (!strcmp(optarg, "ocrnl")) {
          ocrnl = 1;
        }
        break;
      default:
        fprintf(stderr, "invalid option %s\n", argv[optind - 1]);
        exit(1);
    }
  }
}

int orter_serial(int argc, char **argv)
{
  /* exit code */
  int exit = 0;

  /* EOF flag */
  int eof = 0;

  /* select parameters */
  fd_set readfds, writefds, exceptfds;
  struct timeval timeout;
  int nfds;

  /* command line options */
  optind = 2;
  opts(argc, argv);
  argv += optind;
  argc -= optind;
  if (argc != 2) {
    return usage();
  }

  /* signal handlers */
  orter_io_signal_init();

  /* serial */
  if (orter_serial_open(argv[0], atoi(argv[1]))) {
    exit = errno;
    perror("serial open failed");
    restore();
    return exit;
  }

  /* stdin/stdout */
  if (std_open()) {
    exit = errno;
    perror("stdin/stdout open failed");
    restore();
    return exit;
  }

  /* set up select */
  nfds = 0;
  if (0 > nfds) nfds = 0;
  if (1 > nfds) nfds = 1;
  if (serial_fd > nfds) nfds = serial_fd;
  nfds++;

  while (!orter_io_finished) {

    /* init fd sets */
    FD_ZERO(&readfds);
    FD_ZERO(&writefds);
    FD_ZERO(&exceptfds);

    /* add in to read, err set */
    if (!in_pending && !orter_io_eof) {
      FD_SET(0, &readfds);
/*
      FD_SET(0, &exceptfds);
*/
    }

    /* add out to write, err set */
    if (out_pending) {
      FD_SET(1, &writefds);
      FD_SET(1, &exceptfds);
    }

    /* add port to read, write and err sets */
    if (!out_pending) {
      FD_SET(serial_fd, &readfds);
      FD_SET(serial_fd, &exceptfds);
    }
    if (in_pending) {
      FD_SET(serial_fd, &writefds);
      FD_SET(serial_fd, &exceptfds);
    }

    timeout.tv_sec = 1;
    timeout.tv_usec = 0;

    /* select */
    /* TODO use pselect */
    if (select(nfds, &readfds, &writefds, &exceptfds, &timeout) < 0) {
      switch (errno) {
        case EINTR:
          exit = errno;
          perror("select interrupted");
          restore();
          return exit;
        default:
          exit = errno;
          perror("select failed");
          restore();
          return exit;
      }
    }

    /* check for exceptions */
    if (FD_ISSET(1, &exceptfds)) {
      exit = errno;
      perror("out error");
      restore();
      return exit;
    }

    /* exceptions expected from stdin until pipe attached */
/*
    if (FD_ISSET(0, &exceptfds)) {
      perror("in error");
      restore();
      return errno;
    }
*/
    if (FD_ISSET(serial_fd, &exceptfds)) {
      exit = errno;
      perror("serial error");
      restore();
      return exit;
    }

    /* stdin to mapped */
    orter_io_relay(orter_io_stdin_rd, omap_wr, in_buf, &in_offset, &in_pending);

    /* mapped to serial */
    orter_io_relay(omap_rd, orter_serial_wr, mapped_buf, &mapped_offset, &mapped_pending);

    /* serial to stdout */
    orter_io_relay(orter_serial_rd, orter_io_stdout_wr, out_buf, &out_offset, &out_pending);

    /* terminate after ACK */
    if (ack && out_buf[0] == 6) {
      break;
    }

    /* start EOF timer */
    if (!eof && orter_io_eof) {
      eof = 1;
      wai_timer = time(0) + wai_wait;
    }

    /* terminate after EOF and timer */
    if (eof && (!wai || time(0) >= wai_timer)) {
      break;
    }
  }

  /* done */
  restore();
  return orter_io_finished;
}
