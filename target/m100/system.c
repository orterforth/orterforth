/* SYSTEM BINDINGS */

#include "rf.h"

void rf_init(void)
{
}

void rf_code_emit(void)
{
  RF_START;
  {
    unsigned char c;
    
    c = RF_SP_POP & 0x7F;
    /* TODO output char */
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* TODO input char */

    /* return key */
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
  /* TODO output CR */
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, unsigned char len)
{
  for (; len; len--) {
    /* TODO read serial */
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
    /* TODO write serial */
  }
}

void rf_fin(void)
{
}
