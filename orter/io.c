#ifdef __unix__
/* to get strsignal */
#define _DEFAULT_SOURCE
#endif

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#include "io.h"

/* flag to indicate EOF */
int orter_io_eof = 0;

/* exit code to return after cleanup */
int orter_io_exit = 0;

/* flag for cleanup and exit */
int orter_io_finished = 0;

/* select handling */
fd_set orter_io_readfds, orter_io_writefds, orter_io_exceptfds;

/* signal handler */
static void handler(int signum)
{
/*
#ifdef __CYGWIN__
  const char *name = strsignal(signum);
#endif
#ifdef __linux__
  char *name = strsignal(signum);
#endif
#ifdef __MACH__
  const char *name = sys_signame[signum];
#endif
*/
/*
  fprintf(stderr, "handler signal %s\n", name ? name : "unknown");
*/
  orter_io_exit = signum;
  orter_io_finished = 1;
}

void orter_io_signal_init(void)
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

size_t orter_io_fd_wr(int fd, char *off, size_t len)
{
  ssize_t n;

  /* no op if length is 0 */
  if (!len) {
    return 0;
  }

  /* write bytes */
  n = write(fd, off, len);
  if (n <= 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != ETIMEDOUT) {
    orter_io_exit = errno;
    orter_io_finished = 1;
    perror("write failed");
    return 0;
  }

  /* return actual length */
  return (n < 0) ? 0 : n;
}

size_t orter_io_fd_rd(int fd, char *off, size_t len)
{
  ssize_t n;

  /* no op if length is 0 */
  if (!len) {
    return 0;
  }

  /* read bytes */
  n = read(fd, off, len);
  if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != ETIMEDOUT) {
    orter_io_exit = errno;
    orter_io_finished = 1;
    perror("read failed");
    return 0;
  }

  /* mark EOF */
  if (n == 0 && !orter_io_eof) {
    orter_io_eof = 1;
  }

  /* return actual length */
  return (n < 0) ? 0 : n;
}

size_t orter_io_stdin_rd(char *off, size_t len)
{
  return orter_io_fd_rd(0, off, len);
}

size_t orter_io_stdout_wr(char *off, size_t len)
{
  return orter_io_fd_wr(1, off, len);
}

static void bufread(orter_io_rdwr_t rd, char *buf, char **offset, size_t *pending)
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

static void bufwrite(orter_io_rdwr_t wr, char *buf, char **offset, size_t *pending)
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

void orter_io_relay(orter_io_rdwr_t rd, orter_io_rdwr_t wr, char *buf, char **offset, size_t *pending)
{
  bufread(rd, buf, offset, pending);
  bufwrite(wr, buf, offset, pending);
}

void orter_io_pipe_init(orter_io_pipe_t *pipe, int in, orter_io_rdwr_t rd, orter_io_rdwr_t wr, int out)
{
  pipe->in = in;
  pipe->rd = rd;
  pipe->off = pipe->buf;
  pipe->len = 0;
  pipe->wr = wr;
  pipe->out = out;
}

void orter_io_pipe_move(orter_io_pipe_t *pipe)
{
  orter_io_relay(pipe->rd, pipe->wr, pipe->buf, &pipe->off, &pipe->len);  
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
  struct timeval timeout;
  int result;

  /* reset timeout */
  timeout.tv_sec = 1;
  timeout.tv_usec = 0;

  /* select */
  /* TODO use pselect */
  result = select(orter_io_nfds, &orter_io_readfds, &orter_io_writefds, &orter_io_exceptfds, &timeout);
  if (result < 0) {
    switch (errno) {
      case EINTR:
        orter_io_exit = errno;
        perror("select interrupted");
        orter_io_finished = 1;
      default:
        orter_io_exit = errno;
        perror("select failed");
        orter_io_finished = 1;
    }
  }

  return result;
}
