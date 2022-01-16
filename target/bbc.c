/* SYSTEM BINDINGS */

#include <stdint.h>

#include "../rf.h"

void osbyte(uint8_t a, uint8_t x);

void osnewl(void);

uint8_t osrdch(void);

void oswrch(uint8_t a);

void rf_init(void)
{
 #ifdef RF_TARGET_W
  /* W vector, set JMP ind */
  *(((uint8_t *) &rf_w) - 1) = 0x6c;
#endif

  /* RS423 baud rate */
  osbyte(7, 7);
  osbyte(8, 7);

  /* enable RS423 but start with keyboard/screen */
  osbyte(2, 2);
  osbyte(3, 4);
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

    /* get key */
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
  uint8_t c;

  /* switch from keyboard to RS423 */
  osbyte(2, 1);

  /* read into the buffer */
  for (; len; --len) {
    c = osrdch();
    *(p++) = c;
  }

  /* switch from RS423 to keyboard */
  osbyte(2, 2);
}

void rf_disc_write(char *p, unsigned char len)
{
  /* switch from screen to RS423 */
  osbyte(3, 7);

  /* write from the buffer */
  for (; len; --len) {
    oswrch(*(p++));
  }

  /* switch from RS423 to screen */
  osbyte(3, 4);
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
