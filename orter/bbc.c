#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* TODO consolidate this byte io handling */
static void put16be(uint16_t n)
{
  fputc((uint8_t) (n >> 8), stdout);
  fputc((uint8_t) (n & 0x00FF), stdout);
}

static void put16le(uint16_t n)
{
  fputc((uint8_t) (n & 0x00FF), stdout);
  fputc((uint8_t) (n >> 8), stdout);
}

static void set16le(uint16_t n, uint8_t *p)
{
  *(p++) = (uint8_t) (n & 0x00FF);
  *p = (uint8_t) (n >> 8);
}

static void put32le(uint32_t n)
{
  put16le((uint16_t) n & 0x0000FFFF);
  put16le((uint16_t) (n >> 16));
}

static void set32le(uint32_t n, uint8_t *p)
{
  set16le((uint16_t) n & 0x0000FFFF, p);
  set16le((uint16_t) (n >> 16), p + 2);
}

static uint16_t crc(uint8_t *bytes, uint16_t len)
{
  int i, j;
  uint16_t crc = 0;
  for (i = 0; i < len; i++) {
    uint8_t c = bytes[i];
    crc = (((uint16_t) c ^ (crc >> 8)) << 8) | (crc & 0x00FF);
    for (j = 0; j < 8; j++) {
      uint16_t t;
      if (crc & 0x8000) {
          crc = crc ^ 0x0810;
          t = 1;
      } else {
          t = 0;
      }
      crc = (crc * 2 + t) & 0xFFFF;
    }
  }
  return crc;
}

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

static void chunk(uint16_t id, uint32_t length)
{
  put16le(id);
  put32le(length);
}

static void carrier(uint16_t cycles)
{
  chunk(0x0110, 2);
  put16le(cycles);
}

int orter_bbc_uef_write(char *name, uint16_t load, uint16_t exec)
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

  while (block_nr * 256 < s) {
    uint16_t i = block_nr * 256;
    uint16_t j = MIN(i + 256, s);
    uint8_t *block = &data[i];

    /* construct data header */
    uint8_t header[32];
    uint16_t lenname = MIN(10, strlen(name));
    uint16_t lenhdr = 18 + lenname;

    /* name */
    memcpy(header, name, lenname);
    header[lenname] = 0;
    /* load */
    set32le(load, header + lenname + 1);
    /* exec */
    set32le(exec, header + lenname + 5);
    /* block no */
    set16le(block_nr, header + lenname + 9);
    /* block len */
    set16le(j - i, header + lenname + 11);
    /* flag */
    header[lenname + 13] = ((j == s) ? 0x80 : 0);
    /* spare */
    set32le(0, header + lenname + 14);

    /* write data */
    chunk(0x0100, 1 + lenhdr + 2 + (j - i) + 2);
    fputc('*', stdout);
    /* header */
    fwrite(header, 1, lenhdr, stdout);
    put16be(crc(header, lenhdr));
    /* block */
    fwrite(block, 1, j - i, stdout);
    put16be(crc(block, j - i));

    /* carrier tone */
    carrier(600);

    block_nr++;
  }

  /* integer gap */
  chunk(0x0112, 2);
  put16le(600);

  /* done */
  fflush(stdout);
  return 0;
}