/* SYSTEM BINDINGS */

#include <stdint.h>

/* MOS calls */

uint8_t osbyte(uint8_t a, uint8_t x);

void osnewl(void);

uint8_t osrdch(void);

void oswrch(uint8_t a);

void rf_init(void)
{
  /* RS423 baud rate */
  osbyte(7, 7);
  osbyte(8, 7);

  /* enable RS423 but start with keyboard/screen */
  osbyte(2, 2);
  osbyte(3, 4);
}

uint8_t rf_console_get(void)
{
  return osrdch();
}

void rf_console_put(uint8_t b)
{
  oswrch(b);
  if (b == 8) {
    oswrch(' ');
    oswrch(b);
  }
}

uint8_t rf_console_qterm(void)
{
  return osbyte(0x79, 0xF0) & 0x80 ? 1 : 0;
}

void rf_console_cr(void)
{
  osnewl();
}

uint8_t rf_serial_get(void)
{
  uint8_t b;

  /* switch from keyboard to RS423 */
  osbyte(2, 1);

  /* read byte */
  b = osrdch();

  /* switch from RS423 to keyboard */
  osbyte(2, 2);

  return b;
}

void rf_serial_put(uint8_t b)
{
  /* switch from screen to RS423 */
  osbyte(3, 7);

  /* write byte */
  oswrch(b);

  /* switch from RS423 to screen */
  osbyte(3, 4);
}

void rf_fin(void)
{
  /* switch back to screen and keyboard */
  osbyte(2, 0);
  osbyte(3, 4);
}
