/* ORTER */

/* retrocomputing utility command line */

#include <stdio.h>
#include <string.h>

#include "bbc.h"
#include "hex.h"
#include "pty.h"
#include "ql.h"
#include "serial.h"
#include "spectrum.h"
#include "z88.h"

static int usage(void)
{
  fprintf(stderr, "Usage: orter <subcommand> ...\n");

  /* an entry for each subcommand */
  fprintf(stderr, "             bbc ...\n");
  fprintf(stderr, "             dragon ...\n");
  fprintf(stderr, "             hex ...\n");
  fprintf(stderr, "             pty ...\n");
  fprintf(stderr, "             ql ...\n");
  fprintf(stderr, "             serial ...\n");
  fprintf(stderr, "             spectrum ...\n");
  fprintf(stderr, "             z88 ...\n");

  return 1;
}

int orter_dragon(int argc, char *argv[]);

int main(int argc, char *argv[])
{
  if (argc > 1) {
    char *arg = argv[1];
    if (!strcmp("bbc", arg)) {
      return orter_bbc(argc, argv);
    }
    if (!strcmp("dragon", arg)) {
      return orter_dragon(argc, argv);
    }
    if (argc > 2 && !strcmp("hex", arg) && !strcmp("read", argv[2])) {
      return orter_hex_read();
    }
    if (argc > 3 && !strcmp("hex", arg) && !strcmp("include", argv[2])) {
      return orter_hex_include(argv[3]);
    }
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
    if (!strcmp("z88", arg)) {
      return orter_z88(argc, argv);
    }
  }

  return usage();
}
