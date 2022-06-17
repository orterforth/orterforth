#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint32_t getu32be(uint8_t *p)
{
  uint32_t n;

  n = *p << 24;
  n |= (uint32_t) *(++p) << 16;
  n |= (uint32_t) *(++p) << 8;
  n |= (uint32_t) *(++p);

  return n;
}

static void setu16be(uint16_t n, uint8_t *p)
{
  *(p++) = (uint8_t) (n >> 8);
  *p = (uint8_t) (n & 0x00FF);
}

static void setu32be(uint32_t n, uint8_t *p)
{
  setu16be((uint16_t) (n >> 16), p);
  setu16be((uint16_t) n & 0x0000FFFF, p + 2);
}

/* 15-byte QL file header for serial and net */
static void serial_header(uint32_t len, uint8_t typ, uint32_t dsp, uint32_t ext, uint8_t *header)
{
  *(header++) = 0xFF;
  setu32be(len, header);
  header += 4;
  *(header++) = 0x00;
  *(header++) = typ;
  setu32be(dsp, header);
  header += 4;
  setu32be(ext, header);
  header += 4;
}

int orter_ql_serial_header(int argc, char **argv)
{
  uint8_t header[15];

  serial_header(strtol(argv[2], 0, 0), strtol(argv[3], 0, 0), strtol(argv[4], 0, 0), strtol(argv[5], 0, 0), header);
  fwrite(header, 1, 15, stdout);
  fflush(stdout);
  return 0;
}

int orter_ql_serial_xtcc(int argc, char **argv)
{
  uint8_t header[15];
  uint32_t len;
  uint32_t dsp;

  int c;
  int size;
  uint8_t buf[4];
  char *filename = argv[3];

  /* open file */
  FILE *ptr = fopen(filename, "rb");
  if (!ptr) {
    perror("fopen failed");
    return errno;
  }

  /* TODO validate XTcc field is present */
  /* get xtcc field */
  if (fseek(ptr, -4L, SEEK_END)) {
    perror("fseek failed");
    return errno;
  }
  if (fread(buf, 1, 4, ptr) != 4) {
    perror("fread failed");
    return errno;
  }
  dsp = getu32be(buf);
  /* get file size */
  if (fseek(ptr, 0, SEEK_END)) {
    perror("fseek failed");
    return errno;
  }
  size = ftell(ptr);
  if (size == -1) {
    perror("ftell failed");
    return errno;
  }
  len = size;

  /* return to start */
  if (fseek(ptr, 0L, SEEK_SET)) {
    perror("fseek failed");
    return errno;
  }

  fprintf(stderr, "len=%u dsp=%u\n", len, dsp);
  serial_header(len, 1, dsp, 0, header);
  fwrite(header, 1, 15, stdout);

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
    return errno;
  }

  /* flush output */
  if (fflush(stdout)) {
    perror("fclose failed");
    return errno;
  }

  return 0;
}
