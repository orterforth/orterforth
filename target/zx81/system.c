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

  fputc_cons('c');
  fputc_cons(0x08);
  b = fgetc_cons();
  fputc_cons(0x20);
  fputc_cons(0x08);
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
  /* dummy OUT op - custom emulation */
  outp(0x99, b);
}

uint8_t rf_serial_get(void)
{
  /* dummy IN op - custom emulation */
  return inp(0x99);
}

void rf_fin(void)
{
}
