/* SYSTEM BINDINGS */

#include "rf.h"

void rf_serial_init(void);

uint8_t rf_console_get(void);

void __FASTCALL__ rf_console_put(uint8_t b);

uint8_t __FASTCALL__ rf_serial_get(void);

void __FASTCALL__ rf_serial_put(uint8_t b);

void rf_serial_fin(void);

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
    rf_console_put(c);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    uint8_t c;
    c = rf_console_get();
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
  rf_console_put('\r');
  rf_console_put('\n');
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, unsigned char len)
{
  for (; len; len--) {
    *(c++) = rf_serial_get();
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
    rf_serial_put(*(p++));
  }
}

void rf_fin(void)
{
  rf_serial_fin();
}
