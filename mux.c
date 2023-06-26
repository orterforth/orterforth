#include <stdio.h>
#ifdef __RC2014
#include <z80.h>
#endif

#include "rf.h"

#ifdef PICO
#define RF_SLEEP(a) sleep_ms(a);
#endif
#ifdef __RC2014
#define RF_SLEEP(a) z80_delay_ms(a);
#endif

void rf_code_emit(void)
{
  RF_START;
  {
    int c = RF_SP_POP & 0x7F;
    
    /* write char, wait if serial disconnected */
    while (putchar(c) == -1) {
      RF_SLEEP(1000);
    }

    /* backspace erase */
    if (c == 0x08) {
      putchar(' ');
      putchar(c);
    }

    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* read char, wait if serial disconnected */
    /* skip disc input */
    do {
      if ((c = getchar()) == -1) {
        RF_SLEEP(1000);
      }
    } while (c == -1 || c & 0x80);

    /* LF to CR */
    if (c == 10) {
      c = 13;
    }

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
  while (putchar(10) == -1) {
    RF_SLEEP(1000);
  }
  RF_JUMP_NEXT;
}

void rf_mux_disc_read(char *p, unsigned char len)
{
  int c;

  for (; len; len--) {
    /* skip keyboard input */
    do {
      if ((c = getchar()) == -1) {
        RF_SLEEP(1000);
      }
    } while (c == -1 || !(c & 0x80));
    *(p++) = c & 0x7F;
  }
}

void rf_mux_disc_write(char *c, unsigned char len)
{
  for (; len; len--) {
    putchar(*(c++) | 0x80);
  }
}
