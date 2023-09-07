/* ORTERFORTH */

#include "rf.h"

/* FORTH MACHINE */

/* SP */
#ifndef RF_TARGET_SP
uintptr_t *rf_sp = 0;
#endif

#ifndef RF_INLINE_SP
uintptr_t rf_sp_pop(void)
{
  return *(rf_sp++);
}

void __FASTCALL__ rf_sp_push(uintptr_t a)
{
  *(--rf_sp) = a;
}
#endif

/* RP */
#ifndef RF_TARGET_RP
uintptr_t *rf_rp = 0;
#endif

#ifndef RF_INLINE_RP
uintptr_t rf_rp_pop(void)
{
  return *(rf_rp++);
}

void __FASTCALL__ rf_rp_push(uintptr_t a)
{
  *(--rf_rp) = a;
}
#endif

/* IP */
#ifndef RF_TARGET_IP
uintptr_t *rf_ip = 0;
#endif

/* W */
#ifndef RF_TARGET_W
rf_code_t *rf_w = 0;
#endif

/* UP */
#ifndef RF_TARGET_UP
uintptr_t *rf_up = 0;
#endif

/* TRAMPOLINE */

/* trampoline function pointer */
#ifndef RF_TARGET_FP
rf_code_t rf_fp = 0;
#endif

#ifndef RF_TARGET_TRAMPOLINE
/* A loop that repeatedly executes function pointers. */
void rf_trampoline(void)
{
  while (rf_fp) {
    /* Default implementation does nothing here; assembly
    implementations can switch machine state into registers
    (and, if the processor return stack is used by the Forth
    machine, ensure the return address is on the C stack not
    the Forth stack). */
    rf_fp();
  }
}

/* Called at start of each C-based code word. */
void rf_start(void)
{
  /* Default implementation does nothing here; assembly
  implementations can switch machine state out of registers
  (and, if the processor return stack is used by the Forth
  machine, move the stack frame). */
}
#endif

/* CODE */

