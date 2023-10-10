#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "persci.h"

/* STATE */

#define RF_PERSCI_STATE_IDLE 0
#define RF_PERSCI_STATE_INPUT 1
#define RF_PERSCI_STATE_OUTPUT 2
#define RF_PERSCI_STATE_WRITING 3
#define RF_PERSCI_STATE_WRITTEN 4
#define RF_PERSCI_STATE_ERROR 5

static char rf_persci_state = RF_PERSCI_STATE_IDLE;

/* DRIVES */

static FILE *files[4] = { 0, 0, 0, 0 };

static uint8_t *discs[4] = { 0, 0, 0, 0 };

static int validate_drive_no(int drive)
{
  if (drive < 0 || drive > 3) {
    fprintf(stderr, "invalid drive number %d\n", drive);
    return 1;
  }

  return 0;
}

int rf_persci_insert(int drive, char *filename)
{
  FILE *ptr;

  /* 0-3 only */
  if (validate_drive_no(drive)) {
    return 1;
  }

  /* disc must be not already inserted */
  ptr = files[drive];
  if (ptr) {
    fprintf(stderr, "file already open: drive %d\n", drive);
    return 1;
  }

  /* open disc file */
  files[drive] = ptr = fopen(filename, "r+b");
  if (!ptr) {
    perror("fopen failed");
    fprintf(stderr, "filename=%s\n", filename);
    return 1;
  }

  /* read contents into memory */
  if (!(discs[drive] = malloc(256256))) {
    fprintf(stderr, "malloc failed: drive %d\n", drive);
    fclose(ptr);
    files[drive] = 0;
    return 1;
  }
  fread(discs[drive], 1, 256256, ptr);
  if (ferror(ptr)) {
    fprintf(stderr, "fread failed: drive %d\n", drive);
    fclose(ptr);
    files[drive] = 0;
    return 1;
  }

  return 0;
}

void rf_persci_insert_bytes(int drive, const uint8_t *bytes)
{
  /* 0-3 only */
  validate_drive_no(drive);

  /* point at byte array */
  discs[drive] = (uint8_t *) bytes;
}

void rf_persci_eject(int drive)
{
  /* 0-3 only */
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

static char rf_persci_buf[131];
static unsigned int rf_persci_idx = 0;
static unsigned int rf_persci_len = 0;

/* empty buffers */
static void rf_persci_reset(void)
{
  rf_persci_idx = 0;
  rf_persci_len = 0;
}

/* write a char to buffer */
static void rf_persci_w(char c)
{
  /* validate not full */
  if (rf_persci_len >= 131) {
    fprintf(stderr, "rf_persci_w buffer full\n");
    exit(1);
  }

  rf_persci_buf[rf_persci_len++] = c;
}

/* write a string to buffer */
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
  /* send error */
  rf_persci_reset();
  rf_persci_w(RF_ASCII_NAK);
  rf_persci_ws(message);
  rf_persci_ws(" ERROR\r\n\004");

  /* set state */
  rf_persci_state = RF_PERSCI_STATE_ERROR;
}

