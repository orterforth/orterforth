#include <qdos.h>

#include "rf.h"

/* stack can be smaller */
long _stack = 512L;

/* no channel redirection */
long (*_cmdchannels)() = 0;

/* no parameters */
int (*_cmdparams)() = 0;

/* no char translation */
int (*_conread)() = 0;

/* no console setup */
void (*_consetup)() = 0;

int main(int argc, char *argv[]);

/* no C environnment setup */
extern (*_Cstart)() = main;

static chanid_t con;

static chanid_t ser;

void rf_init(void)
{
  short mode = 4;
  short type = 1;
  uint8_t p = 6; /* ACK */

  /* MODE 4, TV */
  mt_dmode(&mode, &type);
  /* open serial */
  mt_baud(4800);
  ser = io_open("SER2", 0);
  /* send ACK to close serial load */
  io_sstrg(ser, TIMEOUT_FOREVER, &p, 1);
  /* 80 columns, 25 rows, white on black */
  con = io_open("CON_480X256A16X0", 0);
  sd_setpa(con, TIMEOUT_FOREVER, 0);
  sd_setin(con, TIMEOUT_FOREVER, 7);
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c = RF_SP_POP & 0x7F;

    /* move cursor for backspace */
    if (c == 8) {
      sd_pcol(con, TIMEOUT_FOREVER);
    } else {
      io_sbyte(con, TIMEOUT_FOREVER, c);
    }

    RF_USER_OUT++;
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
    io_fbyte(con, TIMEOUT_FOREVER, (char *) &k);
    sd_curs(con, TIMEOUT_FOREVER);

    /* LF -> CR */
    if (k == 0x0A) k = 0x0D;
    /* 0xC2 -> DEL */
    if (k == 0xC2) k = 0x7F;
    /* low 7 bits only */
    k &= 0x7f;

    /* return key */
    RF_SP_PUSH(k);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  /* TODO detect break */
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
{
  RF_START;
  io_sbyte(con, TIMEOUT_FOREVER, 10);
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, uint8_t len)
{
  io_fstrg(ser, TIMEOUT_FOREVER, p, len);
}

void rf_disc_write(char *p, uint8_t len)
{
  io_sstrg(ser, TIMEOUT_FOREVER, p, len);
}

void rf_fin(void)
{
  io_close(ser);

  io_close(con);
}