#ifndef RF_TARGET_CODE_LIT
void rf_code_lit(void)
{
  RF_START;
  RF_LOG("lit");
  {
    uintptr_t a = *(RF_IP_GET);
    RF_SP_PUSH(a);
    RF_IP_INC;
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_NEXT
void rf_next(void)
{
  RF_START;
  rf_w = (rf_code_t *) *(RF_IP_GET);
#ifdef RF_TRACE
  {
    char *i = (char *) rf_w - RF_WORD_SIZE;
    int rr = (RF_R0) - (char *) rf_rp;

    while (rr--) {
      putchar(32);
    }

    putchar(*(--i) & 0x7F);
    while (!(*(--i) & 0x80)) {
      /*putchar(*i)*/;
    }
    while (!(*(++i) & 0x80)) {
      putchar(*i);
    }
    putchar(10);
  }
#endif

  RF_IP_INC;
  RF_JUMP(*rf_w);
}
#endif

#ifndef RF_TARGET_CODE_EXEC
void rf_code_exec(void)
{
  RF_START;
  RF_LOG("exec");
  rf_w = (rf_code_t *) RF_SP_POP;
  RF_JUMP(*rf_w);
}
#endif

#ifndef RF_TARGET_CODE_BRAN
#ifndef RF_BRANCH
#define RF_BRANCH
static void rf_branch(void);
#endif
void rf_code_bran(void)
{
  RF_START;
  RF_LOG("bran");
  rf_branch();
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_ZBRAN
#ifndef RF_BRANCH
#define RF_BRANCH
static void rf_branch(void);
#endif
void rf_code_zbran(void)
{
  RF_START;
  RF_LOG("zbran");
  if (RF_SP_POP) {
    RF_IP_INC;
  } else {
    rf_branch();
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_XLOOP
#ifndef RF_BRANCH
#define RF_BRANCH
static void rf_branch(void);
#endif
void rf_code_xloop(void)
{
  RF_START;
  RF_LOG("xloop");
  {
    intptr_t index = (intptr_t) RF_RP_POP;
    intptr_t limit = (intptr_t) RF_RP_POP;
    ++index;
    if (limit > index) {
      RF_RP_PUSH(limit);
      RF_RP_PUSH(index);
      rf_branch();
    } else {
      RF_IP_INC;
    }
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_XPLOO
#ifndef RF_BRANCH
#define RF_BRANCH
static void rf_branch(void);
#endif
void rf_code_xploo(void)
{
  RF_START;
  RF_LOG("xploo");
  {
    intptr_t n = (intptr_t) RF_SP_POP;
    intptr_t index = RF_RP_POP;
    intptr_t limit = RF_RP_POP;

    index += n;
    if (((index - limit) ^ n) < 0) {
      RF_RP_PUSH(limit);
      RF_RP_PUSH(index);
      rf_branch();
    } else {
      RF_IP_INC;
    }
  }
  RF_JUMP_NEXT;
}
#endif

#ifdef RF_BRANCH
static void rf_branch(void)
{
  uintptr_t offset = (uintptr_t) *(RF_IP_GET);
  RF_IP_SET((uintptr_t *) (((char *) RF_IP_GET) + offset));
}
#endif

#ifndef RF_TARGET_CODE_XDO
void rf_code_xdo(void)
{
  RF_START;
  RF_LOG("xdo");
  {
    uintptr_t n2 = RF_SP_POP;
    uintptr_t n1 = RF_SP_POP;
    RF_RP_PUSH(n1);
    RF_RP_PUSH(n2);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DODOE
void rf_code_dodoe(void)
{
  RF_START;
  RF_LOG("dodoe");
  {
    uintptr_t *p1;
    uintptr_t *p2;

    /* execute the words after DOES> (addr in the PFA): */

    /* push IP onto RP */
    RF_RP_PUSH((uintptr_t) RF_IP_GET);

    /* fetch first param *(W + 1) as new IP */
    p1 = (uintptr_t *) rf_w + 1;
    RF_IP_SET((uintptr_t *) (*p1));

    /* push second param addr (W + 2) onto SP */
    p2 = (uintptr_t *) rf_w + 2;
    RF_SP_PUSH((uintptr_t) p2);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_RR
void rf_code_rr(void)
{
  RF_START;
  RF_LOG("rr");
  {
    uintptr_t i = (uintptr_t) *(RF_RP_GET);
    RF_SP_PUSH(i);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DIGIT
static uint8_t rf_digit(uint8_t base, uint8_t c)
{
  if (c >= 0x30) {
    c -= 0x30;
    if (c > 9) {
      if (c < 17) {
        return 0xFF;
      }
      c -= 7;
    }
    if (c < base) {
      return c;
    }
  }
  return 0xFF;
}

void rf_code_digit(void)
{
  RF_START;
  RF_LOG("digit");
  {
    uint8_t b, c, d;

    b = (uint8_t) RF_SP_POP;
    c = (uint8_t) RF_SP_POP;
    d = rf_digit(b, c);
    if (d == 0xFF) {
      RF_SP_PUSH(0);
    } else {
      RF_SP_PUSH(d);
      RF_SP_PUSH(1);
    }
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_PFIND
static uint8_t __FASTCALL__ **rf_lfa(uint8_t *nfa)
{
  while (!(*(++nfa) & 0x80)) {
  }
  return (uint8_t **) ++nfa;
}

static uint8_t *rf_find(uint8_t *t, uint8_t length, uint8_t *nfa)
{
  uint8_t i;
  uint8_t *n;

  while (nfa) {
    /* match length from name field incl smudge bit */
    if (length == (*nfa & 0x3F)) {
      /* match name */
      n = nfa;
      for (i = 0; i < length; i++) {
        if (t[i] != (*(++n) & 0x7F)) {
          break;
        }
      }
      if (i == length) {
        return nfa;
      }
    }

    /* if no match, follow link */
    nfa = *(rf_lfa(nfa));
  }

  /* not found */
  return 0;
}

static uintptr_t __FASTCALL__ *rf_pfa(uint8_t *nfa)
{
  uint8_t **lfa = rf_lfa(nfa);
  uintptr_t *pfa = (uintptr_t *) lfa + 2;
  return pfa;
}

static uintptr_t rf_pfind(uint8_t *addr1, uint8_t *addr2)
{
  uint8_t length;
  uint8_t *f;

  length = *addr1;
  f = rf_find(addr1 + 1, length, addr2);
  if (f) {
    RF_SP_PUSH((uintptr_t) rf_pfa(f));
    RF_SP_PUSH(*((uint8_t *) f));
    return 1;
  } else {
    return 0;
  }
}

void rf_code_pfind(void)
{
  RF_START;
  RF_LOG("pfind");
  {
    uint8_t *addr2;
    uint8_t *addr1;
    uintptr_t f;

    addr2 = (uint8_t *) RF_SP_POP; /* nfa */
    addr1 = (uint8_t *) RF_SP_POP; /* text to find */
    f = rf_pfind(addr1, addr2);
    RF_SP_PUSH(f);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_ENCL
static void rf_enclose(char c, char *addr1, uint8_t *s3, uint8_t *s2, uint8_t *s1)
{
  char *hl = addr1;
  uint8_t e = 0xFF;

  /* skip leading delimiters */
  hl--;
  do {
    ++hl;
	  ++e;
	} while (*hl == c);
	*s3 = e;

  /* return if null */
	if (!*hl) {
	  *s1 = e;
	  ++e;
	  *s2 = e;
	  return;
  }

  /* traverse word */
  do {
	  ++hl;
	  ++e;
    /* return if delim */
	  if (*hl == c) {
      *s2 = e;
      ++e;
      *s1 = e;
      return;
    }
	} while (*hl);

  /* return if null */
	*s2 = e;
	*s1 = e;
}

static void rf_encl(void)
{
  char c;
  char *addr1;
  uint8_t n1, n2, n3;

  c = (char) RF_SP_POP;
  addr1 = (char *) RF_SP_POP;
  rf_enclose(c, addr1, &n1, &n2, &n3);
  RF_SP_PUSH((uintptr_t) addr1);
  RF_SP_PUSH(n1);
  RF_SP_PUSH(n2);
  RF_SP_PUSH(n3);
}

void rf_code_encl(void)
{
  RF_START;
  RF_LOG("encl");
  rf_encl();
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_CMOVE
void rf_code_cmove(void)
{
  RF_START;
  RF_LOG("cmove");
  {
    uintptr_t count = RF_SP_POP;
    char *to = (char *) RF_SP_POP;
    char *from = (char *) RF_SP_POP;

    for (; count; count--) {
      *(to++) = *(from++);
    }
  }
  RF_JUMP_NEXT;
}
#endif

/* define double handling functions where required */
#ifdef RF_DOUBLE_ARITH
#ifndef RF_TARGET_CODE_USTAR
#define RF_UNDOUBLE
#endif
#ifndef RF_TARGET_CODE_USLAS
#define RF_DOUBLE
#endif
#ifndef RF_TARGET_CODE_DPLUS
#define RF_DOUBLE
#define RF_UNDOUBLE
#endif
#ifndef RF_TARGET_CODE_DMINU
#define RF_DOUBLE
#define RF_UNDOUBLE
#endif
#endif

#ifdef RF_DOUBLE
static void rf_double(uintptr_t h, uintptr_t l, rf_double_t *d)
{
  rf_double_t a = (rf_double_t) h << RF_WORD_SIZE_BITS;
  rf_double_t b = (rf_double_t) l;
  *d = a | b;
}
#endif

#ifdef RF_UNDOUBLE
static void rf_undouble(rf_double_t d, uintptr_t *h, uintptr_t *l)
{
  *h = d >> RF_WORD_SIZE_BITS;
  *l = d;
}
#endif

#ifndef RF_TARGET_CODE_USTAR

#ifdef RF_DOUBLE_ARITH
static void rf_ustar(uintptr_t a, uintptr_t b, uintptr_t *ch, uintptr_t *cl)
{
  rf_double_t d;

  d = (rf_double_t) a * b;
  rf_undouble(d, ch, cl);
}
#else
#if (RF_WORD_SIZE==2)
#define RF_WORD_SIZE_BITS_HALF 8
#define RF_WORD_MASK_LO 0x00FFU
#define RF_WORD_MASK_HI 0xFF00U
#endif
#if (RF_WORD_SIZE==4)
#define RF_WORD_SIZE_BITS_HALF 16
#define RF_WORD_MASK_LO 0x0000FFFFU
#define RF_WORD_MASK_HI 0xFFFF0000U
#endif
#if (RF_WORD_SIZE==8)
#define RF_WORD_SIZE_BITS_HALF 32
#define RF_WORD_MASK_LO 0x00000000FFFFFFFFU
#define RF_WORD_MASK_HI 0xFFFFFFFF00000000U
#endif
static void rf_ustar(uintptr_t a, uintptr_t b, uintptr_t *ch, uintptr_t *cl)
{
  uintptr_t ah = a >> RF_WORD_SIZE_BITS_HALF;
  uintptr_t al = a & RF_WORD_MASK_LO;
  uintptr_t bh = b >> RF_WORD_SIZE_BITS_HALF;
  uintptr_t bl = b & RF_WORD_MASK_LO;
  uintptr_t rl = al * bl;
  uintptr_t rm1 = ah * bl;
  uintptr_t rm2 = al * bh;
  uintptr_t rh = ah * bh;
  uintptr_t rml = (rm1 & RF_WORD_MASK_LO) + (rm2 & RF_WORD_MASK_LO);
  uintptr_t rmh = (rm1 >> RF_WORD_SIZE_BITS_HALF) + (rm2 >> RF_WORD_SIZE_BITS_HALF);

  rl += rml << RF_WORD_SIZE_BITS_HALF;
  if (rml & RF_WORD_MASK_HI) {
    rmh++;
  }
  rh += rmh;

  *cl = rl;
  *ch = rh;
}
#endif

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
#endif

#ifndef RF_TARGET_CODE_USLAS

#ifdef RF_DOUBLE_ARITH
static uintptr_t rf_uslas(uintptr_t uh, uintptr_t ul, uintptr_t v, uintptr_t *r)
{
  rf_double_t a, b;

  /* overflow or divide by zero */
  if (uh >= v) {
    *r = (uintptr_t) -1;
    return (uintptr_t) -1;
  }

  rf_double(uh, ul, &a);
  rf_double(0, v, &b);
  *r = (uintptr_t) (a % b);
  return (uintptr_t) (a / b);
}
#else
#if (RF_WORD_SIZE==2)
#define RF_TOPBIT 0x8000
#endif
#if (RF_WORD_SIZE==4)
#define RF_TOPBIT 0x80000000
#endif
#if (RF_WORD_SIZE==8)
#define RF_TOPBIT 0x8000000000000000
#endif
static uintptr_t rf_uslas(uintptr_t uh, uintptr_t ul, uintptr_t v, uintptr_t *r)
{
	int i;

  /* overflow or divide by zero */
	if (v >= RF_TOPBIT || uh >= v) {
    *r = (uintptr_t) -1;
    return (uintptr_t) -1;
  }

	for (i = 0; i < RF_WORD_SIZE_BITS; i++) {
    /* Start to shift numerator left (top bit is lost) */
    uh <<= 1;
    /* Add the carry to high word */
    if (ul & RF_TOPBIT) {
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
#endif

void rf_code_uslas(void)
{
  RF_START;
  RF_LOG("uslas");
  {
    uintptr_t ah, al, b, q, r;

    b = RF_SP_POP;
    ah = RF_SP_POP;
    al = RF_SP_POP;
    q = rf_uslas(ah, al, b, &r);
    RF_SP_PUSH(r);
    RF_SP_PUSH(q);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_ANDD
void rf_code_andd(void)
{
  RF_START;
  RF_LOG("andd");
  {
    uintptr_t a;
    uintptr_t b;

    a = RF_SP_POP;
    b = RF_SP_POP;
    RF_SP_PUSH(a & b);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_ORR
void rf_code_orr(void)
{
  RF_START;
  RF_LOG("orr");
  {
    uintptr_t a;
    uintptr_t b;

    a = RF_SP_POP;
    b = RF_SP_POP;
    RF_SP_PUSH(a | b);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_XORR
void rf_code_xorr(void)
{
  RF_START;
  RF_LOG("xorr");
  {
    uintptr_t a;
    uintptr_t b;

    a = RF_SP_POP;
    b = RF_SP_POP;
    RF_SP_PUSH(a ^ b);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_SPAT
void rf_code_spat(void)
{
  RF_START;
  RF_LOG("spat");
  {
    uintptr_t sp;

    sp = (uintptr_t) RF_SP_GET;
    RF_SP_PUSH(sp);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_SPSTO
void rf_code_spsto(void)
{
  RF_START;
  RF_LOG("spsto");
  RF_SP_SET((uintptr_t *) RF_USER_S0);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_RPSTO
void rf_code_rpsto(void)
{
  RF_START;
  RF_LOG("rpsto");
  RF_RP_SET((uintptr_t *) RF_USER_R0);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_SEMIS
void rf_code_semis(void)
{
  RF_START;
  RF_LOG("semis");
  RF_IP_SET((uintptr_t *) RF_RP_POP);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_LEAVE
void rf_code_leave(void)
{
  RF_START;
  RF_LOG("leave");
  {
    uintptr_t index;

    index = (uintptr_t) RF_RP_POP;
    (void) RF_RP_POP;
    RF_RP_PUSH(index);
    RF_RP_PUSH(index);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_TOR
void rf_code_tor(void)
{
  RF_START;
  RF_LOG("tor");
  RF_RP_PUSH(RF_SP_POP);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_FROMR
void rf_code_fromr(void)
{
  RF_START;
  RF_LOG("fromr");
  RF_SP_PUSH((uintptr_t) RF_RP_POP);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_ZEQU
void rf_code_zequ(void)
{
  RF_START;
  RF_LOG("zequ");
  {
    uintptr_t a;

    a = (RF_SP_POP == 0);
    RF_SP_PUSH(a);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_ZLESS
void rf_code_zless(void)
{
  RF_START;
  RF_LOG("zless");
  {
    uintptr_t a;
    
    a = (((intptr_t) RF_SP_POP) < 0);
    RF_SP_PUSH(a);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_PLUS
void rf_code_plus(void)
{
  RF_START;
  RF_LOG("plus");
  {
    intptr_t a;
    intptr_t b;

    a = RF_SP_POP;
    b = RF_SP_POP;
    RF_SP_PUSH(a + b);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DPLUS

#ifdef RF_DOUBLE_ARITH
static void rf_dplus(uintptr_t ah, uintptr_t al, uintptr_t bh, uintptr_t bl, uintptr_t *ch, uintptr_t *cl)
{
  rf_double_t a;
  rf_double_t b;
  rf_double_t c;

  rf_double(ah, al, &a);
  rf_double(bh, bl, &b);
  c = a + b;
  rf_undouble(c, ch, cl);
}
#else
static void rf_dplus(uintptr_t ah, uintptr_t al, uintptr_t bh, uintptr_t bl, uintptr_t *ch, uintptr_t *cl)
{
	*cl = al + bl;
	*ch = ah + bh;
	if (*cl < al)
		(*ch)++;
}
#endif

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

#ifndef RF_TARGET_CODE_MINUS
void rf_code_minus(void)
{
  RF_START;
  RF_LOG("minus");
  {
    uintptr_t a;

    a = (~RF_SP_POP) + 1;
    RF_SP_PUSH(a);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DMINU

#ifdef RF_DOUBLE_ARITH
static void rf_dminu(uintptr_t bh, uintptr_t bl, uintptr_t *ch, uintptr_t *cl)
{
  rf_double_t d;

  rf_double(bh, bl, &d);
  d = -d;
  rf_undouble(d, ch, cl);
}
#else
static void rf_dminu(uintptr_t bh, uintptr_t bl, uintptr_t *ch, uintptr_t *cl)
{
	*cl = -bl;
	*ch = -bh;
	if (bl)
		(*ch)--;
}
#endif

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

#ifndef RF_TARGET_CODE_OVER
void rf_code_over(void)
{
  RF_START;
  RF_LOG("over");
  {
    uintptr_t a;
    uintptr_t b;

    a = RF_SP_POP;
    b = RF_SP_POP;
    RF_SP_PUSH(b);
    RF_SP_PUSH(a);
    RF_SP_PUSH(b);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DROP
void rf_code_drop(void)
{
  RF_START;
  RF_LOG("drop");
  (void) RF_SP_POP;
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_SWAP
void rf_code_swap(void)
{
  RF_START;
  RF_LOG("swap");
  {
    uintptr_t a;
    uintptr_t b;

    a = RF_SP_POP;
    b = RF_SP_POP;
    RF_SP_PUSH(a);
    RF_SP_PUSH(b);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DUP
void rf_code_dup(void)
{
  RF_START;
  RF_LOG("dup");
  {
    uintptr_t a;

    a = RF_SP_POP;
    RF_SP_PUSH(a);
    RF_SP_PUSH(a);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_PSTOR
void rf_code_pstor(void)
{
  RF_START;
  RF_LOG("pstor");
  {
    uintptr_t *addr;
    intptr_t n;

    addr = (uintptr_t *) RF_SP_POP;
    n = (intptr_t) RF_SP_POP;
    *addr += n;
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_TOGGL
void rf_code_toggl(void)
{
  RF_START;
  RF_LOG("toggl");
  {
    char bits;
    char *addr;

    bits = (char) RF_SP_POP;
    addr = (char *) RF_SP_POP;
    *addr ^= bits;
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_AT
void rf_code_at(void)
{
  RF_START;
  RF_LOG("at");
  {
    uintptr_t *addr;
    uintptr_t word;

    addr = (uintptr_t *) RF_SP_POP;
    word = *addr;
    RF_SP_PUSH(word);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_CAT
void rf_code_cat(void)
{
  RF_START;
  RF_LOG("cat");
  {
    uint8_t *addr;
    
    addr = (uint8_t *) RF_SP_POP;
    RF_SP_PUSH((uintptr_t) *addr);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_STORE
void rf_code_store(void)
{
  RF_START;
  RF_LOG("store");
  {
    uintptr_t *addr;
    uintptr_t p;

    addr = (uintptr_t *) RF_SP_POP;
    p = RF_SP_POP;
    *addr = p;
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_CSTOR
void rf_code_cstor(void)
{
  RF_START;
  RF_LOG("cstor");
  {
    uint8_t *addr;
    uint8_t c;

    addr = (uint8_t *) RF_SP_POP;
    c = (uint8_t) RF_SP_POP;
    *addr = c;
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DOCOL
void rf_code_docol(void)
{
  RF_START;
  RF_LOG("docol");
  RF_RP_PUSH((uintptr_t) RF_IP_GET);
  RF_IP_SET((uintptr_t *) rf_w + 1);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DOCON
void rf_code_docon(void)
{
  RF_START;
  RF_LOG("docon");
  RF_SP_PUSH(*((uintptr_t *) rf_w + 1));
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DOVAR
void rf_code_dovar(void)
{
  RF_START;
  RF_LOG("dovar");
  RF_SP_PUSH((uintptr_t) (rf_w + 1));
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DOUSE
void rf_code_douse(void)
{
  RF_START;
  RF_LOG("douse");
  {
    uintptr_t idx;

    idx = *((uintptr_t *) (rf_w + 1));
    RF_SP_PUSH((uintptr_t) (((char *) rf_up) + idx));
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_STOD
void rf_code_stod(void)
{
  RF_START;
  RF_LOG("stod");
  {
    intptr_t a;

    a = RF_SP_POP;
    RF_SP_PUSH(a);
    RF_SP_PUSH(a < 0 ? -1 : 0);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_COLD
static void rf_cold(void)
{
  int i;
  uintptr_t *origin = (uintptr_t *) RF_ORIGIN;

  /* FORTH vocabulary - parameter field set at inst time */
  /* 0C +ORIGIN LDA, 'T FORTH 4 + STA, ( FORTH VOCAB. ) */
  /* 0D +ORIGIN LDA, 'T FORTH 5 + STA, */
  *((uintptr_t *) origin[17]) = origin[6];

  /* 15 # LDY, ( INDEX TO VOC-LINK ) 0= IF, ( FORCED ) */
  i = 10;
  /* 0F # LDY,  ( INDEX TO WARNING )   THEN, ( FROM IF, ) */
  /* i = 7; */

  /* UP */
  /* 10 +ORIGIN LDA, UP STA, ( LOAD UP ) */
  /* 11 +ORIGIN LDA, UP 1+ STA, */
  rf_up = (uintptr_t *) origin[8];

  /* USER vars */
  /* BEGIN, 0C +ORIGIN ,Y LDA, ( FROM LITERAL AREA ) */
  /* UP )Y STA, ( TO USER AREA ) */
  /* DEY, 0< END, */
  for (; i >= 0; --i) {
    rf_up[i] = origin[i + 6];
  }

  /* jump to RP! then to ABORT - PFA set at inst time */
  /* 'T ABORT 100 /MOD # LDA, IP 1+ STA, */
  /* # LDA, IP STA, */
  RF_IP_SET((uintptr_t *) origin[18]);

  /* 6C # LDA, W 1 - STA,  */
  /* 'T RP! JMP, ( RUN )  */
  RF_JUMP(rf_code_rpsto);
}

void rf_code_cold(void)
{
  RF_START;
  RF_LOG("cold");
  rf_cold();
}
#endif

#ifndef RF_TARGET_CODE_DCHAR
void rf_code_dchar(void)
{
  RF_START;
  {
    char a, c;

    a = (char) RF_SP_POP;
    rf_disc_read(&c, 1);
    RF_SP_PUSH(c == a);
    RF_SP_PUSH(c);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_BREAD
void rf_code_bread(void)
{
  RF_START;
  rf_disc_read((char *) RF_SP_POP, RF_BBLK);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_BWRIT
static char eot = 0x04;

void rf_code_bwrit(void)
{
  RF_START;
  {
    uint8_t a = (uint8_t) RF_SP_POP;
    char *b = (char *) RF_SP_POP;

    rf_disc_write(b, a);
    rf_disc_write(&eot, 1);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_XT
void rf_code_xt(void)
{
  RF_START;
  rf_fp = 0;
}
#endif

#ifndef RF_TARGET_CODE_CL
void rf_code_cl(void)
{
  RF_START;
  RF_LOG("cl");
  RF_SP_PUSH(RF_WORD_SIZE);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_CS
void rf_code_cs(void)
{
  RF_START;
  RF_LOG("cs");
  {
    uintptr_t a;

    a = RF_SP_POP;
    RF_SP_PUSH(RF_WORD_SIZE * a);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_LN
void rf_code_ln(void)
{
  RF_START;
  RF_LOG("ln");
#ifdef RF_ALIGN
  {
    uintptr_t a;

    a = RF_SP_POP;
    while (a % RF_ALIGN) {
      ++a;
    }
    RF_SP_PUSH(a);
  }
#endif
  RF_JUMP_NEXT;
}
#endif
