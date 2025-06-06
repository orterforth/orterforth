/* to get CRTSCTS */
#define _DEFAULT_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/time.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#include "io.h"
#include "serial.h"

/* serial port file descriptor */
int                   orter_serial_fd = -1;

/* opts */
static int            echo = 0;
static int            icrnl = 0;
static int            ixoff = 0;
static int            ixon = 0;
static int            ocrnl = 0;
static int            odelbs = 0;
static int            onlcr = 0;
static int            onlcrx = 0;

/* serial port */
static struct termios serial_attr;
static struct termios serial_attr_save;
static int            serial_attr_saved = 0;

/* exit after ACK */
static char           ack = 0;

/* delay */
static useconds_t     delay = 0;

/* stop if ixon set */
static int            stop = 0;

/* exit after EOF timer */
static int            wai_wait = 0;
static time_t         wai_timer = 0;

/* EOF flag */
static char           eof = 0;

/* buffers */
static orter_io_pipe_t in;
static orter_io_pipe_t in2;
static orter_io_pipe_t out;
static orter_io_pipe_t out2;
orter_io_pipe_t *pipes[4] = {
    &in,
    &in2,
    &out,
    &out2
};

static void set_attr(struct termios *attr)
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
  if (ixoff) {
    attr->c_iflag |= IXOFF;
  }
  /* IXON not adequate, implement flow control here */
  /*if (ixon) {
    attr->c_iflag |= IXON;
  }*/
  if (ocrnl) {
    attr->c_oflag |= OPOST | OCRNL;
  }
  if (onlcr) {
    attr->c_oflag |= OPOST | ONLCR;
  }

  /* timing */
  attr->c_cc[VTIME] = 5;
  attr->c_cc[VMIN]  = 1;
}

int orter_serial_open(char *name, int baud)
{
  speed_t br;

  /* open fd */
  if ((orter_serial_fd = open(name, O_RDWR|O_NDELAY|O_NOCTTY|O_NONBLOCK)) < 0) {
    perror("serial open failed");
    return errno;
  }
  /* check it's a tty */
  if (!isatty(orter_serial_fd)) {
    perror("serial not a tty");
    return -1;
  }
  /* get lock */
  if (flock(orter_serial_fd, LOCK_EX) < 0) {
    perror("serial flock failed");
    return errno;
  }
  /* get and save attr */
  if (tcgetattr(orter_serial_fd, &serial_attr_save) < 0) {
    perror("serial tcgetattr failed");
    return errno;
  }
  serial_attr_saved = 1;
  /* raw mode, 8N1, RTSCTS, options */
  serial_attr = serial_attr_save;
  set_attr(&serial_attr);
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
#ifdef B460800
    case 460800: br = B460800; break;
#endif
    default:
    fprintf(stderr, "invalid baud rate: %d\n", baud);
    return -1;
    break;
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
  if (tcsetattr(orter_serial_fd, TCSADRAIN, &serial_attr)) {
    perror("serial tcsetattr failed");
    return errno;
  }
  /* flush */
  if (tcflush(orter_serial_fd, TCIOFLUSH)) {
    perror("serial tcflush failed");
    return errno;
  }

  return 0;
}

int orter_serial_close(void)
{
  /* ignore if not opened */
  if (orter_serial_fd < 0) {
    return 0;
  }
  /* drain anything pending */
  /* don't drain, hangs */
/*
  if (tcdrain(orter_serial_fd)) {
    perror("serial tcdrain failed");
  }
*/
  /* restore if set */
  if (serial_attr_saved && tcsetattr(orter_serial_fd, TCSANOW, &serial_attr_save)) {
    perror("serial tcsetattr failed");
  }
  serial_attr_saved = 0;
  /* close it */
  if (close(orter_serial_fd)) {
    perror("serial close failed");
  }
  /* deref the fd */
  orter_serial_fd = -1;

  return 0;
}

static void restore(void)
{
  /* serial port */
  if (orter_serial_close()) {
    perror("serial close failed");
  }

  /* stdin/stdout */
  if (orter_io_std_close()) {
    perror("stdin/stdout close failed");
  }
}

