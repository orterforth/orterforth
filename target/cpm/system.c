#include <stdint.h>
#include <stdio.h>

void rf_init(void)
{
  fputc_cons('A');
}

uint8_t rf_console_get(void)
{
  return fgetc_cons();
}

void __FASTCALL__ rf_console_put(uint8_t b)
{
  fputc_cons(b);
}

uint8_t rf_console_qterm(void)
{
  return 0;
}

void rf_console_cr(void)
{
  fputc_cons('\n');
}

uint8_t rf_serial_get(void)
{
  return 0;
}

void __FASTCALL__ rf_serial_put(uint8_t b)
{
}

void rf_fin(void)
{
}
