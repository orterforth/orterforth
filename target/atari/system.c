#include <conio.h>
#include <stdint.h>
#include <stdio.h>

#include <atari.h>
#include <serial.h>

static const struct ser_params params = {
  SER_BAUD_9600,
  SER_BITS_8,
  SER_STOP_1,
  SER_PAR_NONE,
  SER_HS_HW
};

void rf_init(void)
{
  ser_install(atrrdev_ser);
  ser_open(&params);
  cursor(1);
}

void rf_console_put(uint8_t b)
{
  /* BS to ATASCII delete */
  if (b == 0x08) b = 0x7E;
  putchar(b);
}

uint8_t rf_console_get(void)
{
  uint8_t b = cgetc();
  /* ATASCII end of line to CR */
  if (b == 0x9B) b = 0x0D;
  return b;
}

uint8_t rf_console_qterm(void)
{
  return *((uint8_t *) 53769) == 28;
}

void rf_console_cr(void)
{
  putchar('\n');
}

uint8_t rf_serial_get(void)
{
  uint8_t b;
  while (ser_get(&b) == SER_ERR_NO_DATA) { }
  return b;
}

void rf_serial_put(uint8_t b)
{
  while (ser_put(b) == SER_ERR_OVERFLOW) { };
}

void rf_fin(void)
{
  ser_close();
}