/* usage message */
static int usage(void)
{
  fprintf(stderr, "Usage: orter serial <options> <name> <baud>\n\n"
                  "                    -a        : terminate after 0x06 (ACK) read\n"
                  "                    -d <wait> : write wait <wait> s after each byte\n"
                  "                    -e <wait> : read  wait <wait> s after EOF\n"
                  "                    -o echo   : enable echoing\n"
                  "                    -o icrnl  : read  0x0d->0x0a\n"
                  "                    -o ixoff  : write XON/XOFF\n"
                  "                    -o ixon   : read  XON/XOFF\n");
  fprintf(stderr, "                    -o ocrnl  : write 0x0d->0x0a\n"
                  "                    -o odelbs : write 0x7f->0x08\n"
                  "                    -o onlcr  : write 0x0a->0x0d 0x0a\n"
                  "                    -o onlcrx : write 0x0a->0x0d\n");
  return 1;
}

static void opts(int argc, char **argv)
{
  int c;

  /* getopt */
  while ((c = getopt(argc, argv, "ad:e:ho:")) != -1) {
    switch (c) {
      case 'a':
        ack = 1;
        break;
      case 'd':
        delay = (1000000.0F * strtof(optarg, 0));
        break;
      case 'e':
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
        if (!strcmp(optarg, "ixoff")) {
          ixoff = 1;
        }
        if (!strcmp(optarg, "ixon")) {
          ixon = 1;
        }
        if (!strcmp(optarg, "ocrnl")) {
          ocrnl = 1;
        }
        if (!strcmp(optarg, "odelbs")) {
          odelbs = 1;
        }
        if (!strcmp(optarg, "onlcr")) {
          onlcr = 1;
        }
        if (!strcmp(optarg, "onlcrx")) {
          onlcrx = 1;
        }
        break;
      default:
        fprintf(stderr, "invalid option %s\n", argv[optind - 1]);
        exit(1);
    }
  }
}

static void process(void)
{
  int c;

  /* stdin to serial */
  while (!stop && in.len && orter_io_pipe_left(&in2)) {
    c = orter_io_pipe_get(&in);
    /* -o onlcrx */
    if (c == 10 && onlcrx) {
      c = 13;
    }
    /* -o odelbs */
    if (c == 127 && odelbs) {
      c = 8;
    }
    orter_io_pipe_put(&in2, c);
    /* -d <delay> */
    if (delay) {
      usleep(delay);
      break;
    }
  }

  /* serial to stdout */
  while (out.len && orter_io_pipe_left(&out2)) {
    c = orter_io_pipe_get(&out);
    /* -a */
    if (c == 6 && ack) {
      orter_io_finished = 1;
    }
    /* -o ixon */
    if (c == 0x11 && ixon) {
      stop = 0;
    }
    if (c == 0x13 && ixon) {
      stop = 1;
    }
    orter_io_pipe_put(&out2, c);
  }

  /* -a */
  if (ack) {
    return;
  }

  /* start EOF timer */
  if (!eof && in.in == -1 && in.len == 0) {
    eof = 1;
    wai_timer = time(0) + wai_wait;
  }

  /* terminate after EOF */
  /* immediately or after timer */
  if (eof) {
    if (!wai_wait || time(0) >= wai_timer) {
      orter_io_finished = 1;
    }
  }
}

int orter_serial(int argc, char **argv)
{
  /* exit code */
  int exit = 0;

  /* command line options */
  optind = 2;
  opts(argc, argv);
  argv += optind;
  argc -= optind;
  if (argc != 2) {
    return usage();
  }

  /* serial */
  if (orter_serial_open(argv[0], atoi(argv[1]))) {
    exit = errno;
    perror("serial open failed");
    restore();
    return exit;
  }

  /* stdin/stdout */
  if (orter_io_std_open()) {
    exit = errno;
    perror("stdin/stdout open failed");
    restore();
    return exit;
  }

  /* set up pipes */
  orter_io_pipe_read_init(&in, 0);
  orter_io_pipe_write_init(&in2, orter_serial_fd);
  orter_io_pipe_read_init(&out, orter_serial_fd);
  orter_io_pipe_write_init(&out2, 1);

  /* run */
  exit = orter_io_pipe_loop(pipes, 4, process);

  /* done */
  restore();
  return exit;
}

