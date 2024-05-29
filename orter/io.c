#ifdef __unix__
/* for pselect etc */
#define _DEFAULT_SOURCE
#endif

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#ifndef _WIN32
#include <termios.h>
#include <unistd.h>
#endif

#include "io.h"

/* stdin (also stdout/stderr) */
static int            in_fl;
static int            in_fl_saved = 0;
#ifndef _WIN32
static struct termios in_attr;
static struct termios in_attr_save;
#endif
static int            in_attr_saved = 0;

/* exit code to return after cleanup */
int orter_io_exit = 0;

/* flag for cleanup and exit */
int orter_io_finished = 0;

/* select handling */
#ifndef _WIN32
static fd_set orter_io_readfds, orter_io_writefds, orter_io_exceptfds;
#endif

/* signal handler */
static void handler(int signum)
{
  orter_io_exit = signum;
  orter_io_finished = 1;
}

int orter_io_file_size(FILE *ptr, long *size)
{
  /* get file size */
  if (fseek(ptr, 0L, SEEK_END)) {
    perror("fseek failed");
    return errno;
  }
  *size = ftell(ptr);
  if (*size == -1L) {
    perror("ftell failed");
    return errno;
  }
  /* return to start */
  if (fseek(ptr, 0L, SEEK_SET)) {
    perror("fseek failed");
    return errno;
  }

  return 0;
}

#ifndef _WIN32
int orter_io_std_open(void)
{
  /* make nonblocking */
  if (!in_fl_saved) {
    /* stdin also applies to stdout/stderr */
    in_fl = fcntl(0, F_GETFL, 0);
    in_fl_saved = 1;
    if (fcntl(0, F_SETFL, O_NONBLOCK)) {
      perror("stdin fcntl failed");
      return errno;
    }
  }
  /* make raw */
  if (!in_attr_saved && isatty(0)) {
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

  return 0;
}

int orter_io_std_close(void)
{
  /* restore from nonblocking */
  if (in_fl_saved) {
    /* stdin also applies to stdout/stderr */
    if (fcntl(0, F_SETFL, in_fl)) {
      perror("stdin fcntl failed");
    }
    in_fl_saved = 0;
  }
  /* restore from raw */
  if (in_attr_saved && isatty(0)) {
    if (tcsetattr(0, TCSANOW, &in_attr_save)) {
      perror("stdin tcsetattr failed");
    }
    in_attr_saved = 0;
  }

  return 0;
}

static void bufread(int *in, char *buf, char **offset, size_t *pending)
{
  ssize_t n;

  /* no op if no fd */
  if (*in == -1) {
    return;
  }
  /* no op if buffer already non-empty */
  if (*pending) {
    return;
  }

  /* read bytes */
  n = read(*in, buf, 256);
  if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != ETIMEDOUT) {
    orter_io_exit = errno;
    orter_io_finished = 1;
    perror("read failed");
    return;
  }

  /* mark EOF */
  if (n == 0 && *in != -1) {
    *in = -1;
  }

  /* initialise buffer */
  if (n < 0) n = 0;
  *offset = buf;
  *pending = n;
}

static void bufwrite(int out, char *buf, char **offset, size_t *pending)
{
  ssize_t n;

  /* no op if no fd */
  if (out == -1) {
    return;
  }
  /* no op if no pending bytes */
  if (!*pending) {
    return;
  }

  /* write bytes */
  n = write(out, *offset, *pending);
  if (n <= 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != ETIMEDOUT) {
    orter_io_exit = errno;
    orter_io_finished = 1;
    perror("write failed");
    return;
  }

  /* advance pointers */
  if (n < 0) n = 0;
  *offset += n;
  *pending -= n;

  /* reset empty buffer */
  if (*pending == 0) {
    *offset = buf;
  }
}

size_t orter_io_pipe_left(orter_io_pipe_t *buf)
{
  return 256L - (buf->off - buf->buf) - buf->len;
}

int orter_io_pipe_get(orter_io_pipe_t *buf)
{
  int b;

  /* empty */
  if (!buf->len) {
    return -1;
  }

  /* read byte */
  b = *(buf->off);
  buf->off++;
  buf->len--;

  /* reset ptr */
  if (!buf->len) {
    buf->off = buf->buf;
  }

  return b;
}

int orter_io_pipe_put(orter_io_pipe_t *buf, char b)
{
  /* full */
  if (!orter_io_pipe_left(buf)) {
    return -1;
  }

  /* write byte */
  *(buf->off + buf->len) = b;
  buf->len++;

  return b;
}

void orter_io_pipe_init(orter_io_pipe_t *pipe, int in, int out)
{
  pipe->in = in;
  pipe->off = pipe->buf;
  pipe->len = 0;
  pipe->out = out;
}

void orter_io_pipe_read_init(orter_io_pipe_t *pipe, int in)
{
  orter_io_pipe_init(pipe, in, -1);
}

void orter_io_pipe_write_init(orter_io_pipe_t *pipe, int out)
{
  orter_io_pipe_init(pipe, -1, out);
}

