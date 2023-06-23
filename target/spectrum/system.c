/* SYSTEM BINDINGS */

#include <rs232.h>

#include "rf.h"

void rf_init()
{
  /* disc controller over RS232 */
  if (rs232_params(RS_BAUD_9600 | RS_BITS_8 | RS_STOP_1, RS_PAR_NONE) != RS_ERR_OK) {
    exit(1);
  }
  if (rs232_init() != RS_ERR_OK) {
    exit(1);
  }
}

void rf_code_emit()
{
  RF_START;
  {
    uint8_t c;
    
    c = RF_SP_POP & 0x7F;
    fputc_cons(c);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

static char capslock = 1;

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* show cursor */
    fputc_cons('_');
    fputc_cons(32);
    fputc_cons(8);
    fputc_cons(8);

    /* caps lock */
    while ((c = fgetc_cons()) == 6) {
      capslock ^= 1;
    }

    /* eof */
    if (c == -1) {
      exit(0);
    }

    /* LF to CR */
    if (c == 10) {
      c = 13;
    }

    /* apply caps lock */
    if (capslock && c > 96 && c < 123) {
      c ^= 0x20;
    }

    /* return key */
    RF_SP_PUSH(c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  RF_SP_PUSH(in_KeyPressed(0x817F));
  RF_JUMP_NEXT;
}

void rf_code_cr()
{
  RF_START;
  fputc_cons(10);
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, uint8_t len)
{
  ++len;
  while (--len) {
    while (rs232_get(c) == RS_ERR_NO_DATA) {
    }
    c++;
  }
}

void rf_disc_write(char *p, uint8_t len)
{
  ++len;
  while (--len) {
    while (rs232_put(*p) == RS_ERR_OVERFLOW) {
    }
    p++;
  }
}

void rf_fin(void)
{
  if (rs232_close() != RS_ERR_OK) {
    exit(1);
  }
}
