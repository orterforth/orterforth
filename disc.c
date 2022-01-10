#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "orter_serial.h"
#include "rf_persci.h"

#define RF_BBLK 128

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

static int create_disc(void)
{
  /* start reading lines and writing to blocks */
  int lineno = 0;
	char line[82]; 
  char block[RF_BBLK];

  /* read from stdin */
  FILE *stream = stdin;

  while (1) {

    char *read;

    /* clear buffer with spaces */
    memset(&block, ' ', RF_BBLK);

    /* read first line into block */
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

    /* if first line was final line */
    if (!read) {
      break;
    }
  }

  return 0;
}

/* DISPATCH SERIAL READ/WRITE TO FUNCTION POINTERS */

static void (*serial_open)(char *name, unsigned int baud);

static int (*serial_getc)(void);

static int (*serial_putc)(int c);

static void (*serial_flush)(void);

static void (*serial_close)(void);

static char *serial_name = 0;

static unsigned int serial_baud = 0;

/* Real serial port to connect to physical machine */
static void serial_init_physical(char *name, unsigned int baud)
{
  serial_name = name;
  serial_baud = baud;
  serial_open = orter_serial_open;
  serial_getc = orter_serial_getc;
  serial_putc = orter_serial_putc;
  serial_flush = orter_serial_flush;
  serial_close = orter_serial_close;
}

static void serial_standard_open(char *name, unsigned int baud)
{
  /* no buffering */
  if (setvbuf(stdin, NULL, _IONBF, 0)) {
    perror("setvbuf stdin failed");
    exit(1);
  }
  if (setvbuf(stdout, NULL, _IONBF, 0)) {
    perror("setvbuf stdin failed");
    exit(1);
  }
}

static void serial_standard_flush(void)
{
  if (fflush(stdout)) {
    perror("fflush failed");
    exit(1);
  }
}

/* Stdin and stdout */
static void serial_init_standard(void)
{
  serial_open = serial_standard_open;
  serial_getc = getchar;
  serial_putc = putchar;
  serial_flush = serial_standard_flush;
  serial_close = serial_standard_flush;
}

/* Server loop */
static int serve(void)
{
  unsigned int len = 0;
  int result = 1;

  rf_persci_insert(0, "0.disc");
  rf_persci_insert(1, "1.disc");

  /* open serial */
  serial_open(serial_name, serial_baud);

  for (;;) {
    int c;

    /* validate length */
    if (len >= 131) {
      fputs("buffer full\n", stderr);
      break;
    }

    /* read input */
    c = serial_getc();
    if (c == -1) {
      result = 0;
      break;
    }

    /* log input line in yellow */
    if (len == 0) {
      fputs("\033[0;33m", stderr);
    }

    rf_persci_putc(c);
    fputc(c, stderr);

    /* read until EOT */
    if (c != RF_ASCII_EOT) {
      continue;
    }
    fputs("\033[0m\n", stderr);

    /* now write response */
    len = 0;
    for (;;) {
      char c;

      /* read char and write out */      
      c = rf_persci_getc();
      serial_putc(c);

      /* log output in white */
      fputc(c, stderr);

      /* on EOT flush */
      if (c == RF_ASCII_EOT) {
        serial_flush();
        fputc('\n', stderr);
        break;
      }
    }

    /* reset buffer */
    len = 0;
  }

  /* finished */
  serial_close();
  return result;
}

int main(int argc, char *argv[])
{
  /* Console */
  if (argc == 1) {
    serial_init_standard();
    return serve();
  }

  /* Text file to Forth block disc image */
  if (argc == 2 && !strcmp("create", argv[1])) {
    return create_disc();
  }

  /* Physical serial port */
  if (argc == 4 && !strcmp("serial", argv[1])) {
    serial_init_physical(argv[2], atoi(argv[3]));
    return serve();
  }

  /* Usage */
  fputs("Usage: disc                       Run disc controller over stdin/stdout\n", stderr);
  fputs("       disc create                Convert text file (stdin) into Forth block format (stdout)\n", stderr);
  fputs("       disc serial <name> <baud>  Run disc controller over physical serial port\n", stderr);
  return 1;
}
