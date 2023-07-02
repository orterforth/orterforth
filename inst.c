#include "inst.h"
#include "rf.h"
#ifdef RF_INST_LOCAL_DISC
/* disc controller runs in process */
#include "persci.h"
/* fig-Forth source compiled into C array */
/* const to compile to flash on e.g. Pico */
const
#include "model.inc"
#endif

#ifdef RF_INST_WAIT
#ifdef __RC2014
#include <z80.h>
#endif
#endif

/* INST TIME STACK OPERATIONS */

#define RF_INST_SP_POP (*(rf_sp++))
#define RF_INST_SP_PUSH(a) { *(--rf_sp) = (a); }

/* INST TIME DISC OPERATIONS */

/* inst time disc command buffer */
static uint8_t cmd[11] = {
  'I', ' ', '0', '0', ' ', '0', '0', ' ', '/', '0', '\x04'
};

/* write two place decimal integer */
static void rf_inst_puti(uint8_t idx, uint8_t i)
{
  cmd[idx++] = 48 + (i / 10);
  cmd[idx] = 48 + (i % 10);
}

/* hld - write I nn nn /n and return buffer address */
static void rf_inst_code_hld(void)
{
  RF_START;
  {
    uintptr_t block = RF_INST_SP_POP;

    /* convert block number into track and sector */
    rf_inst_puti(2, (uint8_t) (block / 26));
    rf_inst_puti(5, (uint8_t) (block % 26) + 1);

    /* return command addr */
    RF_INST_SP_PUSH((uintptr_t) cmd);
  }
  RF_JUMP_NEXT;
}

/* INST TIME DICTIONARY OPERATIONS */

/* , */
static void __FASTCALL__ rf_inst_comma(uintptr_t word)
{
  *((uintptr_t *) RF_USER_DP) = word;
  RF_USER_DP += RF_WORD_SIZE;
}

/* CURRENT and CONTEXT vocabulary during inst */
static uint8_t *rf_inst_vocabulary = 0;

/* CREATE + SMUDGE */
static void __FASTCALL__ rf_inst_def(const char *name)
{
  uint8_t *here = (uint8_t *) RF_USER_DP;
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

  /* terminating bit */
  *(here - 1) |= 0x80;

  /* update DP */
  RF_USER_DP = (uintptr_t) here;

  /* link field */
  rf_inst_comma((uintptr_t) rf_inst_vocabulary);
  rf_inst_vocabulary = there;
}

/* NFA LFA */
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
  uint8_t *n;
  uint8_t *nfa = rf_inst_vocabulary;

  while (nfa) {
    /* test length from name field incl smudge bit */
    if ((*nfa & 0x3F) == length) {
      /* match name */
      n = nfa;
      for (i = 0; i < length; ++i) {
        if (t[i] != (*(++n) & 0x7F)) {
          break;
        }
      }
      /* if we have a match */
      if (i == length) {
        return nfa;
      }
    }

    /* if no match, follow link */
    nfa = *rf_inst_lfa(nfa);
  }

  /* not found */
  return 0;
}

/* compile a definition and set CFA */
static void rf_inst_code(const char *name, rf_code_t code)
{
  rf_inst_def(name);
  rf_inst_comma((uintptr_t) code);
}

/* compile a colon definition */
static void __FASTCALL__ rf_inst_colon(char *name)
{
  rf_inst_code(name, rf_code_docol);
}

/* compile a constant */
static void rf_inst_constant(const char *name, uintptr_t value)
{
  rf_inst_code(name, rf_code_docon);
  rf_inst_comma(value);
}

/* NFA CFA */
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
    if (*name == ':') {
      /* create colon definition */
      /* two colons means immediate */
      if (*(++name) == ':') {
        rf_inst_colon(++name);
        *rf_inst_vocabulary ^= 0x40;
      } else {
        rf_inst_colon(name);
      }
    } else {
      /* find in dictionary */
      nfa = rf_inst_find(name, (uint8_t) (p - name));
      /* compile word if found, or number (to prefix with LIT, BRANCH or 0BRANCH) */
      rf_inst_comma(nfa ? (uintptr_t) rf_inst_cfa(nfa) : (uintptr_t) rf_inst_number(name));
    }

    /* trailing spaces */
    while (*p == ' ') ++p;

    /* look for more */
    name = p;
  }
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

/* inst time cold start */
static void rf_inst_cold(void)
{
  rf_inst_vocabulary = 0;
  rf_up = (uintptr_t *) RF_USER;
  RF_USER_DP = (uintptr_t) RF_INST_DICTIONARY;
}

/* Table of inst time code addresses */

