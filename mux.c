#include <stdio.h>

#include "rf.h"

/* sleep */

#ifdef PICO
#define RF_SLEEP(a) sleep_ms(a);
#endif
#ifdef __RC2014
#include <z80.h>
#define RF_SLEEP(a) z80_delay_ms(a);
#endif

void rf_code_emit(void)
{
  RF_START;
  {
    /* pop char, keep 7 bits */
    int c = *(rf_sp++) & 0x7F;
    
    /* write char, wait if serial disconnected */
    while (putchar(c) == -1) {
      RF_SLEEP(1000);
    }

    /* backspace erase */
    if (c == 0x08) {
      putchar(' ');
      putchar(c);
    }

    /* advance OUT */
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* read char, skip disc input, wait if serial disconnected */
    while ((c = getchar()) == -1 || c & 0x80) {
      if (c == -1) {
        RF_SLEEP(1000);
      }
    }

    /* LF to CR */
    if (c == 10) {
      c = 13;
    }

    /* push char, keep 7 bits */
    *(--rf_sp) = (c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  *(--rf_sp) = (0);
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

uint8_t rf_mux_serial_get(void)
{
  int c;

  /* read char, skip keyboard input, wait if serial disconnected */
  while ((c = getchar()) == -1 || !(c & 0x80)) {
    if (c == -1) {
      RF_SLEEP(1000);
    }
  }

  return c & 0x7F;
}

void rf_mux_serial_put(uint8_t b)
{
  /* write char, set bit 7, wait if serial disconnected */
  while (putchar(b | 0x80) == -1) {
    RF_SLEEP(1000);
  }
}

void rf_mux_disc_read(char *p, unsigned char len)
{
  for (; len; len--) {
    *(p++) = rf_mux_serial_get();
  }
}

void rf_mux_disc_write(char *p, unsigned char len)
{
  for (; len; len--) {
    rf_mux_serial_put(*(p++));
  }
}
