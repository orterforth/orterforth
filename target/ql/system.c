#include <qdos.h>

#include "rf.h"

#define RF_LOG(name)

/* stack can be smaller */
long _stack = 512L;

/* no channel redirection */
long (*_cmdchannels)() = 0;

/* no parameters */
int (*_cmdparams)() = 0;

/* no char translation */
int (*_conread)() = 0;

/* no console setup */
void (*_consetup)() = 0;

int main(int argc, char *argv[]);

/* no C environnment setup */
extern (*_Cstart)() = main;

/* 64 BIT ARITHMETIC */

typedef uintptr_t uint32_t;

#ifndef RF_TARGET_CODE_USLAS

#define TOPBIT 0x80000000
uint32_t div64(uint32_t uh, uint32_t ul, uint32_t v, uint32_t *r)
{
	int i;

  /* overflow or divide by zero */
  /* TODO is this TOPBIT check correct */
	if (v >= TOPBIT || uh >= v) {
    *r = 0xFFFFFFFF;
    return 0xFFFFFFFF;
  }

	for (i = 0; i < 32; i++) {
    /* Start to shift numerator left (top bit is lost) */
    uh <<= 1;
    /* Add the carry to high word */
    if (ul & TOPBIT) {
      uh++;
    }
    /* End of shift */
    ul <<= 1;

    /* Jump if can't subtract */
    if (uh >= v) {
      /* Subtract v and add the flag to result (in low word) */
      uh -= v;
      ul++;
    }
  }

  /* result */
  *r = uh;
  return ul;
}

void rf_code_uslas(void)
{
  RF_START;
  RF_LOG("uslas");
  {
    uintptr_t ah, al, b, q, r;

    b = RF_SP_POP;
    ah = RF_SP_POP;
    al = RF_SP_POP;
    q = div64(ah, al, b, &r);
    RF_SP_PUSH(r);
    RF_SP_PUSH(q);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_USTAR
static void mul64(uint32_t a, uint32_t b, uint32_t *ch, uint32_t *cl)
{
  uint32_t ah = a >> 16;
  uint32_t al = a & 0xFFFFU;
  uint32_t bh = b >> 16;
  uint32_t bl = b & 0xFFFFU;
  uint32_t rl = al * bl;
  uint32_t rm1 = ah * bl;
  uint32_t rm2 = al * bh;
  uint32_t rh = ah * bh;
  uint32_t rml = (rm1 & 0xFFFFU) + (rm2 & 0xFFFFU);
  uint32_t rmh = (rm1 >> 16) + (rm2 >> 16);

  rl += rml << 16;
  if (rml & 0xFFFF0000U) {
    rmh++;
  }
  rh += rmh;

  *cl = rl;
  *ch = rh;
}

void rf_code_ustar(void)
{
  RF_START;
  RF_LOG("ustar");
  {
    uintptr_t a, b, ch, cl;

    a = RF_SP_POP;
    b = RF_SP_POP;
    mul64(a, b, &ch, &cl);
    RF_SP_PUSH(cl);
    RF_SP_PUSH(ch);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DPLUS
static void rf_dplus(uintptr_t ah, uintptr_t al, uintptr_t bh, uintptr_t bl, uintptr_t *ch, uintptr_t *cl)
{
	*cl = al + bl;
	*ch = ah + bh;
	if (*cl < al)
		(*ch)++;
}

void rf_code_dplus(void)
{
  RF_START;
  RF_LOG("dplus");
  {
    uintptr_t ah, al, bh, bl, ch, cl;

    ah = RF_SP_POP;
    al = RF_SP_POP;
    bh = RF_SP_POP;
    bl = RF_SP_POP;
    rf_dplus(ah, al, bh, bl, &ch, &cl);
    RF_SP_PUSH(cl);
    RF_SP_PUSH(ch);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DMINU
static void rf_dminu(uintptr_t bh, uintptr_t bl, uintptr_t *ch, uintptr_t *cl)
{
	*cl = -bl;
	*ch = -bh;
	if (bl)
		(*ch)--;
}

void rf_code_dminu(void)
{
  RF_START;
  RF_LOG("dminu");
  {
    uintptr_t bh, bl, ch, cl;
    
    bh = RF_SP_POP;
    bl = RF_SP_POP;
    rf_dminu(bh, bl, &ch, &cl);
    RF_SP_PUSH(cl);
    RF_SP_PUSH(ch);
  }
  RF_JUMP_NEXT;
}
#endif

void rf_code_rtgt(void)
{
  RF_START;
  RF_SP_PUSH(RF_TARGET);
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;  
}

static chanid_t con;

static chanid_t ser;

void rf_init(void)
{
  short mode = 4;
  short type = 1;
  uint8_t p = 6; /* ACK */

  /* MODE 4, TV */
  mt_dmode(&mode, &type);
  /* open serial */
  mt_baud(4800);
  ser = io_open("SER2", 0);
  /* send ACK to close serial load */
  io_sstrg(ser, TIMEOUT_FOREVER, &p, 1);
  /* 80 columns, 25 rows, white on black */
  con = io_open("CON_480X256A16X0", 0);
  sd_setpa(con, TIMEOUT_FOREVER, 0);
  sd_setin(con, TIMEOUT_FOREVER, 7);
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c = RF_SP_POP & 0x7F;

    /* move cursor for backspace */
    if (c == 8) {
      sd_pcol(con, TIMEOUT_FOREVER);
    } else {
      io_sbyte(con, TIMEOUT_FOREVER, c);
    }

    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    uint8_t k;

    /* get key */
    sd_cure(con, TIMEOUT_FOREVER);
    io_fbyte(con, TIMEOUT_FOREVER, (char *) &k);
    sd_curs(con, TIMEOUT_FOREVER);

    /* LF -> CR */
    if (k == 0x0A) k = 0x0D;
    /* 0xC2 -> DEL */
    if (k == 0xC2) k = 0x7F;
    /* low 7 bits only */
    k &= 0x7f;

    /* return key */
    RF_SP_PUSH(k);
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
  io_sbyte(con, TIMEOUT_FOREVER, 10);
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, uint8_t len)
{
  io_fstrg(ser, TIMEOUT_FOREVER, p, len);
}

void rf_disc_write(char *p, uint8_t len)
{
  io_sstrg(ser, TIMEOUT_FOREVER, p, len);
}

void rf_fin(void)
{
  io_close(ser);

  io_close(con);
}
