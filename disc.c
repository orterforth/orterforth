#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "orter/io.h"
#include "orter/pty.h"
#include "orter/serial.h"
#include "orter/tcp.h"
#include "persci.h"

#define RF_BBLK 128

static char line[66];

static int lineno = 0;

static int disc_create_line(char *block)
{
  size_t len;

  /* read line from stdin */
  if (!fgets(line, 66, stdin)) {
    if (feof(stdin)) {
      return 0;
    }
    perror("fgets failed");
    return errno;
  }

  /* count lines */
  lineno++;

  /* strip newline */
  len = strlen(line);
  if (line[len - 1] == '\n') {
    --len;
  }
  /* fail if too long */
  if (len > 64) {
    fprintf(stderr, "line %u too long\n", lineno);
    return 1;
  }

  /* write to the block */
  memcpy(block, line, len);

  /* ok */
  return 0;
}

#define CHECK(exit, function) exit = (function); if (exit) return exit;

static int disc_create(void)
{
  char block[RF_BBLK];
  int i, status;

  /* 77 tracks x 26 sectors */
  lineno = 0;
  for (i = 0; i < 2002; i++) {

    /* clear buffer with spaces */
    memset(&block, ' ', RF_BBLK);

    /* read two lines */
    CHECK(status, disc_create_line(block));
    CHECK(status, disc_create_line(block + 64));

    /* write block to stdout */
    if (fwrite(block, 1, RF_BBLK, stdout) != RF_BBLK) {
      perror("fwrite failed");
      return errno;
    }
  }

  /* ok */
  return 0;
}

/* NONBLOCKING I/O PIPES */
static orter_io_pipe_t in;
static orter_io_pipe_t out;
static orter_io_pipe_t mux_in;
static orter_io_pipe_t mux_out;
static orter_io_pipe_t *pipes[4] = {
    &in,
    &out,
    &mux_in,
    &mux_out
};
static int pipe_count = 2;

/* determines whether to log disc I/O to stderr */
static char log = 1;

/* write data to disc */
static size_t disc_wr(char *off, size_t len)
{
  char c;
  size_t i;

  /* start/continue log line */
  if (log) {
    fputs("\033[0;33m", stderr);
    fwrite(off, 1, len, stderr);
  }

  for (i = 0; i < len; i++) {
    /* write byte */
    c = *(off++);
    if (rf_persci_putc(c) == -1) {
      return i;
    }

    if (c == RF_ASCII_EOT) {
      /* finish log line */
      if (log) {
        fputs("\033[0m\n", stderr);
      }

      /* for correct length */
      i++;
      break;
    }
  }

  /* return length */
  return i;
}

/* read data from disc */
static size_t disc_rd(char *off, size_t len)
{
  int c;
  size_t i;

  for (i = 0; i < len; i++) {
    /* read byte */
    c = rf_persci_getc();
    if (c == -1) {
      break;
    }
    *(off++) = c;

    /* stop read once EOT read */
    if (c == RF_ASCII_EOT) {
      /* return correct length */
      i++;
      /* log line */
      if (log) {
        fwrite(off - i, 1, i, stderr);
        fputc('\n', stderr);
      }
      break;
    }
  }

  return i;
}

static size_t disc_rd_mux(char *off, size_t len)
{
  size_t i, j;

  i = disc_rd(off, len);
  for (j = 0; j < i; j++) {
    off[j] |= 0x80;
  }

  return i;
}

static char mux_out_buf[256];
static char *mux_out_off = mux_out_buf;
static size_t mux_out_len;

/* serial data to disc and buffer for stdout */
static size_t mux_wr(char *off, size_t len)
{
  size_t i, j = 0, k = 0;

  /* don't read if mux out buff full */
  if (mux_out_len) {
    return 0;
  }

  /* mux between disc and mux_out_buf */
  for (i = 0; i < len; i++) {
    char c = off[i];
    if (c & 0x80) {
      c &= 0x7F;
      if (rf_persci_putc(c) == -1) {
        break;
      }
      j++;
      /* TODO consistent log mechanism */
      if (log) {
        fputc(c == 0x04 ? 0x0A : c, stderr);
      }
    } else {
      mux_out_off[k++] = c;
    }
  }

  /* record/return both lengths */
  mux_out_len = k;
  return j + k;
}

/* read from mux console buffer */
static size_t mux_out_rd(char *off, size_t len)
{
  return orter_io_buf_rd(mux_out_buf, &mux_out_off, &mux_out_len, off, len);
}

/* Server loop */
static int serve(char *dr0, char *dr1)
{
  /* insert DR0 and DR1 if present */
  if (dr0) {
    rf_persci_insert(0, dr0);
  }
  if (dr1) {
    rf_persci_insert(1, dr1);
  }

  return orter_io_pipe_loop(pipes, pipe_count);
}

