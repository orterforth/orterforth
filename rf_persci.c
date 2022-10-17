#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rf_persci.h"

/* STATE */

#define RF_PERSCI_STATE_COMMAND 0
#define RF_PERSCI_STATE_WRITING 1

static char rf_persci_state = RF_PERSCI_STATE_COMMAND;

/* DRIVES */

static FILE *files[4] = { 0, 0, 0, 0 };

static uint8_t *discs[4] = { 0, 0, 0, 0 };

static void validate_drive_no(int drive)
{
  if (drive < 0 || drive > 3) {
    fprintf(stderr, "invalid drive number %d\n", drive);
    exit(1);
  }
}

void rf_persci_insert(int drive, char *filename)
{
  FILE *ptr;

  validate_drive_no(drive);

  /* disc must be not already inserted */
  ptr = files[drive];
  if (ptr) {
    fprintf(stderr, "file already open: drive %d\n", drive);
    exit(1);
  }

  /* open disc file */
  files[drive] = ptr = fopen(filename, "r+b");
  if (!ptr) {
    perror("fopen failed");
    exit(1);
  }

  /* read contents into memory */
  if (!(discs[drive] = malloc(256256))) {
    fprintf(stderr, "malloc failed: drive %d\n", drive);
    exit(1);
  }
  fread(discs[drive], 1, 256256, ptr);
  if (ferror(ptr)) {
    fprintf(stderr, "fread failed: drive %d\n", drive);
    exit(1);
  }

  /* reset controller state */
  rf_persci_state = RF_PERSCI_STATE_COMMAND;
}

void rf_persci_insert_bytes(int drive, char *filename, const uint8_t *bytes, unsigned int len)
{
  validate_drive_no(drive);

  /* point at byte array */
  discs[drive] = (uint8_t *) bytes;

  /* reset controller state */
  rf_persci_state = RF_PERSCI_STATE_COMMAND;
}

void rf_persci_eject(int drive)
{
  validate_drive_no(drive);

  /* close the file */
  if (files[drive]) {
    fclose(files[drive]);
    files[drive] = 0;

    /* assume malloc was used */
    if (discs[drive]) {
      free(discs[drive]);
    }
  }

  discs[drive] = 0;
}

/* BUFFER */

/* read buffer */
static char rf_persci_r_buf[131];
static unsigned int rf_persci_r_idx = 0;
static unsigned int rf_persci_r_len = 0;

/* write buffer */
static char rf_persci_w_buf[131];
static unsigned int rf_persci_w_idx = 0;
static unsigned int rf_persci_w_len = 0;

/* empty buffers */
static void rf_persci_reset(void)
{
  rf_persci_r_idx = 0;
  rf_persci_r_len = 0;
  rf_persci_w_idx = 0;
  rf_persci_w_len = 0;
}

/* write a char to write buffer */
static void rf_persci_w(char c)
{
  rf_persci_w_buf[rf_persci_w_len++] = c;
}

/* write a string to write buffer */
static void rf_persci_ws(const char *s)
{
  const char *i;

  for (i = s; *i; i++) {
    rf_persci_w(*i);
  }
}

/* ERROR HANDLING */

/* write error message */
static void rf_persci_error(const char *message)
{
  rf_persci_w(RF_ASCII_NAK);
  rf_persci_ws(message);
  rf_persci_ws(" ERROR\r\n\004");
}

/* write error message with drive number */
static void rf_persci_error_on_drive(const char *message, uint8_t drive)
{
  rf_persci_w(RF_ASCII_NAK);
  rf_persci_ws(message);
  rf_persci_ws(" ERROR ON DRIVE #");
  rf_persci_w(48 + drive);
  rf_persci_ws("\r\n\004");
}

/* READING AND WRITING */

/* validate drive track and sector are within ranges */
static char rf_persci_validate(uint8_t track, uint8_t sector, uint8_t drive)
{
  /* validate drive number */
  if (drive > 3) {
    rf_persci_error("COMMAND");
    return 1;
  }

  /* validate track and sector numbers */
  if (track > 76 || sector < 1 || sector > 26) {
    rf_persci_error_on_drive("COMMAND", drive);
    return 1;
  }

  return 0;
}

/* track and sector offset */
static long offset(uint8_t track, uint8_t sector)
{
  return ((track * 26) + (sector - 1)) * 128;
}

/* move to track and sector */
static int seek(FILE *ptr, long off, uint8_t drive)
{
  if (fseek(ptr, off, SEEK_SET)) {
    perror("fseek failed");
    rf_persci_reset();
    rf_persci_error_on_drive("HARD DISK", drive);
    return 1;
  }

  return 0;
}

/* I (Input) */
static void rf_persci_input(uint8_t track, uint8_t sector, uint8_t drive)
{
  uint8_t i;
  uint8_t *p;

  /* reset buffer */
  rf_persci_reset();

  /* validate args */
  if (rf_persci_validate(track, sector, drive)) {
    return;
  }

  /* check disc is present */
  if (!discs[drive]) {
    rf_persci_error_on_drive("READY", drive);
    return;
  }

  /* start response */
  rf_persci_w(RF_ASCII_SOH);

  /* read from memory */
  p = discs[drive] + offset(track, sector);
  i = 128;
  for (; i; --i) {
    rf_persci_w(*(p++));
  }

  /* ACK EOT */
  rf_persci_w(RF_ASCII_ACK);
  rf_persci_w(RF_ASCII_EOT);
}

static uint8_t rf_persci_drive = 0;
static uint8_t rf_persci_track = 0;
static uint8_t rf_persci_sector = 0;

