#ifdef __MACH__
#define ORTER_PLATFORM_UNIX
#endif
#ifdef __unix__
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
#ifdef ORTER_PLATFORM_UNIX
#include <fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#endif

/* opts */
static int            olfcr = 0;
static int            odelbs = 0;

/* serial port */
static int            serial_fd = -1;
static struct termios serial_attr;
static struct termios serial_attr_save;

/* stdin */
static int            in_fd = -1;
static struct termios in_attr;
static struct termios in_attr_save;

/* stdout */
static int            out_fd = -1;

/* EOF indicator */
static int            eof = 0;
static time_t         eof_timer = 0;
static int            eof_wait = 1;

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

  /* timing */
  attr->c_cc[VTIME] = 5;
  attr->c_cc[VMIN]  = 1;
}

static int serial_open(char *name, int baud)
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
  if (tcsetattr(serial_fd, TCSAFLUSH, &serial_attr)) {
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

static int serial_close(void)
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
  if (tcsetattr(serial_fd, TCSANOW, &serial_attr_save)) {
    perror("serial tcsetattr failed");
  }
  /* close it */
  if (close(serial_fd)) {
    perror("serial close failed");
  }
  /* deref the fd */
  serial_fd = -1;

  return 0;
}

/* character mappings */
static void omaps(char *buf, int n)
{
  int i = 0;
  
  for (i = 0; i < n; i++) {
    if (olfcr && buf[i] == 10) {
      buf[i] = 13;
    }
    if (odelbs && buf[i] == 127) {
      buf[i] = 8;
    }
  }
}

static size_t omap_rd(char *off, size_t len)
{
  int n;

  /* no op if empty buffer */
  if (!omap_pending) {
    return 0;
  }

  /* copy into buffer */
  n = omap_pending < len ? omap_pending : len;
  memcpy(off, omap_offset, n);
  omap_offset += n;
  omap_pending -= n;

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

  /* apply mappings */
  omaps(omap_offset, len);

  return len;
}


static void restore(void)
{
  /* serial port */
  serial_close();

  /* stdin */
  if (in_fd >= 0) {
    if (isatty(in_fd)) {
      tcsetattr(in_fd, TCSANOW, &in_attr_save);
    }
    in_fd = -1;
  }

  /* stdout */
  if (out_fd >= 0) {
    out_fd = -1;
  }
}

/* signal handler */
static void handler(int signum)
{
#ifdef __linux__
  const char *name = strsignal(signum);
#endif
#ifdef __MACH__
  const char *name = sys_signame[signum];
#endif

  restore();
  fprintf(stderr, "signal %s\n", name ? name : "unknown");
  exit(signum);
}

static size_t nbwrite(int fd, char *off, size_t len)
{
  ssize_t n;

  if (!len) {
    return 0;
  }

  n = write(fd, off, len);
  /*fprintf(stderr, "nbwrite %d %lu, %ld\n", fd, len, n);*/
  if (n <= 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
    restore();
    perror("write failed");
    exit(errno);
  }

  return (n < 0) ? 0 : n;
}

static size_t nbread(int fd, char *off, size_t len)
{
  ssize_t n;

  /* no op if length is 0 */
  if (!len) {
    return 0;
  }

  /* read bytes */
  n = read(fd, off, len);
  if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != ETIMEDOUT) {
    restore();
    perror("read failed");
    exit(errno);
  }

  /* mark EOF */
  if (n == 0 && !eof) {
    eof = 1;
    eof_timer = time(0) + eof_wait;
  }

  /* return actual length */
  return (n < 0) ? 0 : n;
}

static size_t in_rd(char *off, size_t len)
{
  return nbread(in_fd, off, len);
}

static size_t out_wr(char *off, size_t len)
{
  return nbwrite(out_fd, off, len);
}

static size_t serial_rd(char *off, size_t len)
{
  return nbread(serial_fd, off, len);
}

static size_t serial_wr(char *off, size_t len)
{
  return nbwrite(serial_fd, off, len);
}

typedef size_t (*rdwr_t)(char *, size_t);

static void bufread(rdwr_t rd, char *buf, char **offset, size_t *pending)
{
  size_t n;

  /* no op if buffer already non-empty */
  if (*pending) {
    return;
  }

  /* read bytes and initialise buffer */
  n = rd(buf, 256);
  *offset = buf;
  *pending = n;
}

