#include <stdio.h>
#include <stdint.h>

void rf_init(void)
{
  /* observe a successful start */
  fputc_cons('A');
}

void __FASTCALL__ rf_console_put(uint8_t b)
{
  fputc_cons(b);
}

uint8_t rf_console_get(void)
{
  return fgetc_cons();
}

uint8_t rf_console_qterm(void)
{
  return 0;
}

void rf_console_cr(void)
{
  fputc_cons(10);
}

void __FASTCALL__ rf_serial_put(uint8_t b)
{
  fputc_cons(b);
}

uint8_t rf_serial_get(void)
{
  return fgetc_cons();
}

void rf_fin(void)
{
}