void orter_io_pipe_move(orter_io_pipe_t *pipe)
{
  bufread(&pipe->in, pipe->buf, &pipe->off, &pipe->len);
  bufwrite(pipe->out, pipe->buf, &pipe->off, &pipe->len);
}

static int orter_io_nfds;

void orter_io_select_zero(void)
{
  FD_ZERO(&orter_io_readfds);
  FD_ZERO(&orter_io_writefds);
  FD_ZERO(&orter_io_exceptfds);
  orter_io_nfds = 0;
}

void orter_io_pipe_fdset(orter_io_pipe_t *pipe)
{
  /* if no bytes pending, select input */
  if (pipe->in != -1 && !pipe->len) {
    FD_SET(pipe->in, &orter_io_readfds);
/*
    FD_SET(pipe->in, &orter_io_exceptfds);
*/
    /* advance nfds */
    if (orter_io_nfds <= pipe->in) {
      orter_io_nfds = pipe->in + 1;
    }
  }

  /* if some bytes pending, select output */
  if (pipe->out != -1 && pipe->len) {
    FD_SET(pipe->out, &orter_io_writefds);
/*
    FD_SET(pipe->out, &orter_io_exceptfds);
*/
    /* advance nfds */
    if (orter_io_nfds <= pipe->out) {
      orter_io_nfds = pipe->out + 1;
    }
  }
}

int orter_io_select(void)
{
  struct timespec timeout;
  int result;

  /* reset timeout */
  timeout.tv_sec = 1;
  timeout.tv_nsec = 0;

  /* select */
  result = pselect(orter_io_nfds, &orter_io_readfds, &orter_io_writefds, &orter_io_exceptfds, &timeout, 0);
  if (result < 0) {
    switch (errno) {
      case EINTR:
        orter_io_exit = errno;
        perror("pselect interrupted");
        orter_io_finished = 1;
        break;
      default:
        orter_io_exit = errno;
        perror("pselect failed");
        orter_io_finished = 1;
        break;
    }
  }

  return result;
}

/* loop to operate pipes */
int orter_io_pipe_loop(orter_io_pipe_t **pipes, int num, void (*process)(void))
{
  int i;

  /* finish if interrupted by signal */
  signal(SIGHUP, handler);
  signal(SIGINT, handler);
  signal(SIGTRAP, handler);
  signal(SIGABRT, handler);
  signal(SIGKILL, handler);
  signal(SIGPIPE, handler);
  signal(SIGTERM, handler);
  signal(SIGSYS, handler);

  /* main loop */
  orter_io_finished = 0;
  while (!orter_io_finished) {

    /* init fd sets */
    orter_io_select_zero();
    /* add to fd sets */
    for (i = 0; i < num; i++) {
      orter_io_pipe_fdset(pipes[i]);
    }

    /* select */
    if (orter_io_select() < 0) {
      break;
    }
    /* move data along pipes */
    for (i = 0; i < num; i++) {
      orter_io_pipe_move(pipes[i]);
    }

    /* process data */
    if (process) {
      process();
    }
  }

  /* finished */
  return orter_io_exit;
}
#endif

void orter_io_put_16be(uint16_t u)
{
  fputc((uint8_t) (u >> 8), stdout);
  fputc((uint8_t) (u & 0x00FF), stdout);
}

void orter_io_put_16le(uint16_t u)
{
  fputc((uint8_t) (u & 0x00FF), stdout);
  fputc((uint8_t) (u >> 8), stdout);
}

void orter_io_put_32le(uint32_t u)
{
  orter_io_put_16le((uint16_t) u & 0x0000FFFF);
  orter_io_put_16le((uint16_t) (u >> 16));
}

uint16_t orter_io_get_16le(uint8_t *p)
{
  uint16_t u;

  u = *p;
  u |= (uint32_t) *(++p) << 8;

  return u;
}

uint32_t orter_io_get_32le(uint8_t *p)
{
  uint32_t u;

  u = *p;
  u |= (uint32_t) *(++p) << 8;
  u |= (uint32_t) *(++p) << 16;
  u |= (uint32_t) *(++p) << 24;

  return u;
}

uint32_t orter_io_get_32be(uint8_t *p)
{
  uint32_t u;

  u = *p << 24;
  u |= (uint32_t) *(++p) << 16;
  u |= (uint32_t) *(++p) << 8;
  u |= (uint32_t) *(++p);

  return u;
}

void orter_io_set_16be(uint16_t u, uint8_t *p)
{
  *(p++) = (uint8_t) (u >> 8);
  *p = (uint8_t) (u & 0x00FF);
}

void orter_io_set_16le(uint16_t u, uint8_t *p)
{
  *(p++) = (uint8_t) (u & 0x00FF);
  *p = (uint8_t) (u >> 8);
}

void orter_io_set_32be(uint32_t u, uint8_t *p)
{
  orter_io_set_16be((uint16_t) (u >> 16), p);
  orter_io_set_16be((uint16_t) u & 0x0000FFFF, p + 2);
}

void orter_io_set_32le(uint32_t u, uint8_t *p)
{
  orter_io_set_16le((uint16_t) u & 0x0000FFFF, p);
  orter_io_set_16le((uint16_t) (u >> 16), p + 2);
}
