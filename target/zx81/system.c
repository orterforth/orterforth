/* SYSTEM BINDINGS */

#include "rf.h"

void rf_init(void)
{
  /* observe a successful start */
  fputc_cons('A');
}

void rf_code_emit(void)
{
  RF_START;
  {
    unsigned char c;
    
    c = RF_SP_POP & 0x7F;
    fputc_cons(c);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* show cursor */
/*
    fputc_cons('_');
    fputc_cons(32);
    fputc_cons(8);
    fputc_cons(8);
*/
    /* get key */
/*
    c = fgetc_cons();
*/
    /* eof */
    if (c == -1) {
      exit(0);
    }

    /* LF to CR */
    if (c == 10) {
      c = 13;
    }

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
  fputc_cons(10);
  RF_JUMP_NEXT;
}

void rf_disc_read(char *c, unsigned char len)
{
  for (; len; len--) {
    *(c++) = fgetc_cons();
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
    /* log the disc write data for now */
    fputc_cons(*(p++));
  }
}

void rf_fin(void)
{
}
