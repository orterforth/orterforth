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

static int orter_bbc_uef_write(char *name, uint16_t load, uint16_t exec)
{
  uint8_t data[65536];
  size_t s;
  int block_nr = 0;

  /* header */
  fwrite("UEF File!\x00\x01\x00", 1, 12, stdout);

  /* carrier tone */
  carrier(1500);

  /*  */
  chunk(0x0100, 1);
  fputc(0xdc, stdout);

  /* carrier tone */
  carrier(1500);

  /* read whole file */
  s = fread(data, 1, 65536, stdin);

  while ((block_nr << 8) < (int) s) {
    /* determine block */
    uint16_t i = block_nr << 8;
    uint16_t j = MIN((size_t) i + 256, s);
    uint8_t *block = &data[i];
    uint16_t lenblk = j - i;

    /* construct data header */
    uint8_t header[32];
    uint16_t lenname = MIN(10, strlen(name));
    uint8_t *ptr = header + lenname;
    uint16_t lenhdr = 18 + lenname;

    /* name */
    memcpy(header, name, lenname);
    ptr[0] = 0;
    /* load, exec */
    orter_io_set_32le(load, ptr + 1);
    orter_io_set_32le(exec, ptr + 5);
    /* block no, block len */
    orter_io_set_16le(block_nr, ptr + 9);
    orter_io_set_16le(lenblk, ptr + 11);
    /* flag, spare */
    ptr[13] = ((j == s) ? 0x80 : 0);
    orter_io_set_32le(0, ptr + 14);

    /* write data */
    chunk(0x0100, lenhdr + lenblk + 5);
    fputc('*', stdout);
    /* header */
    fwrite(header, 1, lenhdr, stdout);
    orter_io_put_16be(crc(header, lenhdr));
    /* block */
    fwrite(block, 1, lenblk, stdout);
    orter_io_put_16be(crc(block, lenblk));

    /* carrier tone */
    carrier(600);

    block_nr++;
  }

  /* integer gap */
  chunk(0x0112, 2);
  orter_io_put_16le(600);

  /* done */
  fflush(stdout);
  return 0;
}

int orter_bbc(int argc, char *argv[])
{
  /* create a UEF file from a binary */
  if (argc == 7 && !strcmp("uef", argv[2]) && !strcmp("write", argv[3])) {
    return orter_bbc_uef_write(argv[4], strtol(argv[5], 0, 0), strtol(argv[6], 0, 0));
  }

  /* usage */
  fprintf(stderr, "Usage: orter bbc uef write <filename> <load> <exec>\n");
  return 1;
}
