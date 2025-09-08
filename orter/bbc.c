#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bbc.h"
#include "io.h"

static uint16_t crc(uint8_t *bytes, uint16_t len)
{
  uint16_t hl = 0;
  int i, x;

  for (i = 0; i < len; ++i) {
    hl ^= (uint16_t) bytes[i] << 8;
    for (x = 0; x < 8; ++x) {
      uint16_t c = hl & 0x8000;
      if (c) hl ^= 0x0810;
      hl <<= 1;
      if (c) ++hl;
    }
  }

  return hl;
}

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

static void chunk(uint16_t id, uint32_t length)
{
  orter_io_put_16le(id);
  orter_io_put_32le(length);
}

static void carrier(uint16_t cycles)
{
  chunk(0x0110, 2);
  orter_io_put_16le(cycles);
}

static void data_crc(uint8_t *data, uint16_t len)
{
  fwrite(data, 1, len, stdout);
  orter_io_put_16be(crc(data, len));
}

static uint8_t data[65536];

static uint8_t hdr[32];

static int orter_bbc_bin_to_uef(char *name, uint16_t load, uint16_t exec)
{
  uint16_t namelen = MIN(10, strlen(name));
  uint8_t *ptr = hdr + namelen;
  uint16_t hdrlen = 18 + namelen;
  size_t s;
  uint16_t blkno = 0;

  /* read whole file */
  s = fread(data, 1, 65536, stdin);

  /* header, v0.1 */
  fwrite("UEF File!\x00\x01\x00", 1, 12, stdout);
  /* 5 seconds */
  carrier(12000);

  /* set name, load, exec, spare */
  memcpy(hdr, name, namelen);
  ptr[0] = 0;
  orter_io_set_32le(0xFFFF0000 | (uint32_t) load, ptr + 1);
  orter_io_set_32le(0xFFFF0000 | (uint32_t) exec, ptr + 5);
  orter_io_set_32le(0, ptr + 14);

  while (((size_t) blkno << 8) < s) {
    /* determine block */
    uint16_t i = blkno << 8;
    uint16_t j = MIN((size_t) i + 256, s);
    uint8_t *blk = data + i;
    uint16_t blklen = j - i;

    /* start block */
    chunk(0x0100, hdrlen + blklen + 5);
    putchar('*');

    /* set block no, block len, flag */
    orter_io_set_16le(blkno, ptr + 9);
    orter_io_set_16le(blklen, ptr + 11);
    ptr[13] = ((j == s) ? 0x80 : 0x00);

    /* write header and data */
    data_crc(hdr, hdrlen);
    data_crc(blk, blklen);

    /* 0.6 seconds */
    carrier(1440);

    blkno++;
  }

  /* 5 seconds */
  carrier(12000);
  /* gap 0.25 seconds */
  chunk(0x0112, 2);
  orter_io_put_16le(600);

  /* done */
  fflush(stdout);
  return 0;
}

int orter_bbc(int argc, char *argv[])
{
  /* create a UEF file from a binary */
  if (argc == 8 && !strcmp("bin", argv[2]) && !strcmp("to", argv[3]) && !strcmp("uef", argv[4])) {
    return orter_bbc_bin_to_uef(argv[5], strtol(argv[6], 0, 0), strtol(argv[7], 0, 0));
  }

  /* usage */
  fprintf(stderr, "Usage: orter bbc bin to uef <filename> <load> <exec>\n");
  return 1;
}
