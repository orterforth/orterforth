#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* TODO change to orter bbc uef */
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

int orter_uef_write(char *name, uint16_t load, uint16_t exec)
{
  uint8_t data[65536];
  size_t s;
  int block_nr = 0;

  /* header */
  fputs("UEF File!", stdout);
  fputc('\x00', stdout);
  /* version */
  fputc('\x01', stdout);
  fputc('\x00', stdout);
  /* carrier tone */
  put16le(0x0110);
  put32le(2);
  put16le(1500);

  put16le(0x0100);
  put32le(1);
  fputc(0xdc, stdout);

  put16le(0x0110);
  put32le(2);
  put16le(1500);

  /* read whole file */
  s = fread(data, 1, 65536, stdin);

  while (block_nr * 256 < s) {
    uint16_t i = block_nr * 256;
    uint16_t j = MIN(i + 256, s);
    uint8_t *block = &data[i];
    uint8_t block_flag = (j == s) ? 0x80 : 0;

    /* construct data header */
    uint8_t header[99];
    uint16_t lenname = MIN(10, strlen(name));
    uint16_t lenhdr = 18 + lenname;
    memcpy(header, name, lenname); /* TODO length 10 */
    header[lenname] = 0;
    set32le(load, header + lenname + 1);
    set32le(exec, header + lenname + 5);
    set16le(block_nr, header + lenname + 9);
    set16le(j - i, header + lenname + 11);
    header[lenname + 13] = block_flag;
    set32le(0, header + lenname + 14);

    /* write data chunk lead */
    put16le(0x0100);
    put32le(1 + lenhdr + 2 + (j - i) + 2); /* j - i = len(block) */

    /* write data */
    fputc('*', stdout);
    fwrite(header, 1, lenhdr, stdout);
    put16be(crc(header, lenhdr));
    fwrite(block, 1, j - i, stdout);
    put16be(crc(block, j - i));

    /* write data */
    put16le(0x0110);
    put32le(2);
    put16le(600);

    block_nr++;
  }

  /* integer gap */
  put16le(0x0112);
  put32le(2);
  put16le(600);

  fflush(stdout);

  return 0;
}
