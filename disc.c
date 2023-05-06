#define _DEFAULT_SOURCE

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "orter/io.h"
#include "orter/serial.h"
#include "orter/spectrum.h"
#include "orter/tcp.h"
#include "persci.h"

#define RF_BBLK 128

static int disclinetoblock(char *line, int *lineno, FILE *stream, char *block)
{
  size_t len;

  /* read line from input file */
  if (!fgets(line, 66, stream)) {
    if (feof(stream)) {
      return 0;
    }
    perror("fgets failed");
    return errno;
  }

  /* count lines */
  (*lineno)++;

  /* fail if too long */
  len = strlen(line);
  if (line[len - 1] == '\n') {
    --len;
  }
  if (len > 64) {
    fprintf(stderr, "line %u too long\n", *lineno);
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
	char line[66];
  int lineno = 0;
  char block[RF_BBLK];
  int i, status;

  /* 77 tracks x 26 sectors */
  for (i = 0; i < 2002; i++) {

    /* clear buffer with spaces */
    memset(&block, ' ', RF_BBLK);

    /* read two lines */
    CHECK(status, disclinetoblock(line, &lineno, stdin, block));
    CHECK(status, disclinetoblock(line, &lineno, stdin, block + 64));

    /* write block to stdout */
    if (fwrite(block, 1, RF_BBLK, stdout) != RF_BBLK) {
      perror("fwrite failed");
      return errno;
    }
  }

  /* ok */
  return 0;
}

/* DISPATCH SERIAL READ/WRITE TO FUNCTION POINTERS */

static orter_io_pipe_t in;
static orter_io_pipe_t out;

/* mux of disc and serial console using bit 7 */
static char mux = 0;
static orter_io_pipe_t mux_in;
static orter_io_pipe_t mux_out;

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
        fflush(stderr);
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
        fflush(stderr);
      }
      break;
    }
  }

  return i;
}

/* read data from Fuse Emulator RS232 */
static size_t fuse_rd(char *off, size_t len)
{
  size_t i;
  int c;

  /* TODO read/escape from fd 0 into read buffer */
  for (i = 0; i < len; i++) {
    c = orter_spectrum_fuse_serial_getc(stdin);
    /* EOF */
    if (c == -1) {
      break;
    }
    off[i] = c;
    /* blocking, but EOT as a terminator */
    if (c == RF_ASCII_EOT) {
      i++;
      break;
    }
  }

  return i;
}

/* write data to Fuse Emulator RS232 */
static size_t fuse_wr(char *off, size_t len)
{
  size_t i;

  /* TODO read/escape into a buffer and then write to fd 1 */
  for (i = 0; i < len; i++) {
    orter_spectrum_fuse_serial_putc(off[i], stdout);
  }  

  return len;
}

static char mux_out_buf[256];
static char *mux_out_off = mux_out_buf;
static size_t mux_out_len;

/* read data from serial and mux into two buffers */
static size_t mux_disc_rd(char *off, size_t len)
{
  char buf[256];
  size_t i, j = 0, k = 0, size;

  /* don't read if mux out buff full */
  if (mux_out_len) {
    return 0;
  }

  /* read for disc and console output */
  size = orter_io_fd_rd(orter_serial_fd, buf, len);
  for (i = 0; i < size; i++) {
    char c = buf[i];
    if (c & 0x80) {
      off[j++] = c & 0x7F;
    } else {
      mux_out_off[k++] = c;
    }
  }

  /* record/return both lengths */
  mux_out_len = k;
  return j;
}

/* read from mux console buffer */
static size_t mux_console_rd(char *off, size_t len)
{
  /* number of bytes to read */
  size_t s = (mux_out_len > len) ? len : mux_out_len;

  /* read bytes from mux buffer */
  memcpy(off, mux_out_off, s);
  mux_out_off += s;
  mux_out_len -= s;

  /* reset mux buffer */
  if (!mux_out_len) {
    mux_out_off = mux_out_buf;
    mux_out_len = 0;
  }

  return s;
}

/* write disc data to serial */
static size_t mux_disc_wr(char *off, size_t len)
{
  size_t i;
  char buf[256];

  for (i = 0; i < len; i++) {
    buf[i] = off[i] | 0x80;
  }
  return orter_io_fd_wr(orter_serial_fd, buf, len);
}

static orter_io_pipe_t *pipes[4] = {
    &in,
    &out,
    &mux_in,
    &mux_out
};

/* Server loop */
static int serve(char *dr0, char *dr1)
{
  /* insert the disc image files */
  rf_persci_insert(0, dr0);
  rf_persci_insert(1, dr1);

  return orter_io_pipe_loop(pipes, mux ? 4 : 2);
}