static void bufwrite(rdwr_t wr, char *buf, char **offset, size_t *pending)
{
  size_t n;

  /* no op if no pending bytes */
  if (!*pending) {
    return;
  }

  /* write bytes and advance pointers */
  n = wr(*offset, *pending);
  *offset += n;
  *pending -= n;

  /* reset empty buffer */
  if (*pending == 0) {
    *offset = buf;
  }
}

int eof_wait_done(void)
{
  return eof && time(0) > eof_timer;
}

void init_signal(void)
{
  signal(SIGHUP, handler);
  signal(SIGINT, handler);
  signal(SIGTRAP, handler);
  signal(SIGABRT, handler);
  signal(SIGKILL, handler);
  signal(SIGPIPE, handler);
  signal(SIGTERM, handler);
  signal(SIGSYS, handler);
}

void init_serial(char *name, int baud)
{
  if (serial_open(name, baud)) {
    perror("serial open failed");
    exit(errno);
  }
}

void init_std(void)
{
  /* stdin */
  in_fd = fileno(stdin);
  if (fcntl(in_fd, F_SETFL, O_NONBLOCK)) {
    restore();
    perror("stdin fcntl failed");
    exit(errno);
  }
  if (isatty(in_fd)) {
    tcgetattr(in_fd, &in_attr_save);
    in_attr = in_attr_save;
    in_attr.c_lflag &= ~(ECHO|ICANON);
    in_attr.c_cc[VTIME] = 0;
    in_attr.c_cc[VMIN] = 1;
    in_attr.c_iflag |= BRKINT;
    tcsetattr(in_fd, TCSANOW, &in_attr);
  }

  /* stdout */
  out_fd = fileno(stdout);
  if (isatty(out_fd)) {
    if (fcntl(out_fd, F_SETFL, O_NONBLOCK)) {
      restore();
      perror("stdout fcntl failed");
      exit(errno);
    }
  }
}

/* usage message */
static void usage(void)
{
  fprintf(stderr, "Usage: orter serial [-e wait] [-o option...] <name> <baud>\n\n"
                  "e.g.   orter serial -o olfcr -o odelbs /dev/cu.usbserial-A50285BI 115200\n"
                  "        - connect translate 0x0a->0x0d, 0x7f->0x08\n"
                  "       echo 'run' | orter serial -e 5 /dev/cu.usbserial-A50285BI 115200\n"
                  "        - write the string and keep open for 5 s\n");
  exit(1);
}

static void opts(int argc, char **argv)
{
  int c;

  /* getopt */
  while ((c = getopt(argc, argv, "e:ho:")) != -1) {
    switch (c) {
      case 'e':
        eof_wait = atoi(optarg);
        break;
      case 'h': usage(); break;
      case 'o':
        if (!strcmp(optarg, "odelbs")) {
          odelbs = 1;
        }
        if (!strcmp(optarg, "olfcr")) {
          olfcr = 1;
        }
        break;
      default:
        fprintf(stderr, "invalid option %s\n", argv[optind - 1]);
        exit(1);
    }
  }
}

int orter_serial2(int argc, char **argv)
{
  /* command line options */
  optind = 2;
  opts(argc, argv);
  argv += optind;
  argc -= optind;
  if (argc != 2) {
    usage();
  }

  /* signal handlers */
  init_signal();

  /* serial */
  init_serial(argv[0], atoi(argv[1]));

  /* stdin/stdout */
  init_std();

  for (;;) {

    /* TODO wait with pselect */
    /* TODO select/poll */
    usleep(10000);

    /* stdin to mapped */
    bufread(in_rd, in_buf, &in_offset, &in_pending);
    bufwrite(omap_wr, in_buf, &in_offset, &in_pending);

    /* mapped to serial */
    bufread(omap_rd, mapped_buf, &mapped_offset, &mapped_pending);
    bufwrite(serial_wr, mapped_buf, &mapped_offset, &mapped_pending);

    /* serial to stdout */
    bufread(serial_rd, out_buf, &out_offset, &out_pending);
    bufwrite(out_wr, out_buf, &out_offset, &out_pending);
/*
    if (eof) {
      int n = 9999;
      ioctl(serial_fd, TIOCOUTQ, &n);
      fprintf(stderr, "TIOCOUTQ=%d\n", n);
    }
*/
    /* terminate after eof and timer */
    if (eof_wait_done()) {
      break;
    }
  }

  /* finish */
  restore();
  return 0;
}
