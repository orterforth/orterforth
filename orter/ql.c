#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"
#include "ql.h"

static int getfilesize(FILE *ptr, long *size)
{
  /* get file size */
  if (fseek(ptr, 0, SEEK_END)) {
    perror("fseek failed");
    return errno;
  }
  *size = ftell(ptr);
  if (*size == -1) {
    perror("ftell failed");
    return errno;
  }
  /* return to start */
  if (fseek(ptr, 0L, SEEK_SET)) {
    perror("fseek failed");
    return errno;
  }

  return 0;
}

static int writefile(FILE *ptr)
{
  int c;

  while ((c = fgetc(ptr)) != -1) {
    if (putchar(c) == -1) {
      perror("putchar failed");
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
    perror("fflush failed");
    return errno;
  }

  return 0;
}

/* 15-byte QL file header for serial and net */
static void serial_header(uint32_t len, uint8_t typ, uint32_t dsp, uint32_t ext, uint8_t *header)
{
  *(header++) = 0xFF;
  orter_io_set_32be(len, header);
  header += 4;
  *(header++) = 0x00;
  *(header++) = typ;
  orter_io_set_32be(dsp, header);
  header += 4;
  orter_io_set_32be(ext, header);
  header += 4;
}

static int writeheader(uint32_t len, uint8_t typ, uint32_t dsp, uint32_t ext)
{
  uint8_t header[15];

  serial_header(len, typ, dsp, ext, header);
  if (fwrite(header, 1, 15, stdout) != 15) {
    perror("fwrite failed");
    return errno;
  }
  if (fflush(stdout)) {
    perror("fflush failed");
    return errno;
  }

  return 0;
}

int orter_ql_serial_header(int argc, char **argv)
{
  if (writeheader(
    strtol(argv[2], 0, 0),
    strtol(argv[3], 0, 0),
    strtol(argv[4], 0, 0),
    strtol(argv[5], 0, 0))) {
    return errno;
  }

  return 0;
}

int orter_ql_serial_bytes(int argc, char **argv)
{
  uint32_t len;
  long size;
  char *filename = argv[3];

  /* open file */
  FILE *ptr = fopen(filename, "rb");
  if (!ptr) {
    perror("fopen failed");
    return errno;
  }

  /* size */
  if (getfilesize(ptr, &size)) {
    return errno;
  }
  len = size;

  /* header */
  if (writeheader(len, 0, 0, 0)) {
    return errno;
  }

  /* body */
  if (writefile(ptr)) {
    return errno;
  }

  return 0;
}

int orter_ql_serial_xtcc(int argc, char **argv)
{
  uint32_t len;
  uint32_t dsp;
  long size;
  uint8_t buf[8];
  char *filename = argv[3];

  /* open file */
  FILE *ptr = fopen(filename, "rb");
  if (!ptr) {
    perror("fopen failed");
    return errno;
  }

  /* get xtcc field */
  if (fseek(ptr, -8L, SEEK_END)) {
    perror("fseek failed");
    return errno;
  }
  if (fread(buf, 1, 8, ptr) != 8) {
    perror("fread failed");
    return errno;
  }
  if (memcmp(buf, "XTcc", 4)) {
    fprintf(stderr, "XTcc field not found\n");
    return 1;
  }
  dsp = orter_io_get_32be(buf + 4);

  /* size */
  if (getfilesize(ptr, &size)) {
    return errno;
  }
  len = size;

  /* header */
  if (writeheader(len, 1, dsp, 0)) {
    return errno;
  }

  /* body */
  if (writefile(ptr)) {
    return errno;
  }

  return 0;
}

int orter_ql(int argc, char **argv)
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
