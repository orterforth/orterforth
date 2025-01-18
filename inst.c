#include "rf.h"

/* if we delay start of inst to allow disc server to start */
#ifdef RF_INST_WAIT
#ifdef __M100__
#include <stdlib.h>
#define RF_INST_SLEEP sleep(5)
#endif
#ifdef __RC2014
#include <z80.h>
#define RF_INST_SLEEP z80_delay_ms(5000)
#endif
#else
#define RF_INST_SLEEP
#endif

/* flag to indicate completion of install */
extern char rf_installed;

/* DP */
static uint8_t **rf_inst_dp = 0;

/* LATEST */
static uint8_t *rf_inst_latest = 0;

/* disc command buffer */
static uint8_t cmd[11] = {
  'I', ' ', '0', '0', ' ', '0', '0', ' ', '/', '0', '\x04'
};

/* , */
static void __FASTCALL__ rf_inst_comma(uintptr_t word)
{
  *(*((uintptr_t **) rf_inst_dp))++ = word;
}

/* compile a definition and set CFA */
static void rf_inst_code(const char *name, const rf_code_t code)
{
  uint8_t *here = *rf_inst_dp;
  uint8_t *there = here;

  /* name */
  while (*name > ' ') {
    *(++here) = *(name++);
  }

  /* length byte, unsmudged */
  *there = (uint8_t) (here++ - there) | 0x80;

  /* 6502 JMP (ind) bug workaround */
#ifdef __CC65__
  if (((uint8_t) here & 0xFF) == 0xFD) {
    *(here++) = 0x20;
  }
#endif
  /* address alignment */
#ifdef RF_ALIGN
  while ((uintptr_t) here % RF_ALIGN) {
    *(here++) = 0x20;
  }
#endif

  /* update DP */
  *rf_inst_dp = here;

  /* terminating bit */
  *(--here) |= 0x80;

  /* link field */
  rf_inst_comma((uintptr_t) rf_inst_latest);
  rf_inst_latest = there;

  /* code field */
  rf_inst_comma((uintptr_t) code);
}

/* PFA LFA */
static uint8_t __FASTCALL__ **rf_inst_lfa(uint8_t *nfa)
{
  /* traverse name field */
  while (!(*(++nfa) & 0x80)) {
  }
  return (uint8_t **) ++nfa;
}

/* (FIND) */
static uint8_t *rf_inst_find(const char *t, uint8_t length)
{
  uint8_t i;
  uint8_t *m, *n;
  uint8_t *nfa = rf_inst_latest;

  while (nfa) {
    /* match name (use smudge bit) */
    if ((*nfa & 0x3F) == length) {
      m = (uint8_t *) t;
      n = nfa;
      i = length;
      while (*(m++) == (*(++n) & 0x7F)) {
        if (!--i) {
          return nfa;
        }
      }
    }

    /* if no match, follow link */
    nfa = *rf_inst_lfa(nfa);
  }

  /* not found */
  return 0;
}

/* PFA CFA */
static rf_code_t __FASTCALL__ *rf_inst_cfa(uint8_t *nfa)
{
  uint8_t **lfa = rf_inst_lfa(nfa);
  return (rf_code_t *) ++lfa;
}

/* NUMBER */
static intptr_t __FASTCALL__ rf_inst_number(char *t)
{
  intptr_t factor = 1;
  intptr_t l = 0;
  uint8_t d;

  /* ^ to * by cell size */
  if (*t == '^') {
    ++t;
    factor = RF_WORD_SIZE;
  }

  /* - to negate */
  if (*t == '-') {
    ++t;
    factor = -factor;
  }

  /* ASCII 0-9 */
  while ((d = *(t++) - 0x30) < 0x0A) {
    l *= 10;
    l += d;
  }

  /* result */
  return l * factor;
}

/* proto outer interpreter */
static void __FASTCALL__ rf_inst_compile(const char *source)
{
  char *name = (char *) source;
  char *p;
  uint8_t *nfa;

  while (*name) {

    /* read until space or null */
    for (p = name; *p > ' '; ++p) { }

    /* interpret what we have */
    switch (*name) {
      case ':':
      /* create colon definition */
      rf_inst_code(++name, rf_code_docol);
      break;
      default:
      /* find in dictionary */
      nfa = rf_inst_find(name, (uint8_t) (p - name));
      /* compile word if found, or number (to prefix with LIT, BRANCH or 0BRANCH) */
      rf_inst_comma(nfa ? (uintptr_t) rf_inst_cfa(nfa) : (uintptr_t) rf_inst_number(name));
      break;
    }

    /* trailing spaces */
    while (*p == ' ') ++p;

    /* look for more */
    name = p;
  }
}

/* run proto interpreter */
static void rf_inst_code_compile(void)
{
  RF_START;
  {
    char *addr = (char *) (*(rf_sp++));
    rf_inst_compile(addr);
  }
  RF_JUMP_NEXT;
}

