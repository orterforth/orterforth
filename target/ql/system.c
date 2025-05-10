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
#define CON 0x00010001 /* channel #1 */

static QLRECT_t rect = {
  512, 256, 0, 0
};

/* serial port */
static chanid_t ser;

void rf_init(void)
{
  short mode = 4;
  short type = 1;
  /*uint8_t p = 6;*/

  /* MODE 4, TV */
  mt_dmode(&mode, &type);
  /* channel #1, 85 columns, 25 rows, white on black */
  sd_wdef(CON, TIMEOUT_FOREVER, 0, 0, &rect);
  sd_setpa(CON, TIMEOUT_FOREVER, 0);
  sd_setst(CON, TIMEOUT_FOREVER, 0);
  sd_setin(CON, TIMEOUT_FOREVER, 7);
  sd_clear(CON, TIMEOUT_FOREVER);

  /* open serial */
  mt_baud(4800);
  ser = io_open("SER2", 0);
  /* send ACK to close serial load */
  /*io_sstrg(ser, TIMEOUT_FOREVER, &p, 1);*/
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c = (*(rf_sp++)) & 0x7F;

    switch (c) {
    case 8:
      /* BS erase character */
      sd_pcol(CON, TIMEOUT_FOREVER);
      io_sbyte(CON, TIMEOUT_FOREVER, ' ');
      sd_pcol(CON, TIMEOUT_FOREVER);
      break;
    default:
      io_sbyte(CON, TIMEOUT_FOREVER, c);
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
    sd_cure(CON, TIMEOUT_FOREVER);
    while (io_fbyte(CON, TIMEOUT_FOREVER, (char *) &k)) {}
    sd_curs(CON, TIMEOUT_FOREVER);

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
  io_sbyte(CON, TIMEOUT_FOREVER, 10);
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
}
