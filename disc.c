#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "orter/io.h"
#include "orter/pty.h"
#include "orter/serial.h"
#include "orter/tcp.h"
#include "persci.h"

#define CHECK(exit, function) exit = (function); if (exit) return exit;

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
static char log_io = 0;

static void disc_log_input(char c)
{
  if (log_io) {
    fputs("\033[0;33m", stderr);
    log_io = 0;
  }
  fputc(c == RF_ASCII_EOT ? '\n' : c, stderr);
}

static void disc_log_output(char c)
{
  if (!log_io) {
    fputs("\033[0m", stderr);
    log_io = 1;
  }
  fputc(c == RF_ASCII_EOT ? '\n' : c, stderr);
}

/* Server loop */
static int serve(char *dr0, char *dr1, void (*process)(void))
{
  /* insert DR0 and DR1 if present */
  if (dr0) {
    if (rf_persci_insert(0, dr0)) return 1;
  }
  if (dr1) {
    if (rf_persci_insert(1, dr1)) return 1;
  }

  /* abstracted synchronous nonblocking I/O loop */
  return orter_io_pipe_loop(pipes, pipe_count, process);
}

static int disc_get(void)
{
  int c;

  c = rf_persci_getc();
  if (c == -1) return c;
  if (log) {
    disc_log_output(c);
  }
  return c;
}

static int disc_put(int c)
{
  int r;

  r = rf_persci_putc(c);
  if (r == -1) return r;
  if (log) {
    disc_log_input(c);
  }
  return c;
}

static void process_simple(void)
{
  int c;

  /* write to disc */
  while ((c = orter_io_pipe_get(&in)) != -1) {

    if (disc_put(c) == -1) {
      break;
    }
    if (c == RF_ASCII_EOT) {
      break;
    }
  }

  /* read from disc */
  while (orter_io_pipe_left(&out)) {

    if ((c = disc_get()) == -1) {
      break;
    }
    if (orter_io_pipe_put(&out, c) == -1) {
      break;
    }
    if (c == RF_ASCII_EOT) {
      break;
    }
  }

  /* input EOF terminates */
  if (in.in == -1) {
    orter_io_finished = 1;
  }
}

static int serve_with_fds(int in_fd, int out_fd, char *dr0, char *dr1)
{
  /* create pipelines */
  orter_io_pipe_read_init(&in, in_fd);
  orter_io_pipe_write_init(&out, out_fd);

  /* run server */
  return serve(dr0, dr1, process_simple);
}

static int disc_pty(int argc, char **argv)
{
  int exit = 0;

  /* open serial port */
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

  /* open serial port */
  CHECK(exit, orter_serial_open(argv[2], atoi(argv[3])));

  /* run */
  exit = serve_with_fds(orter_serial_fd, orter_serial_fd, argv[4], argc > 5 ? argv[5] : 0);

  /* close and exit */
  orter_serial_close();
  return exit;
}

static void process_mux(void)
{
  int c;

  /* read from serial */
  while (orter_io_pipe_left(&mux_out) && (c = orter_io_pipe_get(&in)) != -1) {

    if (c & 0x80) {
      /* disc */
      if (disc_put(c & 0x7F) == -1) {
        break;
      }
    } else {
      /* console */
      if (orter_io_pipe_put(&mux_out, c) == -1) {
        break;
      }
    }
  }

  /* read from stdin */
  while (orter_io_pipe_left(&out) && (c = orter_io_pipe_get(&mux_in)) != -1) {

    if (orter_io_pipe_put(&out, c) == -1) {
      break;
    };
  }

  /* read from disc */
  while (orter_io_pipe_left(&out)) {

    if ((c = disc_get()) == -1) {
      break;
    }
    if (orter_io_pipe_put(&out, c | 0x80) == -1) {
      break;
    }
    if (c == RF_ASCII_EOT) {
      break;
    }
  }

  /* input EOF terminates */
  if (mux_in.in == -1) {
    orter_io_finished = 1;
  }
}

static int disc_mux(int argc, char **argv)
{
  int exit = 0;

  /* stdin/stdout */
  CHECK(exit, orter_io_std_open());

  /* open serial port */
  exit = orter_serial_open(argv[2], atoi(argv[3]));
  if (exit) {
    orter_io_std_close();
    return exit;
  }

  /* include mux pipes, create pipelines */
  pipe_count = 4;
  /* read serial */
  orter_io_pipe_read_init(&in, orter_serial_fd);
  /* read stdin */
  orter_io_pipe_read_init(&mux_in, 0);
  /* write serial */
  orter_io_pipe_write_init(&out, orter_serial_fd);
  /* write stdout */
  orter_io_pipe_write_init(&mux_out, 1);

  /* don't log as we are using the console for output */
  log = 0;

  /* run */
  exit = serve(argv[4], argc > 5 ? argv[5] : 0, process_mux);

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

  /* open socket */
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

  /* Pseudoteletype */
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
  fputs("       disc pty <link> <dr0> <dr1>           Run disc controller over pty and create symlink\n", stderr);
  fputs("       disc serial <name> <baud> <dr0> <dr1> Run disc controller over physical serial port\n"
        "       disc tcp <port> <dr0> <dr1>           Run disc controller over tcp port\n", stderr);
  fputs("       disc <dr0> <dr1>                      Run disc controller over stdin/stdout\n", stderr);
  return 1;
}
