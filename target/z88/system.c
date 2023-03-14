/* SYSTEM BINDINGS */

#include "rf.h"

void rf_init()
{
}

void rf_code_emit()
{
  RF_START;
  {
    unsigned char c = RF_SP_POP & 0x7F;
    fputc_cons(c);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c = fgetc_cons();
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

void rf_code_cr()
{
  RF_START;
  fputc_cons('\n');
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, unsigned char len)
{
  for (; len; len--) {
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
  }
}

void rf_fin(void)
{
}
