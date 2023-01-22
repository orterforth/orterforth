#include <cmoc.h>

#include "../../rf.h"

void rf_init(void)
{
}

void rf_code_emit(void)
{
  RF_START;
  putchar(RF_SP_POP & 0x7F);
  RF_USER_OUT++;
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  /* TODO show cursor, fetch key */
  for (;;) {}
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
{
  RF_START;
  putchar(10);
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, unsigned char len)
{
  while (len--) {
    while (!(*((uint8_t *) 0xFF05) & 0x10)) {
    }
    *(p++) = *((uint8_t *) 0xFF04);
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  *((uint8_t *) 0xFF06) |= 0x01;
  while (len--) {
    while (!(*((uint8_t *) 0xFF05) & 0x08)) {
    }
    *((uint8_t *) 0xFF04) = *(p++);
  }
  *((uint8_t *) 0xFF06) &= 0xFE;
}

void rf_fin(void)
{
}
