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

#include "orter_fuse.h"
#include "orter_serial.h"
#include "orter_spectrum.h"

static int usage()
{
  fprintf(stderr, "Usage: orter <subcommand> ...\n");

  /* an entry for each subcommand */
  fprintf(stderr, "             fuse ...\n");
  fprintf(stderr, "             hex ...\n");
  fprintf(stderr, "             serial ...\n");
  fprintf(stderr, "             spectrum ...\n");

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

static int serial_getopt(int *argc, char **argv[], int *wait)
{
  signed char o;

  /* do getopt loop */
  opterr = 1;
  while ((o = getopt(*argc, *argv, "+w:")) != -1) {
    switch (o) {
      case 'w':
        *wait = atoi(optarg);
        break;
      case '?':
        if (optopt == 'w') {
          fprintf(stderr, "Option -%c requires an argument.\n", optopt);
        } else {
          fprintf(stderr, "Unknown option `-%c'.\n", optopt);
        }
        return 1;
      default:
        abort();
    }
  }

  /* shift args to optind */
  *argv += optind;
  (*argv)--;
  *argc -= optind;
  (*argc)++;

  return 0;
}

static int serial(int argc, char *argv[])
{
  /* read options */
  int wait = 0; /* wait before close */

  /* shift args to subcommand */
  argc--;
  argv++;

  if (argc > 3) {
    /* read from serial and write to stdout */
    if (!strcmp("read", argv[1])) {
      int c;

      /* shift args past "read" */
      argc--;
      argv++;

      /* do getopt for -w */
      serial_getopt(&argc, &argv, &wait);

      /* don't buffer output */
      setvbuf(stdout, NULL, _IONBF, 0);

      /* open */
      orter_serial_open(argv[1], atoi(argv[2]));

      /* pipe from port to stdout */
      while ((c = orter_serial_getc()) != -1) {
        if (fputc(c, stdout) == -1) {
          fprintf(stderr, "write failed\n");
          exit(1);
        }
      };

      /* wait for specified time then finish */
      fflush(stdout);
      sleep(wait);
      orter_serial_close();

      return 0;
    }

    /* read from stdin and write to serial */
    if (!strcmp("write", argv[1])) {
      char buffer[256];

      /* shift args past "write" */
      argc--;
      argv++;

      /* do getopt for -w */
      serial_getopt(&argc, &argv, &wait);

      /* no input buffering */
      setvbuf(stdin, NULL, _IONBF, 0);

      /* open */
      orter_serial_open(argv[1], atoi(argv[2]));

      /* pipe from stdin to port */
      for (;;) {
        size_t s = fread(buffer, 1, 256, stdin);
        orter_serial_write(buffer, s);
        if (s < 256) {
          break;
        }
      }

      /* wait for specified time then finish */
      orter_serial_flush();
      sleep(wait);
      orter_serial_close();

      return 0;
    }
  }

  /* usage */
  fprintf(stderr, "Usage: orter serial read  [-w <wait>] <port> <baud>\n");
  fprintf(stderr, "                    write [-w <wait>] <port> <baud>\n");
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
    if (!strcmp("serial", arg)) {
      return serial(argc, argv);
    }
    if (!strcmp("spectrum", arg)) {
      return spectrum(argc, argv);
    }
  }

  return usage();
}