/* put inst time definitions in spare memory and unlink them when finished */
/* NB 3000 may be tight with more extensions */
#ifndef RF_INST_DICTIONARY
#define RF_INST_DICTIONARY (RF_ORIGIN + (3000*RF_WORD_SIZE))
#endif

/* IMPLEMENTATION ATTRIBUTES */
/* B +ORIGIN   ...W:IEBA */
/* W: 0=above sufficient 1=other differences exist */
/* I: Interpreter is	0=pre- 1=post incrementing */
#define RF_ATTRWI 0x0800
/* E: Addr must be even: 0 yes 1 no */
#ifndef RF_ALIGN
#define RF_ATTRE 0x0400
#else
#define RF_ATTRE 0x0000
#endif
/* B: High byte @	0=low addr. 1=high addr. */
#ifdef RF_LE
#define RF_ATTRB 0x0200
#else
#define RF_ATTRB 0x0000
#endif
/* A: CPU Addr.		0=BYTE 1=WORD */
#if (RF_ALIGN==RF_WORD_SIZE)
#define RF_ATTRA 0x0100
#else
#define RF_ATTRA 0x0000
#endif

/* USRVER = r for retro */
#define RF_USRVER 0x0072

/* BS */
#ifndef RF_BS
#define RF_BS 0x007F
#endif

/* table of inst time code addresses */
static const rf_code_t rf_inst_codes[] = {
  rf_code_cl,
  rf_code_cs,
  rf_code_ln,
  rf_code_lit,
  rf_code_exec,
  rf_code_bran,
  rf_code_zbran,
  rf_code_xloop,
  rf_code_xploo,
  rf_code_xdo,
  rf_code_digit,
  rf_code_pfind,
  rf_code_encl,
  rf_code_emit,
#ifdef RF_INST_SILENT
  rf_code_drop,
#else
  rf_code_emit,
#endif
  rf_code_key,
  rf_code_qterm,
  rf_code_cr,
  rf_code_cmove,
  rf_code_ustar,
  rf_code_uslas,
  rf_code_andd,
  rf_code_orr,
  rf_code_xorr,
  rf_code_spat,
  rf_code_spsto,
  rf_code_rpsto,
  rf_code_semis,
  rf_code_leave,
  rf_code_tor,
  rf_code_fromr,
  rf_code_rr,
  rf_code_zequ,
  rf_code_zless,
  rf_code_plus,
  rf_code_dplus,
  rf_code_minus,
  rf_code_dminu,
  rf_code_over,
  rf_code_drop,
  rf_code_swap,
  rf_code_dup,
  rf_code_pstor,
  rf_code_toggl,
  rf_code_at,
  rf_code_cat,
  rf_code_store,
  rf_code_cstor,
  rf_code_docol,
  rf_code_docon,
  rf_code_dovar,
  rf_code_douse,
  rf_code_dodoe,
  rf_code_cold,
  rf_code_stod,
  rf_code_dchar,
  rf_code_bwrit,
  rf_code_bread,
  rf_code_mon,
  rf_inst_code_compile
};

/* corresponding word names */
static const char * rf_inst_names[] = {
  "cl",
  "cs",
  "ln",
  "LIT",
  "EXECUTE",
  "BRANCH",
  "0BRANCH",
  "(LOOP)",
  0,
  "(DO)",
  "DIGIT",
  "(FIND)",
  "ENCLOSE",
  0,
  0,
  0,
  0,
  0,
  "CMOVE",
  "U*",
  "U/",
  "AND",
  0,
  0,
  "SP@",
  "SP!",
  0,
  ";S",
  0,
  ">R",
  "R>",
  "R",
  "0=",
  "0<",
  "+",
  0,
  "MINUS",
  0,
  "OVER",
  "DROP",
  "SWAP",
  "DUP",
  "+!",
  "TOGGLE",
  "@",
  "C@",
  "!",
  "C!",
  0,
  0,
  0,
  0,
  0,
  "COLD",
  0,
  "D/CHAR",
  "BLOCK-WRITE",
  "BLOCK-READ",
  "MON",
  "compile",
};

/* table of installation constants: */
static uintptr_t rf_inst_constants[] = {
  RF_USRVER | RF_ATTRWI | RF_ATTRE | RF_ATTRB | RF_ATTRA,
  RF_BS,
#ifdef RF_INST_DYNAMIC
  0,
  0,
  0,
  0,
#else
  RF_USER,
  RF_S0,
  RF_R0,
  RF_TIB,
#endif
  RF_TARGET_HI,
  RF_TARGET_LO,
#ifdef RF_INST_DYNAMIC
  0,
  0,
  0,
  0,
#else
  (uintptr_t) RF_ORIGIN,
  (uintptr_t) RF_FIRST,
  (uintptr_t) RF_LIMIT,
  (uintptr_t) RF_S1,
#endif
  0,
#ifdef RF_ORG
  RF_ORG,
#else
  0,
#endif
#ifdef RF_INST_LINK
  1,
#else
  0,
#endif
#ifdef RF_INST_SAVE
#ifdef RF_INST_RELOC
  3,
#else
#ifdef RF_INST_LINK
  2,
#else
  1,
#endif
#endif
#else
  0,
#endif
  RF_CPU_HI,
  RF_CPU_LO,
  0,
#ifdef RF_EXT
  (uintptr_t) rf_ext
#else
  0
#endif
};


