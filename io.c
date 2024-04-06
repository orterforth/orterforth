#include "rf.h"

/* system specific */

void rf_init(void);

uint8_t rf_console_get(void);

void __FASTCALL__ rf_console_put(uint8_t b);

void rf_console_cr(void);

uint8_t rf_console_qterm(void);

uint8_t rf_serial_get(void);

void __FASTCALL__ rf_serial_put(uint8_t b);

void rf_fin(void);

void rf_code_emit(void)
{
  RF_START;
  {
    rf_console_put((uint8_t) RF_SP_POP & 0x7F);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    RF_SP_PUSH(rf_console_get() & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  RF_SP_PUSH(rf_console_qterm());
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
{
  RF_START;
  rf_console_cr();
  RF_JUMP_NEXT;
}

void rf_code_dchar(void)
{
  RF_START;
  {
    uint8_t a, c;

    a = (uint8_t) RF_SP_POP;
    c = rf_serial_get();
    RF_SP_PUSH(c == a);
    RF_SP_PUSH(c);
  }
  RF_JUMP_NEXT;
}

void rf_code_bread(void)
{
  RF_START;
  {
    uint8_t len = RF_BBLK;
    uint8_t *p = (uint8_t *) RF_SP_POP;

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
    uint8_t len = (uint8_t) RF_SP_POP;
    uint8_t *b = (uint8_t *) RF_SP_POP;

    /* write from buffer */
    for (; len; --len) {
      rf_serial_put(*(b++));
    }
    /* write EOT */
    rf_serial_put(0x04);
  }
  RF_JUMP_NEXT;
}
