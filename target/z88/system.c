#include <rs232.h>
#include <stdint.h>

#include "rf.h"

void rf_init(void)
{
  rs232_params(RS_BAUD_9600 | RS_BITS_8 | RS_STOP_1, RS_PAR_NONE);
  rs232_init();
}

void rf_code_emit(void)
{
  RF_START;
  {
    unsigned char c = (*(rf_sp++)) & 0x7F;
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
    /* LF -> CR  */
    if (c == 10) c = 13;
    *(--rf_sp) = (c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  *(--rf_sp) = 0;
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
{
  RF_START;
  fputc_cons('\n');
  RF_JUMP_NEXT;
}

static uint8_t rf_serial_get(void)
{
  uint8_t b;
  while (rs232_get(&b) == RS_ERR_NO_DATA) { }
  return b;
}

static void __FASTCALL__ rf_serial_put(uint8_t b)
{
  while (rs232_put(b) == RS_ERR_OVERFLOW) { }
}

void rf_code_dchar(void)
{
  RF_START;
  {
    uint8_t a, c;

    a = (uint8_t) (*(rf_sp++));
    c = rf_serial_get();
    *(--rf_sp) = (c == a);
    *(--rf_sp) = (c);
  }
  RF_JUMP_NEXT;
}

void rf_code_bread(void)
{
  RF_START;
  {
    uint8_t *b = (uint8_t *) (*(rf_sp++));
    uint8_t len = RF_BBLK + 1;

    while (--len) {
      *(b++) = rf_serial_get();
    }
  }
  RF_JUMP_NEXT;
}

void rf_code_bwrit(void)
{
  RF_START;
  {
    uint8_t a = (uint8_t) (*(rf_sp++));
    uint8_t *b = (uint8_t *) (*(rf_sp++));

    ++a;
    while (--a) {
      rf_serial_put(*(b++));
    }
    rf_serial_put(0x04);
  }
  RF_JUMP_NEXT;
}

void rf_fin(void)
{
  rs232_close();
}
