#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

void rf_init(void)
{
}

void __FASTCALL__ rf_console_put(uint8_t b)
{
  fputc_cons(b);
}

uint8_t rf_console_get(void)
{
  int b = fgetc_cons();
  /* LF to CR */
  if (b == 10) b = 13;
  /* UC for now */
  if (b >= 'a' && b <= 'z') {
    b ^= 0x20;
  }
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
