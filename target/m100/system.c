/* SYSTEM BINDINGS */

#include <stdio.h>

#include "rf.h"

void rf_serial_init(void);

void rf_init(void)
{
  rf_serial_init();
}

void rf_code_emit(void)
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

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* return key */
    c = getchar();
    /* LF back to CR */
    if (c == 10) c = 13;
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
  putchar('\n');
  RF_JUMP_NEXT;
}

uint8_t __FASTCALL__ rf_serial_get(void);

void rf_disc_read(char *c, unsigned char len)
{
  for (; len; len--) {
    *(c++) = rf_serial_get();
  }
}

void __FASTCALL__ rf_serial_put(uint8_t b);

void rf_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
    rf_serial_put(*(p++));
  }
}

void rf_serial_fin(void);

void rf_fin(void)
{
  rf_serial_fin();
}
