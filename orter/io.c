#ifdef __unix__
/* to get strsignal */
#define _DEFAULT_SOURCE
#endif

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>

#include "io.h"

/* stdin */
static int            in_fl;
static int            in_fl_saved = 0;
static struct termios in_attr;
static struct termios in_attr_save;
static int            in_attr_saved = 0;

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

int orter_io_std_open(void)
{
  /* make stdin nonblocking */
  in_fl = fcntl(0, F_GETFL, 0);
  in_fl_saved = 1;
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

int orter_io_std_close(void)
{
  /* stdin */
  if (in_fl_saved) {
    if (fcntl(0, F_SETFL, in_fl)) {
      perror("stdin fcntl failed");
    }
    in_fl_saved = 0;
  }
  if (in_attr_saved && isatty(0)) {
    if (tcsetattr(0, TCSANOW, &in_attr_save)) {
      perror("stdin tcsetattr failed");
    }
    in_attr_saved = 0;
  }

  /* stdout */
  /* TODO fl */

  return 0;
}

size_t orter_io_stdin_rd(char *off, size_t len)
{
  return orter_io_fd_rd(0, off, len);
}

size_t orter_io_stdout_wr(char *off, size_t len)
{
  return orter_io_fd_wr(1, off, len);
}

static void bufread(int in, orter_io_rdwr_t rd, char *buf, char **offset, size_t *pending)
{
  size_t n;

  /* no op if buffer already non-empty */
  if (*pending) {
    return;
  }

  /* read bytes and initialise buffer */
  if (rd) {
    n = rd(buf, 256);
  } else {
    /* no fp provided, use fd */
    n = orter_io_fd_rd(in, buf, 256);
  }
  *offset = buf;
  *pending = n;
}

static void bufwrite(int out, orter_io_rdwr_t wr, char *buf, char **offset, size_t *pending)
{
  size_t n;

  /* no op if no pending bytes */
  if (!*pending) {
    return;
  }

  /* write bytes and advance pointers */
  if (wr) {
    n = wr(*offset, *pending);
  } else {
    /* no fp provided, use fd */
    n = orter_io_fd_wr(out, *offset, *pending);
  }
  *offset += n;
  *pending -= n;

  /* reset empty buffer */
  if (*pending == 0) {
    *offset = buf;
  }
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
  bufread(pipe->in, pipe->rd, pipe->buf, &pipe->off, &pipe->len);
  bufwrite(pipe->out, pipe->wr, pipe->buf, &pipe->off, &pipe->len);
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
        break;
      default:
        orter_io_exit = errno;
        perror("select failed");
        orter_io_finished = 1;
        break;
    }
  }

  return result;
}
