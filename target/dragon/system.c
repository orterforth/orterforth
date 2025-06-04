#include "../../rf.h"

extern unsigned char *rf_origin;

void rf_init_origin(void);

void rf_init(void)
{
  /* Speedkey http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=314 */
  if (*((uint8_t *) 269) + *((uint8_t *) 270) != 250) {
    *((uint8_t *) 65283) &= 254;
    *((uint8_t *) 250) = 116;
    *((uint8_t *) 251) = 1;
    *((uint8_t *) 252) = 81;
    *((uint8_t *) 253) = 126;
    *((uint8_t *) 254) = *((uint8_t *) 269);
    *((uint8_t *) 255) = *((uint8_t *) 270);
    *((uint8_t *) 269) = 0;
    *((uint8_t *) 270) = 250;
    *((uint8_t *) 65283) |= 1;
  }
  rf_init_origin();
}

void rf_console_put(uint8_t ch)
{
  asm {
    lda :ch
    jsr $B54A
  }
}

uint8_t rf_console_get(void)
{
  char ch;

  asm {
    jsr $B538
    sta :ch
  }

  return ch;
}

uint8_t rf_console_qterm(void)
{
  char k;

  asm {
    jsr $8006
    sta :k
  }

  return (k == 0x03);
}

void rf_console_cr(void)
{
  asm {
    lda #$0D
    jsr $B54A
  }
}

uint8_t rf_serial_get(void)
{
  while (!(*((uint8_t *) 0xFF05) & 0x10)) {
  }
  return *((uint8_t *) 0xFF04);
}

void rf_serial_put(uint8_t b)
{
  *((uint8_t *) 0xFF06) |= 0x01;
  while (!(*((uint8_t *) 0xFF05) & 0x08)) {
  }
  *((uint8_t *) 0xFF04) = b;
  *((uint8_t *) 0xFF06) &= 0xFE;
}

void rf_fin(void)
{
  /* might reset Speedkey here. */
}
