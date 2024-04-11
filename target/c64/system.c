#include <cbm.h>
#include <serial.h>
#include <stdint.h>

static const struct ser_params serial_params = {
    SER_BAUD_2400,
    SER_BITS_8,
    SER_STOP_1,
    SER_PAR_NONE,
    SER_HS_HW
};

extern char c64_serial;
  
void rf_init(void)
{
  /* init serial */
  ser_install(&c64_serial);
  ser_open(&serial_params);
  ser_ioctl(1, NULL);
}

void rf_console_put(uint8_t c)
{
  /* PETSCII swap case */
  if (((c & 0xDF) >= 0x41 && (c & 0xDF) <= 0x5A)) {
    c ^= 0x20;
  }
  /* BS */
  else if (c == 0x08) {
    c = 0x14;
  }

  cbm_k_bsout(c);
}

uint8_t rf_console_get(void)
{
  int c;

  /* show cursor */
  *((uint8_t *) 204) = 0;
  *((uint8_t *) 647) = 1;
  *((uint8_t *) 207) = 0;

  /* wait for key */
  while (!(c = cbm_k_getin())) {
  }

  /* hide cursor */
  *((uint8_t *) 647) = 14;
  *((uint8_t *) 206) = 32;
  *((uint8_t *) 204) = 255;
  *((uint8_t *) 207) = 0;

  /* PETSCII correct case */
  if (c >= 0x41 && c <= 0x5A) {
    c ^= 0x20;
  }

  /* return key */
  return c;
}

uint8_t rf_console_qterm(void)
{
  return (*((uint8_t *) 0x00CB) == 0x3F);
}

void rf_console_cr(void)
{
  cbm_k_bsout(0x0D);
}

uint8_t rf_serial_get(void)
{
  uint8_t b;

  while (ser_get(&b) != SER_ERR_OK) {
  }

  return b;
}

void rf_serial_put(uint8_t b)
{
  while (ser_put(b) == SER_ERR_OVERFLOW) {
  }
}

void rf_fin(void)
{
  ser_close();
  ser_uninstall();
}