/* O (Output) */
static void rf_persci_output(uint8_t track, uint8_t sector, uint8_t drive)
{
  /* reset buffer */
  rf_persci_reset();

  /* validate args */
  if (rf_persci_validate(track, sector, drive)) {
    return;
  }

  /* set state */
  rf_persci_state = RF_PERSCI_STATE_WRITING;

  /* set desired track/sector/drive */
  rf_persci_track = track;
  rf_persci_sector = sector;
  rf_persci_drive = drive;

  /* ENQ EOT */
  rf_persci_w(RF_ASCII_ENQ);
  rf_persci_w(RF_ASCII_EOT);
}

/* write data after O */
static void rf_persci_write()
{
  FILE *ptr;
  size_t s;
  long off;
  size_t len;

  /* get size of data */
  for (; rf_persci_r_buf[rf_persci_r_idx] != RF_ASCII_EOT; rf_persci_r_idx++) {
  }
  len = rf_persci_r_idx > 128 ? 128 : rf_persci_r_idx;

  /* open file */
  ptr = files[rf_persci_drive];
  if (!ptr) {
    rf_persci_reset();
    rf_persci_error_on_drive("READY", rf_persci_drive);
    return;
  }

  /* move to track and sector */
  off = offset(rf_persci_track, rf_persci_sector);
  if (seek(ptr, off, rf_persci_drive)) {
    return;
  }

  /* write data to file */
  s = fwrite(rf_persci_r_buf, 1, len, ptr);
  fflush(ptr);

  /* handle write failure */
  if (s != rf_persci_r_idx) {
    perror("fwrite failed");
    rf_persci_reset();
    rf_persci_error_on_drive("HARD DISK", rf_persci_drive);
    return;
  }

  /* write data to memory */
  memcpy(
    discs[rf_persci_drive] + off, 
    rf_persci_r_buf, 
    len);

  /* ACK EOT */
  rf_persci_reset();
  rf_persci_w(RF_ASCII_ACK);
  rf_persci_w(RF_ASCII_EOT);

  /* reset controller state */
  rf_persci_state = RF_PERSCI_STATE_COMMAND;
}

/* READ */

/* read char from read buffer */
static char rf_persci_r(void)
{
  char c;

  /* validate buffer */
  if (rf_persci_r_idx >= rf_persci_r_len) {
    fprintf(stderr, "read buffer empty\n");
    exit(1);
  }

  /* read char from buffer */
  c = rf_persci_r_buf[rf_persci_r_idx++];

  /* reset buffer if empty */
  if (rf_persci_r_idx >= rf_persci_r_len) {
    rf_persci_r_idx = 0;
    rf_persci_r_len = 0;
  }

  return c;
}

/* COMMAND PARSING */

/* skip whitespace in read buffer */
static void rf_persci_read_ws(void)
{
  /* validate buffer */
  if (rf_persci_r_idx >= rf_persci_r_len) {
    fprintf(stderr, "read buffer empty\n");
    exit(1);
  }

  while (rf_persci_r_buf[rf_persci_r_idx] == ' ') {
    /* skip whitespace */
    rf_persci_r_idx++;

    /* reset buffer if empty */
    if (rf_persci_r_idx >= rf_persci_r_len) {
      rf_persci_r_idx = 0;
      rf_persci_r_len = 0;
    }
  }
}

/* read decimal int from read buffer */
static char rf_persci_read_int(void)
{
  char i;
  char c;

  rf_persci_read_ws();

  i = 0;
  while ((c = rf_persci_r_buf[rf_persci_r_idx]) >= '0' && c <= '9') {
    i *= 10;
    i += (c - 48);
    rf_persci_r_idx++;
  }

  return i;
}

/* read char and check it is as expected */
static char rf_persci_expect(char c)
{
  rf_persci_read_ws();
  if (rf_persci_r_buf[rf_persci_r_idx] == c) {
    rf_persci_r_idx++;
    return 1;
  }
  return 0;
}

/* read command and execute it */
static void rf_persci_command(void)
{
  char ch = rf_persci_r();
  switch (ch) {
    case 'I':
    case 'O':
    {
      int track, sector, drive;

      /* track */
      track = rf_persci_read_int();

      /* sector */
      sector = rf_persci_read_int();

      /* drive */
      if (!rf_persci_expect('/')) {
        break;
      }
      drive = rf_persci_read_int();

      /* EOT */
      if (!rf_persci_expect(RF_ASCII_EOT)) {
        break;
      }

      /* handle command */
      switch (ch) {
        case 'I':
          rf_persci_input(track, sector, drive);
          return;
        case 'O':
          rf_persci_output(track, sector, drive);
          return;
      }

      /* should not get here */
      break;
    }
  }

  /* parse failed */
  rf_persci_error("COMMAND");
}

/* HANDLE COMMS */

/* handle next operation */
static void rf_persci_serve(void)
{
  switch (rf_persci_state) {
    case RF_PERSCI_STATE_COMMAND:
      rf_persci_command();
      break;
    case RF_PERSCI_STATE_WRITING:
      rf_persci_write();
      break;
    default:
      fprintf(stderr, "invalid state\n");
      exit(1);
  }
}

/* read next char from write buffer */
char rf_persci_getc(void)
{
  char c;

  /* validate not empty */
  if (rf_persci_w_idx >= rf_persci_w_len) {
    fprintf(stderr, "write buffer empty");
    exit(1);
  }

  /* get char and reset empty buffer */
  c = rf_persci_w_buf[rf_persci_w_idx++];
  if (rf_persci_w_idx >= rf_persci_w_len) {
    rf_persci_w_idx = 0;
    rf_persci_w_len = 0;
  }

  return c;
}

/* write next char to read buffer and handle if EOT */
void rf_persci_putc(char c)
{
  rf_persci_r_buf[rf_persci_r_len++] = c;
  if (c == RF_ASCII_EOT) {
    rf_persci_serve();
  }
}
