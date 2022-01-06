/* SYSTEM BINDINGS */

#include <bbc.h>
#include <stdint.h>

void osbyte(uint8_t a, uint8_t x);

void osnewl(void);

uint8_t osrdch(void);

void oswrch(uint8_t a);

#include "../rf.h"

static uint8_t rs423_write = 0;
static uint8_t rs423_read = 0;

void rf_init(void)
{
  osbyte(7, 7);
  osbyte(8, 7);

  rs423_read = 0;
  rs423_write = 0;
}

void rf_out(char c)
{
  oswrch(c);
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c;

    c = RF_SP_POP & 0x7F;
    oswrch(c);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* switch from RS423 to keyboard */
    if (rs423_read) {
      osbyte(2, 0);
      rs423_read = 0;
    }

    /* get key */
    // TODO cursor on and off, off by default
    c = osrdch();

    /* return key */
    RF_SP_PUSH(c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  /* TODO test for escape */
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;
}

void rf_code_cr()
{
  RF_START;
  osnewl();
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, unsigned char len)
{
  int i;
  uint8_t c;

  /* switch from keyboard to RS423 */
  if (!rs423_read) {
    osbyte(2, 1);
    rs423_read = 1;
  }

  /* read into the buffer */
  for (; len; --len) {
    c = osrdch();
    *(p++) = c;
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  /* switch from screen to RS423 */
  if (!rs423_write) {
    osbyte(3, 7);
    rs423_write = 1;
  }

  /* write from the buffer */
  for (; len; --len) {
    oswrch(*(p++));
  }

  /* switch from RS423 to screen */
  if (rs423_write) {
    osbyte(3, 4);
    rs423_write = 0;
  }
}

void rf_disc_flush(void)
{
}

void rf_fin(void)
{
  /* switch back to screen and keyboard */
  osbyte(2, 0);
  osbyte(3, 4);
}