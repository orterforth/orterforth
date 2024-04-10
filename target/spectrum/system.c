#include <rs232.h>
#include <stdio.h>
#include <stdint.h>

void rf_init(void)
{
  rs232_params(RS_BAUD_9600 | RS_BITS_8 | RS_STOP_1, RS_PAR_NONE);
  rs232_init();
}

void __FASTCALL__ rf_console_put(uint8_t b)
{
  fputc_cons(b);
}

static char capslock = 1;

uint8_t rf_console_get(void)
{
  int c;

  /* show cursor */
  fputc_cons('_');
  fputc_cons(32);
  fputc_cons(8);
  fputc_cons(8);

  /* caps lock */
  while ((c = fgetc_cons()) == 6) {
    capslock ^= 1;
  }

  /* LF to CR */
  if (c == 10) {
    c = 13;
  }

  /* apply caps lock */
  if (capslock && c > 96 && c < 123) {
    c ^= 0x20;
  }

  /* return key */
  return c;
}

uint8_t rf_console_qterm(void)
{
  return (in_KeyPressed(0x817F));
}

void rf_console_cr(void)
{
  fputc_cons(10);
}

uint8_t rf_serial_get(void)
{
  uint8_t b;

  while (rs232_get(&b) == RS_ERR_NO_DATA) { }

  return b;
}

void __FASTCALL__ rf_serial_put(uint8_t b)
{
  while (rs232_put(b) == RS_ERR_OVERFLOW) { }
}

void rf_fin(void)
{
  rs232_close();
}