typedef struct rf_inst_code_t {
  const char *word;
  rf_code_t value;
} rf_inst_code_t;

#define RF_INST_CODE_LIT_LIST_SIZE 62

static const rf_inst_code_t rf_inst_code_lit_list[] = {
  { "cl", rf_code_cl },
  { "cs", rf_code_cs },
  { "ln", rf_code_ln },
  { 0, 0 }, /* TODO remove this row */
  { "xt", rf_code_xt },
  { "LIT", rf_code_lit },
  { "EXECUTE", rf_code_exec },
  { "BRANCH", rf_code_bran },
  { "0BRANCH", rf_code_zbran },
  { 0, rf_code_xloop },
  { 0, rf_code_xploo },
  { 0, rf_code_xdo },
  { "DIGIT", rf_code_digit },
  { "(FIND)", rf_code_pfind },
  { "ENCLOSE", rf_code_encl },
  { 0, rf_code_emit },
#ifdef RF_INST_SILENT
  { 0, rf_code_drop },
#else
  { 0, rf_code_emit },
#endif
  { 0, rf_code_key },
  { 0, rf_code_qterm },
  { 0, rf_code_cr },
  { 0, rf_code_cr }, /* TODO remove this row */
  { "CMOVE", rf_code_cmove },
  { "U*", rf_code_ustar },
  { 0, rf_code_uslas },
  { "AND", rf_code_andd },
  { 0, rf_code_orr },
  { 0, rf_code_xorr },
  { "SP@", rf_code_spat },
  { "SP!", rf_code_spsto },
  { 0, rf_code_rpsto },
  { ";S", rf_code_semis },
  { 0, rf_code_leave },
  { ">R", rf_code_tor },
  { "R>", rf_code_fromr },
  { "R", rf_code_rr },
  { "0=", rf_code_zequ },
  { "0<", rf_code_zless },
  { "+", rf_code_plus },
  { 0, rf_code_dplus },
  { "MINUS", rf_code_minus },
  { 0, rf_code_dminu },
  { "OVER", rf_code_over },
  { "DROP", rf_code_drop },
  { "SWAP", rf_code_swap },
  { "DUP", rf_code_dup },
  { "+!", rf_code_pstor },
  { "TOGGLE", rf_code_toggl },
  { "@", rf_code_at },
  { "C@", rf_code_cat },
  { "!", rf_code_store },
  { "C!", rf_code_cstor },
  { 0, rf_code_docol },
  { 0, rf_code_docon },
  { 0, rf_code_dovar },
  { 0, rf_code_douse },
  { 0, rf_code_dodoe },
  { "COLD", rf_code_cold },
  { 0, rf_code_stod },
  { "D/CHAR", rf_code_dchar },
  { "BLOCK-WRITE", rf_code_bwrit },
  { "BLOCK-READ", rf_code_bread },
  { "hld", rf_inst_code_hld }
};

#ifndef RF_BS
#define RF_BS 0x007F
#endif

/* look up a code address in the table */
static void rf_inst_code_cd(void)
{
  RF_START;
  {
    uintptr_t idx = RF_INST_SP_POP;
    RF_INST_SP_PUSH((uintptr_t) rf_inst_code_lit_list[idx].value);
  }
  RF_JUMP_NEXT;
}

/* run proto interpreter */
static void rf_inst_code_compile(void)
{
  RF_START;
  {
    char *addr = (char *) RF_INST_SP_POP;
    rf_inst_compile(addr);
  }
  RF_JUMP_NEXT;
}

/* flag to indicate completion of install */
extern char rf_installed;

#ifdef RF_INST_SAVE
/* return an ASCII hex digit */
static uint8_t __FASTCALL__ rf_inst_hex(uint8_t b)
{
  return b + (b < 10 ? 48 : 55);
}
#endif

static void rf_inst_code_sb(void)
{
  RF_START;
#ifdef RF_INST_SAVE
  {
    uint8_t *buf = (uint8_t *) RF_INST_SP_POP;
    uint8_t *i = (uint8_t *) RF_INST_SP_POP;
    uint8_t j;

    /* inner hex loop */
    for (j = 0; j < 128;) {
      uint8_t b = *i++;
      buf[j++] = rf_inst_hex(b >> 4);
      buf[j++] = rf_inst_hex(b & 15);
    }
  }
#endif
  RF_JUMP_NEXT;
}

