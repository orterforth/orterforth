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

int nlz(uint32_t x)
{
   int n;

   if (x == 0) return(32);
   n = 0;
   if (x <= 0x0000FFFF) {n = n +16; x = x <<16;}
   if (x <= 0x00FFFFFF) {n = n + 8; x = x << 8;}
   if (x <= 0x0FFFFFFF) {n = n + 4; x = x << 4;}
   if (x <= 0x3FFFFFFF) {n = n + 2; x = x << 2;}
   if (x <= 0x7FFFFFFF) {n = n + 1;}
   return n;
}

uint32_t divlu2(uint32_t u1, uint32_t u0, uint32_t v,
                uint32_t *r)
{
   const uint32_t b = 65536; // Number base (16 bits).
   uint32_t un1, un0,        // Norm. dividend LSD's.
            vn1, vn0,        // Norm. divisor digits.
            q1, q0,          // Quotient digits.
            un32, un21, un10,// Dividend digit pairs.
            rhat;            // A remainder.
   int s;                    // Shift amount for norm.

   if (u1 >= v) {            // If overflow, set rem.
      if (r != NULL)         // to an impossible value,
         *r = 0xFFFFFFFF;    // and return the largest
      return 0xFFFFFFFF;}    // possible quotient.

   s = nlz(v);               // 0 <= s <= 31.
   v = v << s;               // Normalize divisor.
   vn1 = v >> 16;            // Break divisor up into
   vn0 = v & 0xFFFF;         // two 16-bit digits.

   un32 = (u1 << s) | (u0 >> 32 - s) & (-s >> 31);
   un10 = u0 << s;           // Shift dividend left.

   un1 = un10 >> 16;         // Break right half of
   un0 = un10 & 0xFFFF;      // dividend into two digits.

   q1 = un32/vn1;            // Compute the first
   rhat = un32 - q1*vn1;     // quotient digit, q1.

again1:
   if (q1 >= b || q1*vn0 > b*rhat + un1) {
     q1 = q1 - 1;
     rhat = rhat + vn1;
     if (rhat < b) goto again1;}

   un21 = un32*b + un1 - q1*v;  // Multiply and subtract.

   q0 = un21/vn1;            // Compute the second
   rhat = un21 - q0*vn1;     // quotient digit, q0.

again2:
   if (q0 >= b || q0*vn0 > b*rhat + un0) {
     q0 = q0 - 1;
     rhat = rhat + vn1;
     if (rhat < b) goto again2;}

   if (r != NULL)            // If remainder is wanted,
      *r = (un21*b + un0 - q0*v) >> s;     // return it.
   return q1*b + q0;
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
    q = divlu2(ah, al, b, &r);
    RF_SP_PUSH(r);
    RF_SP_PUSH(q);
  }
  RF_JUMP_NEXT;
}

static void rf_ustar(uint32_t a, uint32_t b, uint32_t *ch, uint32_t *cl)
{
  /* TODO number of bits, max */
	uint32_t ahi = a >> 16;
	uint32_t alo = a & 0xFFFF;
	uint32_t bhi = b >> 16;
	uint32_t blo = b & 0xFFFF;
	uint32_t lo1 = ((ahi * blo) & 0xFFFF) + ((alo * bhi) & 0xFFFF) + (alo * blo >> 16);
	uint32_t lo2 = (alo * blo) & 0xFFFF;

	*ch = ahi * bhi + (ahi * blo >> 16) + (alo * bhi >> 16) + (lo1 >> 16);
	*cl = (lo1 << 16) + lo2;
}

void rf_code_ustar(void)
{
  RF_START;
  RF_LOG("ustar");
  {
    uintptr_t a, b, ch, cl;

    a = RF_SP_POP;
    b = RF_SP_POP;
    rf_ustar(a, b, &ch, &cl);
    RF_SP_PUSH(cl);
    RF_SP_PUSH(ch);
  }
  RF_JUMP_NEXT;
}

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