/* TODO migrate fuse to fds, then can remove */
static int setconsoleunbuffered(void)
{
  if (setvbuf(stdin, NULL, _IONBF, 0)) {
    perror("setvbuf stdin failed");
    return errno;
  }
  if (setvbuf(stdout, NULL, _IONBF, 0)) {
    perror("setvbuf stdout failed");
    return errno;
  }
  return 0;
}

static int disc_fuse(char **argv)
{
  int exit = 0;

  CHECK(exit, setconsoleunbuffered());
  CHECK(exit, orter_io_std_open());

  /* create pipelines */
  orter_io_pipe_init(&in, 0, fuse_rd, disc_wr, -1);
  orter_io_pipe_init(&out, -1, disc_rd, fuse_wr, 1);

  /* run */
  exit = serve(argv[2], argv[3]);

  /* close and exit */
  orter_io_std_close();
  return exit;
}

static int serve_with_fds(int in_fd, int out_fd, char *dr0, char *dr1)
{
  /* create pipelines */
  orter_io_pipe_init(&in, in_fd, 0, disc_wr, -1);
  orter_io_pipe_init(&out, -1, disc_rd, 0, out_fd);

  /* run server */
  return serve(dr0, dr1);
}

static int disc_serial(char **argv)
{
  int exit = 0;

  /* serial port */
  CHECK(exit, orter_serial_open(argv[2], atoi(argv[3])));

  /* run */
  exit = serve_with_fds(orter_serial_fd, orter_serial_fd, argv[4], argv[5]);

  /* close and exit */
  orter_serial_close();
  return exit;
}

static int disc_mux(char **argv)
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

  /* enable mux, create pipelines */
  mux = 1;
  /* serial in to disc (and stdout buffer) */
  orter_io_pipe_init(&in, orter_serial_fd, mux_disc_rd, disc_wr, -1);
  /* stdin to serial out */
  orter_io_pipe_init(&mux_in, 0, 0, 0, orter_serial_fd);
  /* disc read to serial out */
  orter_io_pipe_init(&out, -1, disc_rd, mux_disc_wr, orter_serial_fd);
  /* stdout buffer to stdout */
  orter_io_pipe_init(&mux_out, -1, mux_console_rd, 0, 1);

  /* don't log as we are using the console for output */
  log = 0;

  /* run */
  exit = serve(argv[4], argv[5]);

  /* close and exit */
  orter_serial_close();
  orter_io_std_close();
  return exit;
}

static int disc_standard(char **argv)
{
  int exit = 0;

  /* stdin/stdout */
  CHECK(exit, orter_io_std_open());

  /* run */
  exit = serve_with_fds(0, 1, argv[2], argv[3]);

  /* close and exit */
  orter_io_std_close();
  return exit;
}

static int disc_tcp(char **argv)
{
  int exit = 0;

  /* open */
  CHECK(exit, orter_tcp_open(atoi(argv[2])));

  /* run */
  exit = serve_with_fds(orter_tcp_fd, orter_tcp_fd, argv[3], argv[4]);

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

  /* Console with Fuse Emulator RS232 fifo escape */
  if (argc == 4 && !strcmp("fuse", argv[1])) {
    return disc_fuse(argv);
  }

  /* Physical serial port but multiplex serial and disc */
  if (argc == 6 && !strcmp("mux", argv[1])) {
    return disc_mux(argv);
  }

  /* Physical serial port */
  if (argc == 6 && !strcmp("serial", argv[1])) {
    return disc_serial(argv);
  }

  /* Console */
  if (argc == 4 && !strcmp("standard", argv[1])) {
    return disc_standard(argv);
  }

  /* TCP */
  if (argc == 5 && !strcmp("tcp", argv[1])) {
    return disc_tcp(argv);
  }

  /* Usage */
  fputs("Usage: disc create                           Convert text file (stdin) into Forth block format (stdout)\n"
        "       disc fuse <dr0> <dr1>                 Run disc controller over stdin/stdout with Fuse Emulator escape\n"
        "       disc mux <name> <baud> <dr0> <dr1>    Run disc controller over physical serial port and multiplex with the console\n", stderr);
  fputs("       disc serial <name> <baud> <dr0> <dr1> Run disc controller over physical serial port\n"
        "       disc standard <dr0> <dr1>             Run disc controller over stdin/stdout\n"
        "       disc tcp <port> <dr0> <dr1>           Run disc controller over tcp port\n", stderr);
  return 1;
}
