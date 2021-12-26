/* PLATFORMS */
#ifdef __unix__
/* to get CRTSCTS */
#define _DEFAULT_SOURCE
#define ORTER_PLATFORM_POSIX
#endif
#ifdef __MACH__
#define ORTER_PLATFORM_POSIX
#endif

/* POSIX */
#ifdef ORTER_PLATFORM_POSIX
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
static int fd = 0;
#endif

/* Z88DK */
#ifdef __SCCZ80
#include <rs232.h>
#include <stdio.h>
#include <stdlib.h>
#endif

#include "orter_serial.h"

#ifdef ORTER_PLATFORM_POSIX
static tcflag_t get_speed(unsigned int baud)
#endif
#ifdef __SCCZ80
static unsigned char get_speed(unsigned int baud)
#endif
{
  switch (baud) {
    case 1200:
#ifdef ORTER_PLATFORM_POSIX
      return B1200;
#endif
#ifdef __SCCZ80
      return RS_BAUD_1200;
#endif
    case 2400:
#ifdef ORTER_PLATFORM_POSIX
      return B2400;
#endif
#ifdef __SCCZ80
      return RS_BAUD_2400;
#endif
    case 4800:
#ifdef ORTER_PLATFORM_POSIX
      return B4800;
#endif
#ifdef __SCCZ80
      return RS_BAUD_4800;
#endif
    case 9600:
#ifdef ORTER_PLATFORM_POSIX
      return B9600;
#endif
#ifdef __SCCZ80
      return RS_BAUD_9600;
#endif
    case 19200:
#ifdef ORTER_PLATFORM_POSIX
      return B19200;
#endif
#ifdef __SCCZ80
      return RS_BAUD_19200;
#endif
#ifdef ORTER_PLATFORM_POSIX
    case 115200:
      return B115200;
#endif
    default:
#ifdef ORTER_PLATFORM_POSIX
      fprintf(stderr, "Invalid baud rate %u\n", baud);
#endif
#ifdef __SCCZ80
      printk("Invalid baud rate\n");
#endif
      exit(1);
  }
}

void orter_serial_open(char *name, unsigned int baud)
{
#ifdef ORTER_PLATFORM_POSIX
  int flags;
  tcflag_t speed;
  struct termios options;

  /* open port */
  fd = open(name, O_RDWR | O_NOCTTY | O_SYNC | O_NONBLOCK);
  if (fd == -1) {
    perror("Could not open serial port");
    exit(1);
  }

  /* blocking I/O */
  flags = fcntl(fd, F_GETFL);
  flags &= ~O_NONBLOCK;
  if (fcntl(fd, F_SETFL, flags)) {
    perror("Could not F_SETFL");
    exit(1);
  }

  /* set baud rate */
  speed = get_speed(baud);

  /* get attr */
  if (tcgetattr(fd, &options)) {
    perror("tcgetattr failed");
    exit(1);
  }

  /* baud rate */
  if (cfsetispeed(&options, speed)) {
    perror("cfsetispeed failed");
    exit(1);
  }
  if (cfsetospeed(&options, speed)) {
    perror("cfsetospeed failed");
    exit(1);
  }

  /* defaults */
  options.c_iflag &= ~(INLCR | ICRNL);
  options.c_iflag |= IGNPAR | IGNBRK;
  options.c_oflag &= ~(OPOST | ONLCR | OCRNL);
  options.c_cflag &= ~(PARENB | PARODD | CSTOPB | CSIZE);
  options.c_cflag |= CLOCAL | CREAD | CS8;
  options.c_lflag &= ~(ICANON | ISIG | ECHO);

  /* rtscts */
  options.c_cflag |= CRTSCTS;

  /* set attr */
  if (tcsetattr(fd, TCSANOW, &options)) {
    perror("tcsetattr failed");
    exit(1);
  }
#endif
#ifdef __SCCZ80
  unsigned char params;
  
  params = RS_STOP_1 | RS_BITS_8 | speed(baud);
  if (rs232_params(params, RS_PAR_NONE) != RS_ERR_OK) {
    exit(1);
  }
  if (rs232_init() != RS_ERR_OK) {
    exit(1);
  }
#endif
}

void orter_serial_read(char *p, int len)
{
#ifdef ORTER_PLATFORM_POSIX
  int s;
  while (len) {
    s = read(fd, p, len);
    if (s < 0) {
      switch (errno) {
        case EINTR:
        case EAGAIN:
          s = 0;
          sleep(1);
          break;
        default:
          perror("read failed");
          exit(1);
          break;
      }
    }
    p += s;
    len -= s;
  }
#endif
#ifdef __SCCZ80
  unsigned char c;

  for (; len; len--) {
    while (rs232_get(&c) == RS_ERR_NO_DATA) {
    }
    *p++ = c;
  }
#endif
}

void orter_serial_write(char *p, int len)
{
#ifdef ORTER_PLATFORM_POSIX
  ssize_t s;

  while (len) {
    s = write(fd, p, len);
    if (s < 0) {
      switch (errno) {
        case EINTR:
        case EAGAIN:
          s = 0;
          sleep(1);
          break;
        default:
          perror("write failed");
          exit(1);
          break;
      }
    }
    p += s;
    len -= s;
  }
#endif
#ifdef __SCCZ80
  for (; len; len--) {
    char c = *p;
    while (rs232_put(c) == RS_ERR_OVERFLOW) {
    }
    p++;
  }
#endif
}

int orter_serial_getc()
{
  unsigned char c;
#ifdef ORTER_PLATFORM_POSIX
  orter_serial_read((char *) &c, 1);
  return c;
#endif
#ifdef __SCCZ80
  while (rs232_get(&c) == RS_ERR_NO_DATA) {
  }
  return c;
#endif
}

int orter_serial_putc(int c)
{
#ifdef ORTER_PLATFORM_POSIX
  unsigned char b = c;
  orter_serial_write((char *) &b, 1);
  return c;
#endif
#ifdef __SCCZ80
  while (rs232_put(c) == RS_ERR_OVERFLOW) {
  }
  return c;
#endif
}

void orter_serial_flush()
{
#ifdef ORTER_PLATFORM_POSIX
  if (fd) {
    if (tcdrain(fd)) {
      perror("tcdrain failed");
      exit(1);
    }
  }
#endif
}

void orter_serial_close()
{
#ifdef ORTER_PLATFORM_POSIX
  if (fd) {
    orter_serial_flush();
    if (close(fd)) {
      perror("close failed");
    }
    fd = 0;
  }
#endif
#ifdef __SCCZ80
  rs232_close();
#endif
}