/* bootstrap the installing Forth vocabulary */
static void rf_inst_load(void)
{
  int i;
  uintptr_t *origin = (uintptr_t *) RF_ORIGIN;

  /* forward defined code words */
  for (i = 0; i < RF_INST_CODE_LIT_LIST_SIZE; ++i) {
    const rf_inst_code_t *code = &rf_inst_code_lit_list[i];
    if (code->word) {
      rf_inst_code(code->word, code->value);
    }
  }

  /* boot time literals */
  rf_inst_constant("ver", (uintptr_t) RF_USRVER | RF_ATTRWI | RF_ATTRE | RF_ATTRB | RF_ATTRA);
  rf_inst_constant("bs", (uintptr_t) RF_BS);
  rf_inst_constant("user", (uintptr_t) RF_USER);
  rf_inst_constant("s0", (uintptr_t) RF_S0);
  rf_inst_constant("r0", (uintptr_t) RF_R0);
  rf_inst_constant("tib", (uintptr_t) RF_TIB);
  /* boot time literals to identify platform */
  rf_inst_constant("th", RF_TARGET_HI);
  rf_inst_constant("tl", RF_TARGET_LO);
  /* for +ORIGIN and also for save */
  rf_inst_constant("origin", (uintptr_t) RF_ORIGIN);
  /* disc buffer constants */
  rf_inst_constant("FIRST", (uintptr_t) RF_FIRST);
  rf_inst_constant("LIMIT", (uintptr_t) RF_LIMIT);
  /* s0, s1 used in ?STACK */
  rf_inst_constant("s1", (uintptr_t) ((uintptr_t *) RF_S0 - (RF_STACK_SIZE * RF_WORD_SIZE)));
  /* installed flag */
  rf_inst_constant("installed", (uintptr_t) &rf_installed);
  /* save install to DR1 in hex */
#ifdef RF_ORG
  rf_inst_constant("org", RF_ORG);
#else
  rf_inst_constant("org", 0);
#endif
#ifdef RF_INST_LINK
  rf_inst_constant("link?", 1);
#else
  rf_inst_constant("link?", 0);
#endif
#ifdef RF_INST_SAVE
  rf_inst_constant("save?", 1);
#else
  rf_inst_constant("save?", 0);
#endif
  rf_inst_code("sb", rf_inst_code_sb);

  /* proto interpreter */
  rf_inst_code("compile", rf_inst_code_compile);
  /* code address lookup */
  rf_inst_code("cd", rf_inst_code_cd);

  /* ?DISC */
  rf_inst_compile(
    ":?DISC LIT 1 D/CHAR DROP 0BRANCH ^2 ;S LIT 4 D/CHAR DROP DROP ;S");
  /* BLOCK */
  rf_inst_compile(
    ":BLOCK DUP FIRST @ MINUS + 0BRANCH ^15 DUP hld LIT 10 BLOCK-WRITE ?DISC FIRST "
    "cl + BLOCK-READ ?DISC DUP FIRST ! DROP FIRST cl + ;S");
  /* read from disc and run proto interpreter */
  rf_inst_compile(
    ":inst SP! "
    /* empty buffers */
    "LIT 0 DUP FIRST ! FIRST cl + LIT 128 + ! "
    /* loop over blocks */
    "LIT 641 DUP LIT -661 + 0BRANCH ^9 "
    "DUP BLOCK compile "
    "LIT 1 + BRANCH ^-13 DROP "
    /* call ABORT just defined */
    "LIT ^17 origin + @ @ LIT ^-22 + EXECUTE");

  /* set boot-up literals and run COLD */
  origin[6] = (uintptr_t) rf_inst_vocabulary;
  origin[8] = (uintptr_t) RF_USER;
  origin[9] = (uintptr_t) RF_S0;
  origin[10] = (uintptr_t) RF_R0;
  origin[13] = 0;
  origin[15] = (uintptr_t) RF_USER_DP;
  origin[17] = (uintptr_t) &rf_inst_vocabulary;
  origin[18] = (uintptr_t) ((uintptr_t *) rf_inst_cfa(rf_inst_find("inst", 4)) + 1);
  rf_fp = rf_code_cold;
  rf_trampoline();
}

#ifdef PICO
extern char rf_system_local_disc;
#endif

void rf_inst(void)
{
#ifdef RF_INST_WAIT
#ifdef __RC2014
  /* wait for disc server to init */
  z80_delay_ms(10000);
#endif
#endif

  /* cold start */
  rf_inst_cold();

#ifdef RF_INST_LOCAL_DISC
  /* "insert" the inst disc */
  rf_persci_insert_bytes(0, model_disc);
#endif

  /* LOAD all Forth model source from disc */
  rf_inst_load();

#ifdef RF_INST_LOCAL_DISC
  /* now "eject" the inst disc */
  rf_persci_eject(0);
#ifdef PICO
  rf_system_local_disc = 0;
#endif
#endif
}