/* write error message with drive number */
static void rf_persci_error_on_drive(const char *message, uint8_t drive)
{
  /* send error */
  rf_persci_reset();
  rf_persci_w(RF_ASCII_NAK);
  rf_persci_ws(message);
  rf_persci_ws(" ERROR ON DRIVE #");
  rf_persci_w(48 + drive);
  rf_persci_ws("\r\n\004");

  /* set state */
  rf_persci_state = RF_PERSCI_STATE_ERROR;
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

  /* check disc is present */
  if (!discs[drive]) {
    rf_persci_error_on_drive("READY", drive);
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

/* I (Input) */
static void rf_persci_input(uint8_t track, uint8_t sector, uint8_t drive)
{
  uint8_t i;
  uint8_t *p;

  /* start response */
  rf_persci_reset();
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

  /* set state */
  rf_persci_state = RF_PERSCI_STATE_INPUT;
}

static uint8_t rf_persci_drive = 0;
static uint8_t rf_persci_track = 0;
static uint8_t rf_persci_sector = 0;

/* O (Output) */
static void rf_persci_output(uint8_t track, uint8_t sector, uint8_t drive)
{
  /* set desired track/sector/drive */
  rf_persci_track = track;
  rf_persci_sector = sector;
  rf_persci_drive = drive;

  /* ENQ EOT */
  rf_persci_reset();
  rf_persci_w(RF_ASCII_ENQ);
  rf_persci_w(RF_ASCII_EOT);

  /* set state */
  rf_persci_state = RF_PERSCI_STATE_OUTPUT;
}

/* READ */

/* read next char from buffer */
static char rf_persci_peek(void)
{
  /* validate buffer */
  if (rf_persci_idx >= rf_persci_len) {
    fprintf(stderr, "buffer empty\n");
    exit(1);
  }

  /* read char from buffer */
  return rf_persci_buf[rf_persci_idx];
}

/* read next char from buffer and advance */
static char rf_persci_r(void)
{
  char c = rf_persci_peek();

  /* advance and reset if empty */
  rf_persci_idx++;
  if (rf_persci_idx >= rf_persci_len) {
    rf_persci_idx = 0;
    rf_persci_len = 0;
  }

  return c;
}

/* write data after O */
static void rf_persci_write(void)
{
  FILE *ptr;
  size_t s;
  long off;
  size_t len;

  /* get size of data */
  for (len = 0; rf_persci_r() != RF_ASCII_EOT; ++len) {
  }

  /* get location */
  off = offset(rf_persci_track, rf_persci_sector);

  /* write data to file (if present) */
  ptr = files[rf_persci_drive];
  if (ptr) {

    /* move to track and sector */
    if (fseek(ptr, off, SEEK_SET)) {
      perror("fseek failed");
      rf_persci_error_on_drive("HARD DISK", rf_persci_drive);
      return;
    }

    /* write sector */
    s = fwrite(rf_persci_buf, 1, len, ptr);
    if (s != len) {
      perror("fwrite failed");
      rf_persci_error_on_drive("HARD DISK", rf_persci_drive);
      return;
    }
    if (fflush(ptr)) {
      perror("fflush failed");
      rf_persci_error_on_drive("HARD DISK", rf_persci_drive);
    }
  }

  /* write data to memory */
  memcpy(
    discs[rf_persci_drive] + off, 
    rf_persci_buf, 
    len);

  /* ACK EOT */
  rf_persci_reset();
  rf_persci_w(RF_ASCII_ACK);
  rf_persci_w(RF_ASCII_EOT);

  /* reset controller state */
  rf_persci_state = RF_PERSCI_STATE_WRITTEN;
}

/* COMMAND PARSING */

/* skip whitespace in buffer */
static void rf_persci_read_ws(void)
{
  /* validate buffer */
  if (rf_persci_idx >= rf_persci_len) {
    fprintf(stderr, "buffer empty\n");
    exit(1);
  }

  while (rf_persci_peek() == ' ') {
    /* skip whitespace */
    rf_persci_r();
  }
}

/* read decimal int from buffer */
static char rf_persci_read_int(void)
{
  char i;
  char c;

  rf_persci_read_ws();

  i = 0;
  while ((c = rf_persci_peek()) >= '0' && c <= '9') {
    rf_persci_r();
    i *= 10;
    i += (c - 48);
  }

  return i;
}

/* read char and check it is as expected */
static char rf_persci_expect(char c)
{
  rf_persci_read_ws();
  if (rf_persci_peek() == c) {
    rf_persci_r();
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

      /* validate args */
      if (rf_persci_validate(track, sector, drive)) {
        return;
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
    case RF_PERSCI_STATE_IDLE:
      rf_persci_command();
      break;
    case RF_PERSCI_STATE_WRITING:
      rf_persci_write();
      break;
    default:
      fprintf(stderr, "rf_persci_serve invalid state\n");
      exit(1);
  }
}

/* read next char from buffer */
int rf_persci_getc(void)
{
  int c;

  /* validate state */
  if (rf_persci_state != RF_PERSCI_STATE_INPUT && 
    rf_persci_state != RF_PERSCI_STATE_OUTPUT && 
    rf_persci_state != RF_PERSCI_STATE_WRITTEN &&
    rf_persci_state != RF_PERSCI_STATE_ERROR) {
    return -1;
  }

  /* test not empty */
  if (rf_persci_idx >= rf_persci_len) {
    return -1;
  }

  /* get char */
  c = rf_persci_r();
  /* when empty set state */
  if (rf_persci_idx == 0) {
    rf_persci_state = (rf_persci_state == RF_PERSCI_STATE_OUTPUT) ? RF_PERSCI_STATE_WRITING : RF_PERSCI_STATE_IDLE;
  }

  return c;
}

/* write next char to buffer and handle if EOT */
int rf_persci_putc(char c)
{
  /* validate state */
  if (rf_persci_state != RF_PERSCI_STATE_IDLE && rf_persci_state != RF_PERSCI_STATE_WRITING) {
    return -1;
  }

  /* write to buffer */
  rf_persci_w(c);

  /* on EOT, operate */
  if (c == RF_ASCII_EOT) {
    rf_persci_serve();
  }

  return c;
}
