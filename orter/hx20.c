#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "io.h"
#include "wav.h"

static uint8_t checksum = 0;

static void checksum_start(void)
{
  checksum = 0;
}

static void checksum_write(uint8_t *p, int s)
{
  int i = 0;

  for (i = 0; i < s; ++i) {
    checksum += p[i];
  }

  fwrite(p, 1, s, stdout);  
}

static void checksum_write_8(uint8_t u)
{
  checksum_write(&u, 1);
}

static void checksum_write_16be(uint16_t u)
{
  uint8_t buf[2];

  orter_io_set_16be(u, buf);
  checksum_write(buf, 2);
}

static void checksum_end(void)
{
  fputc(-checksum, stdout);
}

static int orter_hx20_bin_write(uint16_t load, uint16_t exec)
{
  uint8_t data[255];
  size_t s;
  uint16_t addr = load;

  /* intermediate records */
  while ((s = fread(data, 1, 255, stdin))) {
    checksum_start();
    /* length */
    checksum_write_8(s);
    /* address */
    checksum_write_16be(addr);
    /* data */
    checksum_write(data, s);
    /* checksum */
    checksum_end();
    addr += s;
  }
  /* last record */
  checksum_start();
  checksum_write_8(0);
  /* entry point */
  checksum_write_16be(exec);
  /* checksum */
  checksum_end();

  fflush(stdout);
  return 0;
}

static void bit(uint8_t b)
{
  int i, duty = (b ? 22 : 11);

  for (i = 0; i < duty; ++i) {
    orter_wav_write_16le(-32768);
  }
	for (i = 0; i < duty; ++i) {
    orter_wav_write_16le(32767);
  }
}

static void byte(uint8_t b)
{
  uint8_t m;

	for (m = 1; m; m <<= 1) {
    bit(b & m);
  }
	bit(1);
}

static void gap(size_t s)
{
	for (; s; --s) {
    byte(0xFF);
  }
}

static uint16_t crc = 0;

static void crc_start(void)
{
  crc = 0;
}

static void crc_write(uint8_t *p, size_t s)
{
  uint8_t b, k;

  while (s--) {
    b = *(p++);
    crc ^= b;
    for (k = 8; k; --k) {
      crc = (crc & 0x0001) ? ((crc >> 1) ^ 0x8408) : (crc >> 1);
    }
    byte(b);
  }
}

static void crc_write_16be(uint16_t u)
{
  uint8_t buf[2];

  orter_io_set_16be(u, (uint8_t *) &buf);
  crc_write(buf, 2);
}

static void crc_end(void)
{
  uint8_t buf[2];

  /* LE not BE */
  orter_io_set_16le(crc, (uint8_t *) &buf);
  byte(buf[0]);
  byte(buf[1]);
}

static void block(char typ, uint8_t *dat, size_t s, uint16_t bno)
{
  uint8_t buf[256];
  uint8_t bin, j;

  /* pad data */
  memset(buf, '\0', 256);
  memcpy(buf, dat, s);

  /* repeat block twice */
  for (bin = 0; bin < 2; ++bin) {
    /* synchronization field */
    for (j = 0; j < 80; ++j) {
      bit(0);
    }
    /* extra bit necessary */
    bit(1);
    /* preamble */
    byte(0xFF);
    byte(0xAA);
    crc_start();
    /* block identifier field */
    crc_write((uint8_t *) &typ, 1);
    /* block number */
    crc_write_16be(bno);
    /* block identification number */
    crc_write(&bin, 1);
    /* data */
    crc_write(buf, (typ == 'D') ? 256 : 80);
    /* block check character */
    crc_end();
    /* postamble */
    byte(0xAA);
    byte(0x00);
    gap(50);
  }
}

static void header(uint8_t *hdr, char *id, char *nam, char *tim)
{
  memset(hdr, ' ', 80);
  /* ID field */
  memcpy(hdr, id, 4);
  /* file name */
  memcpy(hdr + 4, nam, strlen(nam));
  /* file type */
  memcpy(hdr + 15, "\x02\x00\x00\x00\x00", 5);
  /* record type, interblock gap length, block length */
  memcpy(hdr + 20, "2S  256", 7);
  /* date and time */
  memcpy(hdr + 32, tim, 12);
  /* system name */
  memcpy(hdr + 52, "HX-20", 5);
}

static int orter_hx20_wav_write(char *nam)
{
  uint8_t dat[256];
  int bno = 0;
  size_t s;
  char datetime[13];
  time_t now;
  struct tm *localnow;

  /* timestamp */
  time(&now);
  localnow = localtime(&now);
  strftime(datetime, sizeof(datetime), "%m%d%y%H%M%S", localnow);

  orter_wav_start();

  /* header */
  gap(100);
  header(dat, "HDR1", nam, datetime);
  block('H', dat, 80, bno++);
  gap(100);

  /* data */
  while ((s = fread(dat, 1, 256, stdin))) {
    block('D', dat, s, bno++);
  }

  /* EOF */
  header(dat, "EOF ", nam, datetime);
  block('E', dat, 80, bno++);
  gap(300);

  orter_wav_end();

  return 0;
}

int orter_hx20(int argc, char *argv[])
{
  if (argc == 6 && !strcmp("bin", argv[2]) && !strcmp("write", argv[3])) {
    return orter_hx20_bin_write(strtol(argv[4], 0, 0), strtol(argv[5], 0, 0));
  }
  if (argc == 5 && !strcmp("wav", argv[2]) && !strcmp("write", argv[3])) {
    return orter_hx20_wav_write(argv[4]);
  }

  /* usage */
  fprintf(stderr, "Usage: orter hx20 bin write <load> <exec>\n");
  fprintf(stderr, "                  wav write <filename>\n");
  return 1;
}
