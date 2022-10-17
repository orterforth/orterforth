#include "io.h"

/* flag for cleanup and exit */
int orter_io_finished = 0;

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

