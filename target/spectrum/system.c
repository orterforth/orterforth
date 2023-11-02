/* SYSTEM BINDINGS */

#include <rs232.h>

#include "rf.h"

void rf_init(void)
{
  /* disc controller over RS232 */
  if (rs232_params(RS_BAUD_9600 | RS_BITS_8 | RS_STOP_1, RS_PAR_NONE) != RS_ERR_OK) {
    exit(1);
  }
  if (rs232_init() != RS_ERR_OK) {
    exit(1);
  }
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c;
    
    c = (*(rf_sp++)) & 0x7F;
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
    *(--rf_sp) = (c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  *(--rf_sp) = (in_KeyPressed(0x817F));
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
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

void rf_code_dchar(void)
{
  RF_START;
  {
    char a, c;

    a = (char) (*(rf_sp++));
    rf_disc_read(&c, 1);
    *(--rf_sp) = (c == a);
    *(--rf_sp) = (c);
  }
  RF_JUMP_NEXT;
}

void rf_code_bread(void)
{
  RF_START;
  rf_disc_read((char *) (*(rf_sp++)), RF_BBLK);
  RF_JUMP_NEXT;
}

static char eot = 0x04;

void rf_code_bwrit(void)
{
  RF_START;
  {
    uint8_t a = (uint8_t) (*(rf_sp++));
    char *b = (char *) (*(rf_sp++));

    rf_disc_write(b, a);
    rf_disc_write(&eot, 1);
  }
  RF_JUMP_NEXT;
}

void rf_fin(void)
{
  if (rs232_close() != RS_ERR_OK) {
    exit(1);
  }
}
