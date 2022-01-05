// SYSTEM BINDINGS

#include <bbc.h>

void osbyte(char a, char x);
void oswrch(char a);
char osrdch(void);

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
    unsigned char c;

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

    // get key
    // TODO cursor on and off, off by default
    c = osrdch();

    // return key
    RF_SP_PUSH(c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  // TODO test for escape
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;
}

void rf_code_cr()
{
  RF_START;
  // TODO OSNEWL $FFE7
  oswrch('\r');
  oswrch('\n');
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, unsigned char len)
{
  int i;
  char c;

  /* switch from keyboard to RS423 */
  if (!rs423_read) {
    osbyte(2, 1);
    rs423_read = 1;
  }

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

  for (; len; len--) {
    oswrch(*(p++));
  }

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
  // switch back to screen and keyboard
  osbyte(2, 0);
  osbyte(3, 4);
}