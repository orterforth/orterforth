#include <stdint.h>
#include <stdlib.h>

void rf_init(void)
{
}

void __FASTCALL__ rf_console_put(uint8_t b)
{
  /* FF to BS */
  if (b == 0x0C) {
    fputc_cons(0x08);
    fputc_cons(0x20);
    fputc_cons(0x08);
    return;
  }

  fputc_cons(b);
}

uint8_t rf_console_get(void)
{
  uint8_t b;

  /* draw cursor */
  fputc_cons('c');
  fputc_cons(0x08);
  /* fetch byte */
  b = fgetc_cons();
  /* erase cursor */
  fputc_cons(0x20);
  fputc_cons(0x08);
  /* LF to CR */
  if (b == 10) b = 13;

  return b;
}

uint8_t rf_console_qterm(void)
{
  return 0;
}

void rf_console_cr(void)
{
  fputc_cons('\n');
}

void __FASTCALL__ rf_serial_put(uint8_t b)
{

  while (!(*((uint8_t *) 12045) & 0x10)) { }
  *((uint8_t *) 12040) = b;
}

uint8_t rf_serial_get(void)
{
  while (!(*((uint8_t *) 12045) & 0x08)) { }
  return *((uint8_t *) 12044);
}

void rf_fin(void)
{
}
