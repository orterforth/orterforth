#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"
#include "spectrum.h"

/* save CTS status received from Fuse */
static char cts = 0;

static void fuse_log(char *message)
{
  fprintf(stderr, "fuse: %s\n", message);
}

int orter_spectrum_fuse_serial_getc(FILE *ptr)
{
  int c;

  /* read ch */
	while ((c = fgetc(ptr)) == 0) {

    /* 0x00 is escape code */
    c = fgetc(ptr);
    switch (c) {
      case 0:
        fuse_log("DTR low");
        break;
      case 1:
        fuse_log("DTR high");
        break;
      case 2:
        fuse_log("CTS low");
        cts = 1;
        break;
      case 3:
        fuse_log("CTS high");
        cts = 0;
        break;
      case 42:
        return 0;
      case 63:
        fuse_log("lost");
        break;
      default:
        fuse_log("invalid escape");
        break;
    }
  }

  return c;
}

int orter_spectrum_fuse_serial_putc(int c, FILE *ptr)
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

int orter_spectrum_header(const char *filename, unsigned char type_, unsigned short p1, unsigned short p2)
{
  int c;
  int size;

  /* open file */
  FILE *ptr = fopen(filename, "rb");
  if (!ptr) {
    perror("file not found");
    return errno;
  }

  /* get file size */
  if (orter_io_file_size(ptr, &size)) {
    perror("orter_io_file_size failed");
    return errno;
  }

  /* write header */
  putchar(type_);
  orter_io_put_16le(size);
  orter_io_put_16le(p1);
  orter_io_put_16le(p2);
  putchar(255);
  putchar(255);

  /* write data */
  while ((c = fgetc(ptr)) != -1) {
    if (putchar(c) == -1) {
      perror("write failed");
      return errno;
    }
  };

  /* close file */
  if (fclose(ptr)) {
    perror("fclose failed");
    return errno;
  }

  /* flush output */
  if (fflush(stdout)) {
    perror("fflush failed");
    return errno;
  }

  return 0;
}

int orter_spectrum(int argc, char *argv[])
{
  /* use unbuffered stdin/stdout */
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);

  /* Fuse Emulator serial escape handling */
  if (argc == 5 && !strcmp("fuse", argv[2]) && !strcmp("serial", argv[3])) {

    int c;

    /* read from Fuse serial named pipe and write to stdout */
    if (!strcmp("read", argv[4])) {
      while ((c = orter_spectrum_fuse_serial_getc(stdin)) != -1) {
        fputc(c, stdout);
      }
    }

    /* read from stdin and write to Fuse serial named pipe */
    if (!strcmp("write", argv[4])) {
      while ((c = fgetc(stdin)) != -1) {
        orter_spectrum_fuse_serial_putc(c, stdout);
      }
    }

    /* in case of any buffering */
    fflush(stdout);
    return 0;
  }

  /* prepend a file with a header suitable for LOAD *"b" or LOAD *"n" */
  if (argc == 7 && !strcmp("header", argv[2])) {
    return orter_spectrum_header(argv[3], atoi(argv[4]), atoi(argv[5]), atoi(argv[6]));
  }

  /* usage */
  fprintf(stderr, "Usage: orter spectrum header <filename> <type> <p1> <p2>\n");
  fprintf(stderr, "                      fuse serial read\n");
  fprintf(stderr, "                                  write\n");
  return 1;
}
