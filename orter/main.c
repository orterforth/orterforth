/* ORTER */

/* retrocomputing utility command line */

#include <stdio.h>
#include <string.h>

#ifndef _WIN32
#include "bbc.h"
#include "hex.h"
#include "m100.h"
#include "pty.h"
#include "ql.h"
#include "serial.h"
#include "spectrum.h"
#include "tcp.h"
#include "z88.h"
#endif

static int usage(void)
{
  fprintf(stderr, "Usage: orter <subcommand> ...\n");

  /* an entry for each subcommand */
  fprintf(stderr, "             atari ...\n");
  fprintf(stderr, "             bbc ...\n");
  fprintf(stderr, "             dragon ...\n");
  fprintf(stderr, "             hex ...\n");
  fprintf(stderr, "             hx20 ...\n");
  fprintf(stderr, "             m100 ...\n");
  fprintf(stderr, "             pty ...\n");
  fprintf(stderr, "             ql ...\n");
  fprintf(stderr, "             serial ...\n");
  fprintf(stderr, "             spectrum ...\n");
  fprintf(stderr, "             tcp ...\n");
  fprintf(stderr, "             z88 ...\n");

  return 1;
}

int orter_atari(int argc, char *argv[]);

int orter_dragon(int argc, char *argv[]);

int orter_hx20(int argc, char *argv[]);

int main(int argc, char *argv[])
{
  if (argc > 1) {
    char *arg = argv[1];
    if (!strcmp("atari", arg)) {
      return orter_atari(argc, argv);
    }
#ifndef _WIN32
    if (!strcmp("bbc", arg)) {
      return orter_bbc(argc, argv);
    }
    if (!strcmp("dragon", arg)) {
      return orter_dragon(argc, argv);
    }
#endif
    if (argc > 2 && !strcmp("hex", arg) && !strcmp("read", argv[2])) {
      return orter_hex_read();
    }
    if (argc > 3 && !strcmp("hex", arg) && !strcmp("include", argv[2])) {
      return orter_hex_include(argv[3]);
    }
    if (argc > 2 && !strcmp("hex", arg) && !strcmp("write", argv[2])) {
      return orter_hex_write();
    }
    if (!strcmp("hx20", arg)) {
      return orter_hx20(argc, argv);
    }
    if (!strcmp("m100", arg)) {
      return orter_m100(argc, argv);
    }
#ifndef _WIN32
    if (argc > 2 && !strcmp("pty", arg)) {
      return orter_pty(argv[2]);
    }
    if (!strcmp("ql", arg)) {
      return orter_ql(argc, argv);
    }
    if (!strcmp("serial", arg)) {
      return orter_serial(argc, argv);
    }
    if (!strcmp("spectrum", arg)) {
      return orter_spectrum(argc, argv);
    }
    if (!strcmp("tcp", arg)) {
      return orter_tcp(argc, argv);
    }
    if (!strcmp("z88", arg)) {
      return orter_z88(argc, argv);
    }
#endif
  }

  return usage();
}
