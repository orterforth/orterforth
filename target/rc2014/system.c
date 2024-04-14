/* SYSTEM BINDINGS */

#include "mux.h"
#include "rf.h"

void rf_init(void)
{
}

uint8_t rf_serial_get(void)
{
  return rf_mux_serial_get();
}

void rf_serial_put(uint8_t b)
{
  rf_mux_serial_put(b);
}

void rf_code_dchar(void)
{
  RF_START;
  {
    char a, c;

    a = (char) (*(rf_sp++));
    c = rf_serial_get();
    *(--rf_sp) = (c == a);
    *(--rf_sp) = (c);
  }
  RF_JUMP_NEXT;
}

void rf_code_bread(void)
{
  RF_START;
  {
    uint8_t len = RF_BBLK;
    uint8_t *p = (uint8_t *) (*(rf_sp++));

    /* read into the buffer, break on EOT */
    for (; len; --len) {
      if ((*(p++) = rf_serial_get()) == 0x04) {
        break;
      }
    }
  }
  RF_JUMP_NEXT;
}

void rf_code_bwrit(void)
{
  RF_START;
  {
    uint8_t len = (uint8_t) (*(rf_sp++));
    uint8_t *b = (uint8_t *) (*(rf_sp++));

    /* write from buffer */
    for (; len; --len) {
      rf_serial_put(*(b++));
    }
    /* write EOT */
    rf_serial_put(0x04);
  }
  RF_JUMP_NEXT;
}

void rf_fin(void)
{
}
