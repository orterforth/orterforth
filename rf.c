/* ORTERFORTH */

#include "rf.h"

/* FORTH MACHINE */

/* parameter stack pointer */
uintptr_t *rf_sp = 0;

#ifndef RF_INLINE_SP
uintptr_t rf_sp_pop(void)
{
  return *(rf_sp++);
}

void __FASTCALL__ rf_sp_push(uintptr_t a)
{
  *(--rf_sp) = (a);
}
#endif

/* return stack pointer */
uintptr_t *rf_rp = 0;

#ifndef RF_INLINE_RP
uintptr_t rf_rp_pop(void)
{
  return *(rf_rp++);
}

void __FASTCALL__ rf_rp_push(uintptr_t a)
{
  *(--rf_rp) = ((uintptr_t) a);
}
#endif

#ifndef RF_TARGET_IP
/* Interpretive Pointer */
uintptr_t *rf_ip = 0;
#endif

/* code field pointer */
#ifndef RF_TARGET_W
rf_code_t *rf_w = 0;
#endif

/* user area pointer */
#ifndef RF_TARGET_UP
uintptr_t *rf_up = 0;
#endif

/* TRAMPOLINE */

/* trampoline function pointer */
rf_code_t rf_fp = 0;

#ifndef RF_TARGET_TRAMPOLINE
void rf_trampoline(void)
{
  /* repeatedly execute function pointers */
  while (rf_fp) {
    /* target implementations can switch machine state into registers */
    /* default implementation does nothing */

    rf_fp();
    /* C-based code returns here and the loop repeats */
  }
}

void rf_start(void)
{
  /* called at start of C-based code */
  /* target implementations can switch machine state out of registers */
  /* default implementation does nothing */
}
#endif

/* CODE */

#ifndef RF_TARGET_CODE_LIT
void rf_code_lit(void)
{
  RF_START;
  RF_LOG("lit");
  {
    uintptr_t a;

    a = *(RF_IP_GET);
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
    intptr_t index;
    intptr_t limit;

    index = (intptr_t) RF_RP_POP;
    limit = (intptr_t) RF_RP_POP;
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
    intptr_t n;
    intptr_t index;
    intptr_t limit;

    n = (intptr_t) RF_SP_POP;
    index = RF_RP_POP;
    limit = RF_RP_POP;
    index += n;

    if (n > 0 ? (limit > index) : (index > limit)) {
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
  uintptr_t offset;
  
  offset = (uintptr_t) *(RF_IP_GET);
  RF_IP_SET((uintptr_t *) (((char *) RF_IP_GET) + offset));
}
#endif

#ifndef RF_TARGET_CODE_XDO
void rf_code_xdo(void)
{
  RF_START;
  RF_LOG("xdo");
  {
    uintptr_t n1;
    uintptr_t n2;

    n2 = RF_SP_POP;
    n1 = RF_SP_POP;
    RF_RP_PUSH(n1);
    RF_RP_PUSH(n2);
  }
  RF_JUMP_NEXT;
}
#endif

uintptr_t __FASTCALL__ *rf_lfa(char *nfa)
{
  while (!(*(++nfa) & 0x80)) {
  }
  return (uintptr_t *) ++nfa;
}

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
    uintptr_t i;

    i = (uintptr_t) *(RF_RP_GET);
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

    b = RF_SP_POP;
    c = RF_SP_POP;
    d = rf_digit(b, c);
    if (d == 255) {
      RF_SP_PUSH(0);
    } else {
      RF_SP_PUSH(d);
      RF_SP_PUSH(1);
    }
  }
  RF_JUMP_NEXT;
}
#endif

char *rf_find(char *t, uint8_t length, char *nfa)
{
  uint8_t l;
  uint8_t i;

  while (nfa) {
    /* length from name field incl smudge bit */
    l = nfa[0] & 0x3F;

    /* try and match the name */
    if (l == length) {
      for (i = 0; i < l; i++) {
        if (t[i] != (nfa[i + 1] & 0x7F)) {
          l = 0;
          break;
        }
      }

      if (l) {
        return nfa;
      }
    }

    /* if no match, follow link */
    nfa = (char *) *(rf_lfa(nfa));
  }

  /* not found */
  return 0;
}

