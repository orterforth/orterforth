#include <rs232.h>
#include <stdint.h>

void rf_init(void)
{
  rs232_params(RS_BAUD_9600 | RS_BITS_8 | RS_STOP_1, RS_PAR_NONE);
  rs232_init();
}

void __FASTCALL__ rf_console_put(uint8_t c)
{
  fputc_cons(c);
  /* backspace clear */
  if (c == 8) {
    fputc_cons(' ');
    fputc_cons(c);
  }
}

uint8_t rf_console_get(void)
{
  int c = fgetc_cons();
  /* LF -> CR  */
  if (c == 10) c = 13;
  return c;
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
