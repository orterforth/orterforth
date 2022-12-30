#include <cmoc.h>

#include "../../rf.h"

void rf_init(void)
{
  printf("init\n");
}

void rf_code_emit(void)
{
  RF_START;
  RF_USER_OUT++;
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
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
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, unsigned char len)
{
}

void rf_disc_write(char *p, unsigned char len)
{
  while (len--) {
    putchar(*(p++));
  }
}

void rf_fin(void)
{
}