/* bootstrap the installing Forth vocabulary and install Forth itself */
void rf_inst(void)
{
  int i;
  uintptr_t *origin = (uintptr_t *) RF_ORIGIN;

  /* heap alloc dependent constants */
#ifdef RF_INST_DYNAMIC
  rf_inst_constants[2] = (uintptr_t) RF_USER;
  rf_inst_constants[3] = (uintptr_t) RF_S0;
  rf_inst_constants[4] = (uintptr_t) RF_R0;
  rf_inst_constants[5] = (uintptr_t) RF_TIB;
  rf_inst_constants[8] = (uintptr_t) RF_ORIGIN;
  rf_inst_constants[9] = (uintptr_t) RF_FIRST;
  rf_inst_constants[10] = (uintptr_t) RF_LIMIT;
  rf_inst_constants[11] = (uintptr_t) RF_S1;
#endif
  /* some C compilers do not regard these & expressions as constant */
  rf_inst_constants[12] = (uintptr_t) &rf_installed;
  rf_inst_constants[18] = (uintptr_t) &rf_inst_codes;

  /* cold start LATEST UP DP */
  rf_inst_latest = 0;
  rf_up = (uintptr_t *) RF_USER;
  rf_inst_dp = (uint8_t **) rf_up + 9;
  *rf_inst_dp = (uint8_t *) RF_INST_DICTIONARY;

  /* to get constant table */
  rf_inst_code("id", rf_code_docon);
  rf_inst_comma((uintptr_t) &rf_inst_constants);

  /* code words */
  for (i = 0; i < 60; ++i) {
    const char *name = rf_inst_names[i];
    if (name) {
      rf_inst_code(name, rf_inst_codes[i]);
    }
  }

  /* disc command (set track and sector) */
  rf_inst_code("cmd", rf_code_docon);
  rf_inst_comma((uintptr_t) &cmd);
  rf_inst_compile(
    ":ch cmd + SWAP LIT 48 + SWAP C! ;S "
    ":hl >R LIT 0 LIT 10 U/ R ch R> LIT 1 + ch ;S "
    ":hld LIT 0 LIT 26 U/ LIT 2 hl LIT 1 + LIT 5 hl cmd ;S");
  /* ic (installation constants), FIRST */
  rf_inst_compile(
    ":ic cs id + @ ;S :FIRST LIT 9 ic ;S");
  /* ?DISC, BLOCK */
  rf_inst_compile(
    ":?DISC LIT 1 D/CHAR DROP 0BRANCH ^2 ;S "
    "LIT 4 D/CHAR DROP DROP ;S "
    ":BLOCK FIRST cl + "
    "OVER FIRST @ MINUS + 0BRANCH ^10 "
    "OVER hld LIT 10 BLOCK-WRITE ?DISC "
    "DUP BLOCK-READ ?DISC "
    "SWAP FIRST ! ;S");
  /* load and launch the outer interpreter */
  /*rf_inst_compile(":inst");*/ /* dict header not required */
  origin[22] = (uintptr_t) *rf_inst_dp;
  rf_inst_compile(
    "SP! "
    "LIT 0 FIRST OVER OVER ! cl + LIT 128 + ! "
    "LIT 805 LIT 785 (DO) R BLOCK compile (LOOP) ^-4 "
    "LIT ^21 LIT 8 ic + @ @ LIT ^-24 + EXECUTE");

  /* set boot-up literals */
  /* LATEST */
  origin[6] = (uintptr_t) rf_inst_latest;
  /* USER area */
  origin[8] = (uintptr_t) RF_USER;
  /* S0, R0, DP user variables */
  origin[9] = (uintptr_t) RF_S0;
  origin[10] = (uintptr_t) RF_R0;
  origin[15] = (uintptr_t) *rf_inst_dp;
  /* instead of FORTH */
  origin[21] = (uintptr_t) &rf_inst_latest;
  /* instead of ABORT */
  /*origin[22] = (uintptr_t) ((uintptr_t *) rf_inst_cfa(rf_inst_latest) + 1);*/

  /* wait for disc server to init */ 
  RF_INST_SLEEP;

  /* run COLD, which inits and runs :inst */
  /* NB no code can be run before COLD because */
  /* necessary operations may live there */
  rf_fp = rf_code_cold;
  rf_trampoline();
}