#ifndef RF_TARGET_CODE_PFIND
static uintptr_t __FASTCALL__ *rf_pfa(char *nfa)
{
  uintptr_t *lfa = rf_lfa(nfa);
  uintptr_t *pfa = lfa + 2;
  return pfa;
}

static uintptr_t rf_pfind(char *addr1, char *addr2)
{
  char length;
  char *f;

  length = *addr1;
  f = rf_find(addr1 + 1, length, (char *) addr2);
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
    char *addr2;
    char *addr1;
    uintptr_t f;

    addr2 = (char *) RF_SP_POP; /* nfa */
    addr1 = (char *) RF_SP_POP; /* text to find */
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
    uintptr_t count;
    char *to;
    char *from;
    uintptr_t i;

    count = RF_SP_POP;
    to = (char *) RF_SP_POP;
    from = (char *) RF_SP_POP;
    for (i = 0; i < count; ++i) {
      to[i] = from[i];
    }
  }
  RF_JUMP_NEXT;
}
#endif

#ifdef RF_DOUBLE_ARITH
#ifndef RF_TARGET_CODE_USTAR
#ifndef RF_DPUSH
#define RF_DPUSH
static void __FASTCALL__ rf_dpush(rf_double_t *a);
#endif
static void rf_ustar(void)
{
  uintptr_t a;
  uintptr_t b;
  rf_double_t d;

  a = RF_SP_POP;
  b = RF_SP_POP;
  d = (rf_double_t) a * b;
  rf_dpush(&d);
}

void rf_code_ustar(void)
{
  RF_START;
  RF_LOG("ustar");
  rf_ustar();
  RF_JUMP_NEXT;
}
#endif
#endif

#ifdef RF_DOUBLE_ARITH
#ifndef RF_TARGET_CODE_USLAS
#ifndef RF_DPOP
static void rf_dpop(rf_double_t *a);
#define RF_DPOP
#endif
static void rf_uslas(void)
{
  rf_double_t b;
  rf_double_t a;

  b = (rf_double_t) RF_SP_POP;
  rf_dpop(&a);
  if ((a >> RF_WORD_SIZE_BITS) >= b) {
    RF_SP_PUSH(-1);
    RF_SP_PUSH(-1);
  } else {
    RF_SP_PUSH((uintptr_t) (a % b));
    RF_SP_PUSH((uintptr_t) (a / b));
  }
}

void rf_code_uslas(void)
{
  RF_START;
  RF_LOG("uslas");
  rf_uslas();
  RF_JUMP_NEXT;
}
#endif
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

#ifdef RF_DOUBLE_ARITH

#ifndef RF_TARGET_CODE_DPLUS
#ifndef RF_DPOP
static void rf_dpop(rf_double_t *a);
#define RF_DPOP
#endif
#ifndef RF_DPUSH
#define RF_DPUSH
static void __FASTCALL__ rf_dpush(rf_double_t *a);
#endif
static void rf_dplus(void)
{
  rf_double_t a, b, c;

  rf_dpop(&a);
  rf_dpop(&b);
  c = a + b;
  rf_dpush(&c);
}

void rf_code_dplus(void)
{
  RF_START;
  RF_LOG("dplus");
  rf_dplus();
  RF_JUMP_NEXT;
}
#endif
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

#ifdef RF_DOUBLE_ARITH
#ifndef RF_TARGET_CODE_DMINU
#ifndef RF_DPOP
static void rf_dpop(rf_double_t *a);
#define RF_DPOP
#endif
#ifndef RF_DPUSH
#define RF_DPUSH
static void __FASTCALL__ rf_dpush(rf_double_t *a);
#endif
void rf_code_dminu(void)
{
  RF_START;
  RF_LOG("dminu");
  {
    rf_double_t d;
    
    rf_dpop(&d);
    d = -d;
    rf_dpush(&d);
  }
  RF_JUMP_NEXT;
}
#endif
#endif

#ifdef RF_DOUBLE_ARITH
#ifdef RF_DPOP
static void rf_dpop(rf_double_t *e)
{
  uintptr_t a = RF_SP_POP;
  uintptr_t b = RF_SP_POP;
  rf_double_t c = (rf_double_t) a << RF_WORD_SIZE_BITS;
  rf_double_t d = (rf_double_t) b;
  *e = c | d;
}
#endif
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
/* non-zero so not allocated in BSS and not zeroed on entry */
uintptr_t *rf_cold_forth = (uintptr_t *) 1;
uintptr_t *rf_cold_abort = (uintptr_t *) 1;

