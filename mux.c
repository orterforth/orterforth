#include <stdio.h>

#include "rf.h"

void rf_code_emit(void)
{
  RF_START;
  {
    unsigned char c;
    
    c = RF_SP_POP & 0x7F;
    putchar(c);
    if (c == 0x08) {
      putchar(' ');
      putchar(c);
    }
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* skip disc input */
    while (((c = getchar()) & 0x80)) {
    }

    /* LF to CR */
    if (c == 10) {
      c = 13;
    }

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
  putchar(10);
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, unsigned char len)
{
  for (; len; len--) {
    /* skip keyboard input */
    while (!((*c = getchar()) & 0x80)) {
    }
    *(c++) &= 0x7F;
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
    putchar(*(p++) | 0x80);
  }
}

