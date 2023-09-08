#include <stdint.h>

#include "../../rf.h"

void rf_init(void)
{
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c;
    
    c = RF_SP_POP & 0x7F;
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    RF_SP_PUSH(c & 0x7F);
  }
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
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, uint8_t len)
{
}

void rf_disc_write(char *p, uint8_t len)
{
}

void rf_fin(void)
{
}
