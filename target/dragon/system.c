#include "../../rf.h"

void rf_init(void)
{
  /* Speedkey http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=314 */
  if (*((uint8_t *) 269) + *((uint8_t *) 270) != 250) {
    *((uint8_t *) 65283) &= 254;
    *((uint8_t *) 250) = 116;
    *((uint8_t *) 251) = 1;
    *((uint8_t *) 252) = 81;
    *((uint8_t *) 253) = 126;
    *((uint8_t *) 254) = *((uint8_t *) 269);
    *((uint8_t *) 255) = *((uint8_t *) 270);
    *((uint8_t *) 269) = 0;
    *((uint8_t *) 270) = 250;
    *((uint8_t *) 65283) |= 1;
  }
}

#ifndef RF_TARGET_CODE_EMIT
void rf_code_emit(void)
{
  RF_START;
  {
    char ch = (char) RF_SP_POP & 0x7F;
    asm {
      lda :ch
      jsr $B54A
    }
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_KEY
void rf_code_key(void)
{
  RF_START;
  {
    char ch;
    asm {
      jsr $B538
      sta :ch
    }
    RF_SP_PUSH(ch);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_QTERM
void rf_code_qterm(void)
{
  RF_START;
  {
    char k;
    asm {
      jsr $8006
      sta :k
    }
    RF_SP_PUSH(k == 0x03);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_CR
void rf_code_cr(void)
{
  RF_START;
  asm {
    lda #$0D
    jsr $B54A
  }
  RF_JUMP_NEXT;
}
#endif

void rf_disc_read(char *p, unsigned char len)
{
  while (len--) {
    while (!(*((uint8_t *) 0xFF05) & 0x10)) {
    }
    *(p++) = *((uint8_t *) 0xFF04);
  }
}

void rf_disc_write(char *p, unsigned char len)
{
  *((uint8_t *) 0xFF06) |= 0x01;
  while (len--) {
    while (!(*((uint8_t *) 0xFF05) & 0x08)) {
    }
    *((uint8_t *) 0xFF04) = *(p++);
  }
  *((uint8_t *) 0xFF06) &= 0xFE;
}

void rf_fin(void)
{
}
