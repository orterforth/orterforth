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

void __FASTCALL__ rf_console_put(uint8_t b)
{
  /* keep 7 bits, write char, wait if serial disconnected */
  while (putchar(b & 0x7F) == -1) {
    RF_SLEEP(1000);
  }

  /* backspace erase */
  if (b == 0x08) {
    putchar(' ');
    putchar(b);
  }
}

void rf_code_emit(void)
{
  RF_START;
  {
    rf_console_put(*(rf_sp++));

    /* advance OUT */
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

uint8_t rf_console_get(void)
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
  return (c & 0x7F);
}

void rf_code_key(void)
{
  RF_START;
  {
    *(--rf_sp) = rf_console_get();
  }
  RF_JUMP_NEXT;
}

uint8_t rf_console_qterm(void)
{
  return 0;
}

void rf_code_qterm(void)
{
  RF_START;
  *(--rf_sp) = rf_console_qterm();
  RF_JUMP_NEXT;
}

void rf_console_cr(void)
{
  rf_console_put(0x0A);
}

void rf_code_cr(void)
{
  RF_START;
  rf_console_cr();
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

void __FASTCALL__ rf_mux_serial_put(uint8_t b)
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
