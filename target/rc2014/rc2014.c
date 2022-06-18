/* SYSTEM BINDINGS */

#include <stdio.h>

#include "rf.h"

void rf_init()
{
  putchar('@');
  putchar('\n');
}

void rf_code_emit()
{
  RF_START;
  {
    unsigned char c;
    
    c = RF_SP_POP & 0x7F;
    putchar(c);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

static char capslock = 0;

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* caps lock */
    c = getchar();

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

void rf_code_cr()
{
  RF_START;
  putchar(10);
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, unsigned char len)
{
  for (; len; len--) {
    *(c++) = getchar();
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
    putchar(*(p++));
  }
}

void rf_fin(void)
{
}
