#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"

#define NUL 0x00
#define LF  0x0A
#define DLE 0x10
#define DC1 0x11
#define DC3 0x13
#define SUB 0x1A

static int orter_m100_co_header(uint16_t start, uint16_t length, uint16_t entry)
{
  orter_io_put_16le(start);
  orter_io_put_16le(length);
  orter_io_put_16le(entry);

  return 0;
}

static int orter_m100_serial_write(void)
{
    int c;

    while ((c = getchar()) != -1) {
        switch (c) {
        case NUL:
        case LF:
        case DLE:
        case DC1:
        case DC3:
        case SUB:
            putchar(DLE);
            putchar(c + 0x40);
            break;
        default:
            putchar(c);
            break;
        }
    }

    putchar(SUB);
    return 0;
}

int orter_m100(int argc, char **argv)
{
  if (argc == 7 && !strcmp(argv[2], "co") && !strcmp(argv[3], "header")) {
    return orter_m100_co_header(
      strtol(argv[4], 0, 0), 
      strtol(argv[5], 0, 0), 
      strtol(argv[6], 0, 0));
  }

  if (argc == 4 && !strcmp(argv[2], "serial") && !strcmp(argv[3], "write")) {
    return orter_m100_serial_write();
  }

  fprintf(stderr, "Usage: orter m100 co header <start> <length> <entry>\n");
  fprintf(stderr, "                  serial write\n");
  return 1;
}
