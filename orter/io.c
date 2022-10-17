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

/* flag for cleanup and exit */
int orter_io_finished = 0;

/* signal handler */
static void handler(int signum)
{
#ifdef __CYGWIN__
  const char *name = strsignal(signum);
#endif
#ifdef __linux__
  char *name = strsignal(signum);
#endif
#ifdef __MACH__
  const char *name = sys_signame[signum];
#endif
  fprintf(stderr, "handler signal %s\n", name ? name : "unknown");
  orter_io_finished = signum;
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
    orter_io_finished = errno;
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
    orter_io_finished = errno;
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
