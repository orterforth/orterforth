#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

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

static void write_u16le(uint16_t u16, int (*w)(int))
{
  w(u16 & 255);
  w(u16 >> 8);
}

int orter_spectrum_header(const char *filename, unsigned char type_, unsigned short p1, unsigned short p2)
{
  int c;
  int size;

  /* open file */
  FILE *ptr = fopen(filename, "rb");
  if (!ptr) {
    perror("file not found");
    return 1;
  }

  /* get file size */
  if (fseek(ptr, 0, SEEK_END)) {
    perror("fseek failed");
    return 1;
  }
  size = ftell(ptr);
  if (size == -1) {
    perror("file size failed");
    return 1;
  }
  if (fseek(ptr, 0L, SEEK_SET)) {
    perror("fseek failed");
    return 1;
  }

  /* write header */
  putchar(type_);
  write_u16le(size, putchar);
  write_u16le(p1, putchar);
  write_u16le(p2, putchar);
  putchar(255);
  putchar(255);

  /* write data */
  while ((c = fgetc(ptr)) != -1) {
    if (putchar(c) == -1) {
      perror("write failed");
      return 1;
    }
  };

  /* close file */
  if (fclose(ptr)) {
    perror("fclose failed");
    return 1;
  }

  /* flush output */
  if (fflush(stdout)) {
    perror("fclose failed");
    return 1;
  }

  return 0;
}
