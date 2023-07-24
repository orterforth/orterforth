/* SYSTEM BINDINGS */


#include <cbm.h>
#include <serial.h>
#include <stdint.h>

#include "../../rf.h"

static const struct ser_params serial_params = {
    SER_BAUD_2400,
    SER_BITS_8,
    SER_STOP_1,
    SER_PAR_NONE,
    SER_HS_NONE
};

extern char c64_serial;
  
void rf_init(void)
{
  /* init serial */
  if (ser_install(&c64_serial)) {
  }
  if (ser_open(&serial_params)) {
  }
  if (ser_ioctl(1, NULL)) {
  }
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c;
    
    c = RF_SP_POP & 0x7F;

    /* PETSCII swap case */
    if (((c & 0xDF) >= 'A' && (c & 0xDF) <= 'Z')) {
      c ^= 0x20;
    }
    /* BS */
    else if (c == 0x08) {
      c = 0x14;
    }

    cbm_k_bsout(c);

    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    /* show cursor */
    *((uint8_t *) 204) = 0;
    *((uint8_t *) 647) = 1;
    *((uint8_t *) 207) = 0;

    /* wait for key */
    while (!(c = cbm_k_getin())) {
    }

    /* hide cursor */
    *((uint8_t *) 647) = 14;
    *((uint8_t *) 206) = 32;
    *((uint8_t *) 204) = 255;
    *((uint8_t *) 207) = 0;

    /* PETSCII correct case */
    if (c >= 'A' && c <= 'Z') {
      c ^= 0x20;
    }

    /* return key */
    RF_SP_PUSH(c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  RF_SP_PUSH(*((uint8_t *) 0x00CB) == 0x3F);
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
{
  RF_START;
  cbm_k_bsout('\r');
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, uint8_t len)
{
  int t;

  ++len;
  while (--len) {
    while ((t = ser_get(p)) != SER_ERR_OK) {
    }
    p++;
  }
}

void rf_disc_write(char *p, uint8_t len)
{
  ++len;
  while (--len) {
    while (ser_put(*p) == SER_ERR_OVERFLOW) {
    }
    p++;
  }
}

void rf_fin(void)
{
  ser_close();
  ser_uninstall();
}
