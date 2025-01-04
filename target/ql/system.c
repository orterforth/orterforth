#include <qdos.h>

#include "rf.h"

/* stack can be smaller */
long _stack = 256L;

/* no channel redirection */
long (*_cmdchannels)() = 0;

/* no parameters */
int (*_cmdparams)() = 0;

/* no char translation */
int (*_conread)() = 0;

/* no console setup */
void (*_consetup)() = 0;

/* used by rf_m68k.s */
char *rf_origin = (char *) RF_ORIGIN;

int main(int argc, char *argv[]);

/* no C environnment setup */
extern (*_Cstart)() = main;

/* console */
static chanid_t con;

/* serial port */
static chanid_t ser;

void rf_init(void)
{
  short mode = 4;
  short type = 1;
/*
  uint8_t p = 6;
*/
  /* MODE 4, TV */
  mt_dmode(&mode, &type);
  /* open serial */
  mt_baud(4800);
  ser = io_open("SER2", 0);
  /* send ACK to close serial load */
/*
  io_sstrg(ser, TIMEOUT_FOREVER, &p, 1);
*/
  /* 85 columns, 25 rows, white on black */
  con = io_open("CON_512X256A0X0", 0);
  sd_setpa(con, TIMEOUT_FOREVER, 0);
  sd_setin(con, TIMEOUT_FOREVER, 7);
  sd_clear(con, TIMEOUT_FOREVER);
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c = (*(rf_sp++)) & 0x7F;

    /* move cursor for backspace */
    switch (c) {
    case 8:
      sd_pcol(con, TIMEOUT_FOREVER);
      io_sbyte(con, TIMEOUT_FOREVER, ' ');
      sd_pcol(con, TIMEOUT_FOREVER);
      break;
    case 12:
      sd_clear(con, TIMEOUT_FOREVER);
      break;
    default:
      io_sbyte(con, TIMEOUT_FOREVER, c);
      break;
    }

    rf_up[13]++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    uint8_t k;

    /* get key */
    sd_cure(con, TIMEOUT_FOREVER);
    while (io_fbyte(con, TIMEOUT_FOREVER, (char *) &k)) {}
    sd_curs(con, TIMEOUT_FOREVER);

    /* LF -> CR */
    if (k == 0x0A) k = 0x0D;
    /* 0xC2 -> DEL */
    if (k == 0xC2) k = 0x7F;
    /* low 7 bits only */
    k &= 0x7F;

    /* return key */
    *(--rf_sp) = ((uintptr_t) k);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  *(--rf_sp) = (keyrow(1) == 8);
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
{
  RF_START;
  io_sbyte(con, TIMEOUT_FOREVER, 10);
  RF_JUMP_NEXT;
}

void rf_code_dchar(void)
{
  RF_START;
  {
    char a, c;

    a = (char) (*(rf_sp++));
    io_fstrg(ser, TIMEOUT_FOREVER, &c, 1);
    *(--rf_sp) = (c == a);
    *(--rf_sp) = (c);
  }
  RF_JUMP_NEXT;
}

void rf_code_bread(void)
{
  RF_START;
  io_fstrg(ser, TIMEOUT_FOREVER, (char *) (*(rf_sp++)), RF_BBLK);
  RF_JUMP_NEXT;
}

static char eot = 0x04;

void rf_code_bwrit(void)
{
  RF_START;
  {
    uint8_t a = (uint8_t) (*(rf_sp++));
    char *b = (char *) (*(rf_sp++));

    io_sstrg(ser, TIMEOUT_FOREVER, b, a);
    io_sstrg(ser, TIMEOUT_FOREVER, &eot, 1);
  }
  RF_JUMP_NEXT;
}

void rf_fin(void)
{
  io_close(ser);

  io_close(con);
}