void rf_cold(void)
{
  /* HERE 02 +ORIGIN ! ( POINT COLD ENTRY TO HERE ) */
  uintptr_t *origin = (uintptr_t *) RF_ORIGIN;

  /* FORTH vocabulary */
  /* 0C +ORIGIN LDA, 'T FORTH 4 + STA, ( FORTH VOCAB. ) */
  /* 0D +ORIGIN LDA, 'T FORTH 5 + STA, */
  *rf_cold_forth = origin[6];

  /* UP and USER vars */

  /* 10 +ORIGIN LDA, UP STA, ( LOAD UP ) */
  /* 11 +ORIGIN LDA, UP 1+ STA, */
  rf_up = (uintptr_t *) origin[8];

  /* BEGIN, 0C +ORIGIN ,Y LDA, ( FROM LITERAL AREA ) */
  /* UP )Y STA, ( TO USER AREA ) */
  /* DEY, 0< END, */

  rf_up[0] = origin[6];
  rf_up[1] = origin[7];
  rf_up[2] = origin[8];
  RF_USER_S0 = origin[9];
  RF_USER_R0 = origin[10];
  RF_USER_TIB = origin[11];
  RF_USER_WIDTH = origin[12];
  RF_USER_WARNING = origin[13];

  RF_USER_FENCE = origin[14];
  RF_USER_DP = origin[15];
  RF_USER_VOCLINK = origin[16];

  /* jump to RP! then to ABORT */
  /* 'T ABORT 100 /MOD # LDA, IP 1+ STA, */
  /* # LDA, IP STA, */
  RF_IP_SET(rf_cold_abort);
  /* 6C # LDA, W 1 - STA,  */
  /* 'T RP! JMP, ( RUN )  */
  RF_RP_SET((uintptr_t *) RF_USER_R0);
}

void rf_code_cold(void)
{
  RF_START;
  RF_LOG("cold");
  rf_cold();
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_DCHAR
void rf_code_dchar(void)
{
  RF_START;
  {
    char a, c;

    a = RF_SP_POP;
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
    uint8_t a = RF_SP_POP;
    char *b = (char *) RF_SP_POP;

    rf_disc_write(b, a);
    rf_disc_write(&eot, 1);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_RXIT
void rf_code_rxit(void)
{
  RF_START;
  rf_fp = 0;
}
#endif

#ifndef RF_TARGET_CODE_RCLL
void rf_code_rcll(void)
{
  RF_START;
  RF_LOG("rcll");
  RF_SP_PUSH(RF_WORD_SIZE);
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_RCLS
void rf_code_rcls(void)
{
  RF_START;
  RF_LOG("rcls");
  {
    uintptr_t a;

    a = RF_SP_POP;
    RF_SP_PUSH(RF_WORD_SIZE * a);
  }
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_RLNS
void rf_code_rlns(void)
{
  RF_START;
  RF_LOG("rlns");
#ifdef RF_ALIGN
  {
    uintptr_t a;

    a = RF_SP_POP;
    /*if (a % RF_ALIGN) a += RF_ALIGN - (a % RF_ALIGN);*/
/*
    if (a & 0x01) {
*/
    if (a % RF_ALIGN) {
/*       ++a;*/
      /* TODO support wider align */
      a += RF_ALIGN - (a % RF_ALIGN);
    }
    RF_SP_PUSH(a);
  }
#endif
  RF_JUMP_NEXT;
}
#endif

#ifndef RF_TARGET_CODE_RTGT
void rf_code_rtgt(void)
{
  RF_START;
  RF_SP_PUSH(RF_TARGET_LO);
  RF_SP_PUSH(RF_TARGET_HI);
  RF_JUMP_NEXT;
}
#endif

#ifdef RF_DOUBLE_ARITH
#ifdef RF_DPUSH
static void __FASTCALL__ rf_dpush(rf_double_t *a)
{
  uintptr_t b = *a;
  uintptr_t c = *a >> RF_WORD_SIZE_BITS;
  RF_SP_PUSH(b);
  RF_SP_PUSH(c);
}
#endif
#endif
