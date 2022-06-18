#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

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
