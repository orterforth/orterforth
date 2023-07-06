/* SYSTEM BINDINGS */

#include "mux.h"
#include "rf.h"

void rf_init(void)
{
}

void rf_disc_read(char *c, unsigned char len)
{
  rf_mux_disc_read(c, len);
}

void rf_disc_write(char *c, unsigned char len)
{
  rf_mux_disc_write(c, len);
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
}