static int serve_with_fds(int in_fd, int out_fd, char *dr0, char *dr1)
{
  /* create pipelines */
  orter_io_pipe_init(&in, in_fd, 0, disc_wr, -1);
  orter_io_pipe_init(&out, -1, disc_rd, 0, out_fd);

  /* run server */
  return serve(dr0, dr1);
}

static int disc_pty(int argc, char **argv)
{
  int exit = 0;

  /* serial port */
  CHECK(exit, orter_pty_open(argv[2]));

  /* run */
  exit = serve_with_fds(orter_pty_master_fd, orter_pty_master_fd, argv[3], argc > 4 ? argv[4] : 0);

  /* close and exit */
  orter_pty_close();
  return exit;
}

static int disc_serial(int argc, char **argv)
{
  int exit = 0;

  /* serial port */
  CHECK(exit, orter_serial_open(argv[2], atoi(argv[3])));

  /* run */
  exit = serve_with_fds(orter_serial_fd, orter_serial_fd, argv[4], argc > 5 ? argv[5] : 0);

  /* close and exit */
  orter_serial_close();
  return exit;
}

static int disc_mux(int argc, char **argv)
{
  int exit = 0;

  /* stdin/stdout */
  CHECK(exit, orter_io_std_open());

  /* serial port */
  exit = orter_serial_open(argv[2], atoi(argv[3]));
  if (exit) {
    orter_io_std_close();
    return exit;
  }

  /* include mux pipes, create pipelines */
  pipe_count = 4;
  /* serial in to disc (and stdout buffer) */
  orter_io_pipe_init(&in, orter_serial_fd, 0, mux_wr, -1);
  /* stdin to serial out */
  orter_io_pipe_init(&mux_in, 0, 0, 0, orter_serial_fd);
  /* disc read to serial out */
  orter_io_pipe_init(&out, -1, disc_rd_mux, 0, orter_serial_fd);
  /* stdout buffer to stdout */
  orter_io_pipe_init(&mux_out, -1, mux_out_rd, 0, 1);

  /* don't log as we are using the console for output */
  log = 0;

  /* run */
  exit = serve(argv[4], argc > 5 ? argv[5] : 0);

  /* close and exit */
  orter_serial_close();
  orter_io_std_close();
  return exit;
}

static int disc_standard(int argc, char **argv)
{
  int exit = 0;

  /* stdin/stdout */
  CHECK(exit, orter_io_std_open());

  /* run */
  exit = serve_with_fds(0, 1, argv[1], argc > 2 ? argv[2] : 0);

  /* close and exit */
  orter_io_std_close();
  return exit;
}

static int disc_tcp(int argc, char **argv)
{
  int exit = 0;

  /* open */
  CHECK(exit, orter_tcp_open(atoi(argv[2])));

  /* run */
  exit = serve_with_fds(orter_tcp_fd, orter_tcp_fd, argv[3], argc > 4 ? argv[4] : 0);

  /* close and exit */
  orter_tcp_close();
  return exit;
}

int main(int argc, char *argv[])
{
  /* Text file to Forth block disc image */
  if (argc == 2 && !strcmp("create", argv[1])) {
    return disc_create();
  }

  /* Physical serial port but multiplex serial and disc */
  if ((argc == 5 || argc == 6) && !strcmp("mux", argv[1])) {
    return disc_mux(argc, argv);
  }

  /* Pty */
  if ((argc == 4 || argc == 5) && !strcmp("pty", argv[1])) {
    return disc_pty(argc, argv);
  }

  /* Physical serial port */
  if ((argc == 5 || argc == 6) && !strcmp("serial", argv[1])) {
    return disc_serial(argc, argv);
  }

  /* Console */
  if (argc == 2 || argc == 3) {
    return disc_standard(argc, argv);
  }

  /* TCP */
  if ((argc == 4 || argc == 5) && !strcmp("tcp", argv[1])) {
    return disc_tcp(argc, argv);
  }

  /* Usage */
  fputs("Usage: disc create                           Convert text file (stdin) into Forth block format (stdout)\n"
        "       disc mux <name> <baud> <dr0> <dr1>    Run disc controller over physical serial port and multiplex with the console\n", stderr);
  fputs("       disc serial <name> <baud> <dr0> <dr1> Run disc controller over physical serial port\n"
        "       disc standard <dr0> <dr1>             Run disc controller over stdin/stdout\n"
        "       disc tcp <port> <dr0> <dr1>           Run disc controller over tcp port\n", stderr);
  return 1;
}
