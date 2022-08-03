#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "orter/serial.h"
#include "rf_persci.h"

#define RF_BBLK 128

static char eof = 0;

static char *read_line(char *line, int *lineno, FILE *stream)
{
  /* read line from input file (null if at end) */
  if (!fgets(line, 80, stream)) {
    if (feof(stream)) {
      return 0;
    }
    perror("fgets failed");
    exit(1);
  }

  /* fail if too long */
  (*lineno)++;
  if (strlen(line) > 65) {
    fprintf(stderr, "line %u too long\n", *lineno);
    exit(1);
  }

  /* return non-null, the line read */
  return line;
}

static char *line_to_block(char *line, int *lineno, FILE *stream, char *block)
{
  /* read the line */
  char *r = read_line(line, lineno, stream);

  /* write the line into the block, maybe offset by 64 chars */
  if (r) {
    memcpy(block, line, strlen(line) - 1);
  }

  /* return non-null */
  return r;
}

static int disc_write(void)
{
  int lineno = 0;
	char line[82]; 
  char block[RF_BBLK];
  char *read;

  /* read from stdin */
  FILE *stream = stdin;

  for (;;) {

    /* clear buffer with spaces */
    memset(&block, ' ', RF_BBLK);

    /* read first line into block, finish if no more */
    if (!line_to_block(line, &lineno, stream, block)) {
      break;
    }

    /* read second line into block */
    read = line_to_block(line, &lineno, stream, block + 64);

    /* write block to stdout */
    if (fwrite(block, 1, RF_BBLK, stdout) != RF_BBLK) {
      perror("fwrite failed");
      exit(1);
    }

    /* finish if first line was final line */
    if (!read) {
      break;
    }
  }

  return 0;
}

/* DISPATCH SERIAL READ/WRITE TO FUNCTION POINTERS */

static rdwr_t rd;

static rdwr_t wr;

/* TODO replace fetch check with nonblocking operations */
static char fetch = 0;

static size_t disc_wr(char *off, size_t len)
{
  char c;
  size_t i;

  /* TODO relay to logging */
  fputs("\033[0;33m", stderr);
  for (i = 0; i < len; i++) {
    c = *(off++);
    rf_persci_putc(c);
    if (c == RF_ASCII_EOT) {
      i++;
      fetch = 1;
      fputs("\033[0m\n", stderr);
      break;
    }
    fputc(c, stderr);
  }

  return i;
}

static size_t disc_rd(char *off, size_t len)
{
  char c;
  size_t i;

  if (!fetch) {
    return 0;
  }

  /* TODO relay to logging */
  for (i = 0; i < len; i++) {
    c = rf_persci_getc();
    *(off++) = c;
    if (c == RF_ASCII_EOT) {
      i++;
      fetch = 0;
      fputc('\n', stderr);
      break;
    }
    fputc(c, stderr);
  }

  return i;
}

/* Server loop */
static int serve(char *dr0, char *dr1)
{
  char           in_buf[256];
  size_t         in_pending = 0;
  char *         in_offset = in_buf;

  char           out_buf[256];
  size_t         out_pending = 0;
  char *         out_offset = out_buf;

  rf_persci_insert(0, dr0);
  rf_persci_insert(1, dr1);

  for (;;) {

    /* TODO use select */
    usleep(100000);

    orter_serial_relay(rd, disc_wr, in_buf, &in_offset, &in_pending);
    orter_serial_relay(disc_rd, wr, out_buf, &out_offset, &out_pending);

    /* EOF */
    if (eof) {
      break;
    }
  }

  /* finished */
  orter_serial_close();
  return 0;
}

static int disc_serial(int argc, char **argv)
{
  orter_serial_open(argv[2], atoi(argv[3]));
  rd = orter_serial_rd;
  wr = orter_serial_wr;

  return serve(argv[4], argv[5]);
}

static int disc_standard(int argc, char **argv)
{
  if (setvbuf(stdin, NULL, _IONBF, 0)) {
    perror("setvbuf stdin failed");
    exit(1);
  }
  rd = orter_serial_stdin_rd;
  if (setvbuf(stdout, NULL, _IONBF, 0)) {
    perror("setvbuf stdout failed");
    exit(1);
  }
  wr = orter_serial_stdout_wr;

  return serve(argv[2], argv[3]);
}

int main(int argc, char *argv[])
{
  /* Text file to Forth block disc image */
  if (argc == 2 && !strcmp("create", argv[1])) {
    return disc_write();
  }

  /* Physical serial port */
  if (argc == 6 && !strcmp("serial", argv[1])) {
    return disc_serial(argc, argv);
  }

  /* Console */
  if (argc == 4 && !strcmp("standard", argv[1])) {
    return disc_standard(argc, argv);
  }

  /* Usage */
  fputs("Usage: disc create                           Convert text file (stdin) into Forth block format (stdout)\n", stderr);
  fputs("       disc serial <name> <baud> <dr0> <dr1> Run disc controller over physical serial port\n", stderr);
  fputs("       disc standard <dr0> <dr1>             Run disc controller over stdin/stdout\n", stderr);
  return 1;
}
