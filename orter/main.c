/* ORTER */

/* retrocomputing utility command line */

/* platform specific compilation */
#ifdef __unix__
#define ORTER_PLATFORM_POSIX
#endif
#ifdef __MACH__
#define ORTER_PLATFORM_POSIX
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef ORTER_PLATFORM_POSIX
#include <getopt.h>
#include <unistd.h>
#endif

#include "fuse.h"
#include "ql.h"
#include "serial.h"
#include "spectrum.h"
#include "uef.h"

static int usage()
{
  fprintf(stderr, "Usage: orter <subcommand> ...\n");

  /* an entry for each subcommand */
  fprintf(stderr, "             fuse ...\n");
  fprintf(stderr, "             hex ...\n");
  fprintf(stderr, "             ql ...\n");
  fprintf(stderr, "             serial ...\n");
  fprintf(stderr, "             spectrum ...\n");
  fprintf(stderr, "             uef ...\n");

  return 1;
}

static int fuse(int argc, char *argv[])
{
  int c;

  if (argc > 2) {
    /* use unbuffered stdin/stdout */
    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);

    /* read from Fuse serial named pipe and write to stdout */
    if (!strcmp("serial", argv[2]) && !strcmp("read", argv[3])) {
      while ((c = orter_fuse_serial_getc(stdin)) != -1) {
        fputc(c, stdout);
      }
    }

    /* read from stdin and write to Fuse serial named pipe */
    if (!strcmp("serial", argv[2]) && !strcmp("write", argv[3])) {
      while ((c = fgetc(stdin)) != -1) {
        orter_fuse_serial_putc(c, stdout);
      }
    }

    /* in case of any buffering */
    fflush(stdout);

    return 0;
  }

  return usage();
}


static int ql(int argc, char **argv)
{
  if (argc == 4 && !strcmp(argv[2], "serial-bytes")) {
    return orter_ql_serial_bytes(argc, argv);
  }

  if (argc == 7 && !strcmp(argv[2], "serial-header")) {
    return orter_ql_serial_header(argc, argv);
  }

  if (argc == 4 && !strcmp(argv[2], "serial-xtcc")) {
    return orter_ql_serial_xtcc(argc, argv);
  }

  fprintf(stderr, "Usage: orter ql serial-header <len> <typ> <dsp> <ext>\n");
  fprintf(stderr, "                serial-bytes <filename>\n");
  fprintf(stderr, "                serial-xtcc <filename>\n");
  return 1;
}

static int spectrum(int argc, char *argv[])
{
  /* prepend a file with a header suitable for LOAD *"b" or LOAD *"n" */
  if (argc == 7 && !strcmp("header", argv[2])) {
    return orter_spectrum_header(argv[3], atoi(argv[4]), atoi(argv[5]), atoi(argv[6]));
  }

  /* usage */
  fprintf(stderr, "Usage: orter spectrum header <filename> <type> <p1> <p2>\n");
  return 1;
}

static int hex_getdigit()
{
  int c;

  for (;;) {
    c = getchar();

    /* EOF */
    if (c == -1) {
      return c;
    }

    /* convert */
    if (c >= '0' && c <= '9') {
      return c - 48;
    }
    if (c >= 'A' && c <= 'F') {
      return c - 55;
    }
    if (c >= 'a' && c <= 'f') {
      return c - 87;
    }

    /* ignore non-digits */
  }

  return c;
}

int hex_include(char *name)
{
  unsigned int i;
  int c;

  /* unbuffered */
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);

  printf("unsigned char %s[] = {", name);

  /* loop until EOF */
  for (i = 0;;i++) {
    c = getchar();
    if (c == -1) {
      break;
    }
    if (i) {
      putchar(',');
    }
    if (i % 12 == 0) {
      printf("\n  ");
    } else {
      putchar(' ');
    }
    printf("0x%02x", c);
  }

  printf("\n};\nunsigned int %s_len = %u;\n", name, i);

  return 0;
}

/* read hex, write binary */
static int hex_read()
{
  int b, c;

  /* unbuffered */
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);

  /* loop until EOF */
  for (b = 0;;) {
    /* high digit */
    c = hex_getdigit();
    if (c == -1) {
      break;
    }
    b = c << 4;

    /* low digit */
    c = hex_getdigit();
    if (c == -1) {
      fprintf(stderr, "odd number of digits\n");
      return 1;
    }
    b |= c;

    /* write byte */
    if (putchar(b) == -1) {
      perror("putchar failed");
      return 1;
    }
  }

  return 0;
}

static int uef(int argc, char *argv[])
{
  /* create a UEF file from a binary */
  if (argc == 6 && !strcmp("write", argv[2])) {
    return orter_uef_write(argv[3], strtol(argv[4], 0, 0), strtol(argv[5], 0, 0));
  }

  /* usage */
  fprintf(stderr, "Usage: orter uef write <filename> <load> <exec>\n");
  return 1;
}

int main(int argc, char *argv[])
{
  if (argc > 1) {
    char *arg = argv[1];
    if (!strcmp("fuse", arg)) {
      return fuse(argc, argv);
    }
    if (argc > 2 && !strcmp("hex", arg) && !strcmp("read", argv[2])) {
      return hex_read();
    }
    if (argc > 3 && !strcmp("hex", arg) && !strcmp("include", argv[2])) {
      return hex_include(argv[3]);
    }
    if (!strcmp("ql", arg)) {
      return ql(argc, argv);
    }
    if (!strcmp("serial", arg)) {
      return orter_serial(argc, argv);
    }
    if (!strcmp("spectrum", arg)) {
      return spectrum(argc, argv);
    }
    if (!strcmp("uef", arg)) {
      return uef(argc, argv);
    }
  }

  return usage();
}
