#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

/* save CTS status received from Fuse */
static char cts = 0;

static void log(char *message)
{
  fprintf(stderr, "fuse: %s\n", message);
}

int orter_fuse_serial_getc(FILE *ptr)
{
  int c;

  /* read ch */
	while ((c = fgetc(ptr)) == 0) {

    /* 0x00 is escape code */
    c = fgetc(ptr);
    switch (c) {
      case 0:
        log("DTR low");
        break;
      case 1:
        log("DTR high");
        break;
      case 2:
        log("CTS low");
        cts = 1;
        break;
      case 3:
        log("CTS high");
        cts = 0;
        break;
      case 42:
        return 0;
      case 63:
        log("lost");
        break;
      default:
        log("invalid escape");
        break;
    }
  }

  return c;
}

int orter_fuse_serial_putc(int c, FILE *ptr)
{
  /* write ch */
  if (fputc(c, ptr) == EOF) {
    return EOF;
  }

  /* 0x00 is escape code */
	if (c == 0) {
    if (fputc(42, ptr) == EOF) {
      return EOF;
    }
  }

  return c;
}
