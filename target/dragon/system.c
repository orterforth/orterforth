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

  /* 8N1, 1200 baud, no echo */
  *((uint8_t *) (ACIA+2)) = 0x0B;
  *((uint8_t *) (ACIA+3)) = 0x18;
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
  /* Cmd */
  *((uint8_t *) (ACIA+2)) |= 0x01;
  /* RDRF */
  while (!(*((uint8_t *) (ACIA+1)) & 0x08)) {
  }
  /* Cmd */
  *((uint8_t *) (ACIA+2)) &= 0xFE;
  /* RDR */
  return *((uint8_t *) ACIA);
}

void rf_serial_put(uint8_t b)
{
  /* TDRE */
  while (!(*((uint8_t *) (ACIA+1)) & 0x10)) {
  }
  /* TDR */
  *((uint8_t *) ACIA) = b;
}

void rf_fin(void)
{
  /* might reset Speedkey here. */
}
