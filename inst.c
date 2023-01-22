/* TODO remove if not necessary */
#ifdef __RC2014
#include <z80.h>
#endif

#include "rf.h"
#ifdef RF_INST_LOCAL_DISC
/* disc controller runs in process */
#include "persci.h"
/* fig-Forth source compiled into C array */
/* const to compile to flash on e.g. Pico */
const
#include "model.inc"
#endif

/* ASCII CONTROL CHARS */
#define RF_ASCII_EOT 4
#define RF_ASCII_ENQ 5
#define RF_ASCII_ACK 6

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

/* PerSci disc command, I or O */
static void rf_inst_disc_cmd_set(char c, uintptr_t blk)
{
  uintptr_t offset = blk % 2000;

  /* set command */
  cmd[0] = c;
  /* convert block number into drive, track and sector */
  rf_inst_puti(2, offset / 26);
  rf_inst_puti(5, (offset % 26) + 1);
  cmd[9] = 48 + (blk / 2000);
}

/* INST TIME CODE */

/* flag to indicate completion of install */
extern char rf_installed;

/* do nothing - only used to create a no op CR */
#ifdef RF_INST_SILENT
static void rf_inst_code_noop(void)
{
  RF_START;
  RF_JUMP_NEXT;
}
#endif

/* PREV - always use just first buffer */
static void rf_inst_code_prev(void)
{
  RF_START;
  RF_SP_PUSH((uintptr_t) RF_FIRST);
  RF_JUMP_NEXT;
}

/* block-cmd - write I nn nn /n and return buffer address */
static void rf_inst_code_block_cmd(void)
{
  RF_START;
  {
    uintptr_t block = RF_SP_POP;

    /* create command */
    rf_inst_disc_cmd_set('I', block);

    /* return command addr */
    RF_SP_PUSH((uintptr_t) cmd);
  }
  RF_JUMP_NEXT;
}

/* replaces strlen */
static uint8_t __FASTCALL__ rf_inst_strlen(const char *s)
{
  uint8_t i;

  for (i = 0; *(s++); ++i) {
  }
  return i;
}

/* replaces memset */
static void rf_inst_memset(uint8_t *ptr, uint8_t value, unsigned int num)
{
  while (num--) {
    *(ptr++) = value;
  }
}

/* , */
static void __FASTCALL__ rf_inst_comma(uintptr_t word)
{
  *((uintptr_t *) RF_USER_DP) = word;
  RF_USER_DP += RF_WORD_SIZE;
}

/* CURRENT and CONTEXT vocabulary during inst */
static char *rf_inst_vocabulary = 0;

/* CREATE */
static void rf_inst_create(uint8_t length, uint8_t *name)
{
  uint8_t *here = (uint8_t *) RF_USER_DP;
  uint8_t *there = here;

  /* length byte with smudge */
  *here = length | 0xA0;

  /* name */
  while (length--) {
    *(++here) = *(name++);
  }
  ++here;

#ifdef __CC65__
  /* 6502 bug workaround */
  *here = 0x20;
  if (((uintptr_t) here & 0xFF) == 0xFD) {
    ++here;
  }
#endif
#ifdef RF_ALIGN
  /* word alignment */
  while ((uintptr_t) here % RF_ALIGN) {
    *here = 0x20;
    ++here;
  }
#endif

  /* terminating bit */
  *(here - 1) |= 0x80;

  /* link field */
  RF_USER_DP = (uintptr_t) here;
  rf_inst_comma((uintptr_t) rf_inst_vocabulary);

  /* vocabulary */
  rf_inst_vocabulary = (char *) there;
}

/* create and un-smudge */
static void __FASTCALL__ rf_inst_def(char *name)
{
  /* create */
  rf_inst_create(rf_inst_strlen(name), (uint8_t *) name);
  /* un-smudge */
  *rf_inst_vocabulary ^= 0x20;
}

/* NUMBER */
static intptr_t __FASTCALL__ rf_inst_number(char *t)
{
  intptr_t l = 0;
  uint8_t sign;
  uint8_t d;

  /* - */
  sign = (*t == '-');
  if (sign) {
    t++;
  }

  /* ASCII 0-9 */
  for (;;) {
    d = *(t++) - 0x30;
    if (d > 0x09) {
      break;
    }

    l *= 10;
    l += d;
  }

  return sign ? -l : l;
}

/* LFA */
static uintptr_t __FASTCALL__ *rf_inst_lfa(char *nfa)
{
  while (!(*(++nfa) & 0x80)) {
  }
  return (uintptr_t *) ++nfa;
}

/* CFA */
static rf_code_t __FASTCALL__ *rf_inst_cfa(char *nfa)
{
  uintptr_t *lfa = rf_inst_lfa(nfa);
  uintptr_t *cfa = lfa + 1;
  return (rf_code_t *) cfa;
}

/* (FIND) */
static char *rf_inst_find(char *t, uint8_t length, char *nfa)
{
  uint8_t l;
  uint8_t i;
  uintptr_t *lfa;
  char *n;

  while (nfa) {
    /* length from name field incl smudge bit */
    l = *nfa & 0x3F;
    /* start of name */
    n = nfa + 1;
    /* match name */
    if (l == length) {
      for (i = 0; i < l; i++) {
        if (t[i] != (*(n++) & 0x7F)) {
          break;
        }
      }
      if (i == l) {
        return nfa;
      }
    }

    /* if no match, follow link */
    lfa = rf_inst_lfa(nfa);
    nfa = (char *) *(lfa);
  }

  /* not found */
  return 0;
}

/* proto outer interpreter */
static void __FASTCALL__ rf_inst_compile(char *name)
{
  char *p;
  char *nfa;

  for (;;) {
    /* read until space or null */
    for (p = name; *p != ' ' && *p != '\0'; p++) { }

    /* find in dictionary */
    nfa = rf_inst_find(name, p - name, rf_inst_vocabulary);

    if (nfa) {
      /* compile word */
      rf_inst_comma((uintptr_t) rf_inst_cfa(nfa));
    } else {
      /* compile number */
      intptr_t factor = 1;
      intptr_t accum = 0;
      char *q = name;

      /* ^ to * by word size */
      if (*q == '^') {
        q++;
        factor = RF_WORD_SIZE;
      }
      /* now read decimal number */
      accum = rf_inst_number(q);

      /* to prefix with LIT, BRANCH or 0BRANCH */
      rf_inst_comma((uintptr_t) (factor * accum));
    }

    /* look for more */
    if (!*p) break;
    name = ++p;
  }
}

/* IMMEDIATE */
static void rf_inst_immediate(void)
{
  *rf_inst_vocabulary ^= 0x40;
}

/* compile a LIT value */
static void __FASTCALL__ rf_inst_compile_lit(uintptr_t literal)
{
  /* compile LIT */
  rf_inst_comma((uintptr_t) rf_inst_cfa(rf_inst_find("LIT", 3, rf_inst_vocabulary)));
  /* compile value */
	rf_inst_comma(literal);
}

/* compile a definition and set CFA */
static void rf_inst_def_code(char *name, rf_code_t code)
{
  rf_inst_def(name);
  rf_inst_comma((uintptr_t) code);
}

/* compile a colon definition */
static void __FASTCALL__ rf_inst_colon(char *name)
{
  rf_inst_def_code(name, rf_code_docol);
}

/* inst time literal code */
static void rf_inst_code_doliteral(void)
{
  RF_START;
  {
    uintptr_t number = *((uintptr_t *) rf_w + 1);

    if (RF_USER_STATE) {
      rf_inst_compile_lit(number);
    } else {
      RF_SP_PUSH(number); 
    }
  }
  RF_JUMP_NEXT;
}

/* compile an inst time literal - these install-time values 
   are compiled as literals or executed and so aren't
   referenced by the resulting install.
*/
static void rf_inst_def_literal(char *name, uintptr_t value)
{
  rf_inst_def_code(name, rf_inst_code_doliteral);
  rf_inst_comma(value);
  rf_inst_immediate();
}

/* compile a user variable */
static void rf_inst_def_user(char *name, unsigned int idx)
{
  rf_inst_def_code(name, rf_code_douse);
  rf_inst_comma(idx * RF_WORD_SIZE);
}

/* put inst time definitions in spare memory and unlink them when finished */
/* NB 3000 may be tight with more extensions */
#define RF_INST_DICTIONARY (RF_ORIGIN + (3000*RF_WORD_SIZE))

#define RF_FIGRELFIGREV 0x0101 /* 1.1 */

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

/* inst time cold start, based on COLD, ABORT, QUIT */
static void rf_inst_cold(void)
{
  /* set vocabulary */
  /* 0C +ORIGIN LDA, 'T FORTH 4 + STA, ( FORTH VOCAB. ) */
  /* 0D +ORIGIN LDA, 'T FORTH 5 + STA, */
  rf_inst_vocabulary = 0;

  /* set UP */
  rf_up = (uintptr_t *) RF_USER;

  /* set USER vars */
  /* BEGIN, 0C +ORIGIN ,Y LDA, ( FROM LITERAL AREA ) */
  /* UP )Y STA, ( TO USER AREA ) */
  /* DEY, 0< END, */

  /* warm start */
  RF_USER_S0 = (uintptr_t) RF_S0;
  RF_USER_R0 = (uintptr_t) RF_R0;
  RF_USER_TIB = (uintptr_t) RF_TIB;
  RF_USER_WIDTH = 31;
  RF_USER_WARNING = 0;

  /* cold start */
  RF_USER_FENCE = (uintptr_t) RF_INST_DICTIONARY;
  RF_USER_DP = (uintptr_t) RF_INST_DICTIONARY;
  RF_USER_VOCLINK = 0;

  /* set IP to ABORT */
  /* 'T ABORT 100 /MOD # LDA, IP 1+ STA, */
  /* # LDA, IP STA, */

  /* create 6502 JMP ind */
  /* 6C # LDA, W 1 - STA, */

  /* jump to RP! */
  /* 'T RP! JMP, ( RUN ) */
  RF_RP_SET((uintptr_t *) RF_USER_R0);

  /* : ABORT */
  /* SP! */
  RF_SP_SET((uintptr_t *) RF_USER_S0);
  /* DECIMAL */
  RF_USER_BASE = 10;
  /* DR0 */
  RF_USER_OFFSET = 0;
  /* CR ." FORTH-65 V 4.0" */
  /* [COMPILE] FORTH */
  RF_USER_CONTEXT = (uintptr_t) &rf_inst_vocabulary;
  /* DEFINITIONS */
  RF_USER_CURRENT = RF_USER_CONTEXT;
  /* QUIT */

  /* : QUIT */
  /* 0 BLK ! */
  RF_USER_BLK = 0;
  /* [COMPILE] [ */
  RF_USER_STATE = 0;
  /* then the outer interpreter loop */
  /* BEGIN RP! CR QUERY INTERPRET */
  /* STATE @ 0= IF ."  OK" ENDIF AGAIN */
}

/* compile additional words after boot time literals */
static void rf_inst_code_add(void)
{
  RF_START;
  rf_inst_def_code("cl", rf_code_cl);
  rf_inst_def_code("cs", rf_code_cs);
  rf_inst_def_code("ln", rf_code_ln);
  rf_inst_def_code("tg", rf_code_tg);
  rf_inst_def_code("xt", rf_code_xt);
  RF_JUMP_NEXT;
}

/* Table of inst time code addresses */

typedef struct rf_inst_code_t {
  char *name;
  char *word;
  rf_code_t value;
} rf_inst_code_t;

#define RF_INST_CODE_LIT_LIST_SIZE 64

static rf_inst_code_t rf_inst_code_lit_list[] = {
  { 0, "cl", rf_code_cl },
  { 0, "cs", rf_code_cs },
  { 0, "ln", rf_code_ln },
  { 0, 0, rf_code_tg },
  { 0, "xt", rf_code_xt },
  { "lit", "LIT", rf_code_lit },
  { "exec", "EXECUTE", rf_code_exec },
  { "bran", "BRANCH", rf_code_bran },
  { "zbran", "0BRANCH", rf_code_zbran },
  { "xloop", 0, rf_code_xloop },
  { "xploo", 0, rf_code_xploo },
  { "xdo", 0, rf_code_xdo },
  { "digit", "DIGIT", rf_code_digit },
  { "pfind", "(FIND)", rf_code_pfind },
  { "encl", "ENCLOSE", rf_code_encl },
  { "emit2", 0, rf_code_emit },
#ifdef RF_INST_SILENT
  { "emit", 0, rf_code_drop },
#else
  { "emit", 0, rf_code_emit },
#endif
  { "key", 0, rf_code_key },
  { "qterm", 0, rf_code_qterm },
  { "cr2", 0, rf_code_cr },
#ifdef RF_INST_SILENT
  { "cr", 0, rf_inst_code_noop },
#else
  { "cr", 0, rf_code_cr },
#endif
  { "cmove", "CMOVE", rf_code_cmove },
  { "ustar", "U*", rf_code_ustar },
  { "uslas", 0, rf_code_uslas },
  { "andd", "AND", rf_code_andd },
  { "orr", 0, rf_code_orr },
  { "xorr", 0, rf_code_xorr },
  { "spat", "SP@", rf_code_spat },
  { "spsto", 0, rf_code_spsto },
  { "rpsto", 0, rf_code_rpsto },
  { "semis", ";S", rf_code_semis },
  { "leave", 0, rf_code_leave },
  { "tor", ">R", rf_code_tor },
  { "fromr", "R>", rf_code_fromr },
  { "rr", "R", rf_code_rr },
  { "zequ", "0=", rf_code_zequ },
  { "zless", "0<", rf_code_zless },
  { "plus", "+", rf_code_plus },
  { "dplus", 0, rf_code_dplus },
  { "minus", "MINUS", rf_code_minus },
  { "dminu", 0, rf_code_dminu },
  { "over", "OVER", rf_code_over },
  { "drop", "DROP", rf_code_drop },
  { "swap", "SWAP", rf_code_swap },
  { "dup", "DUP", rf_code_dup },
  { "pstor", "+!", rf_code_pstor },
  { "toggl", "TOGGLE", rf_code_toggl },
  { "at", "@", rf_code_at },
  { "cat", "C@", rf_code_cat },
  { "store", "!", rf_code_store },
  { "cstor", "C!", rf_code_cstor },
  { "docol", 0, rf_code_docol },
  { "docon", 0, rf_code_docon },
  { "dovar", 0, rf_code_dovar },
  { "douse", 0, rf_code_douse },
  { "dodoe", 0, rf_code_dodoe },
  { "cold", 0, rf_code_cold },
  { "stod", 0, rf_code_stod },
  { "dchar", "D/CHAR", rf_code_dchar },
  { "bwrit", "BLOCK-WRITE", rf_code_bwrit },
  { "bread", "BLOCK-READ", rf_code_bread },
  { 0, "add", rf_inst_code_add },
  { 0, "prev", rf_inst_code_prev },
  { 0, "block-cmd", rf_inst_code_block_cmd }
};

#ifndef RF_BS
#define RF_BS 0x007F
#endif

static rf_code_t *rf_inst_load_cfa = 0;

static void rf_inst_forward(void)
{
  int i;
  uint8_t *here;

  /* user variables */
  rf_inst_def_user("DP", RF_USER_DP_IDX);
  rf_inst_def_user("BLK", RF_USER_BLK_IDX);
  rf_inst_def_user("IN", RF_USER_IN_IDX);
  rf_inst_def_user("CONTEXT", RF_USER_CONTEXT_IDX);
  rf_inst_def_user("CURRENT", RF_USER_CURRENT_IDX);
  rf_inst_def_user("STATE", RF_USER_STATE_IDX);
  rf_inst_def_user("BASE", RF_USER_BASE_IDX);
  rf_inst_def_user("CSP", RF_USER_CSP_IDX);

  /* boot time literals */
  rf_inst_def_literal("relrev", (uintptr_t) RF_FIGRELFIGREV);
  rf_inst_def_literal("ver", (uintptr_t) RF_USRVER | RF_ATTRWI | RF_ATTRE | RF_ATTRB | RF_ATTRA);
  rf_inst_def_literal("bs", (uintptr_t) RF_BS);
  rf_inst_def_literal("user", (uintptr_t) RF_USER);
  rf_inst_def_literal("inits0", (uintptr_t) RF_S0);
  rf_inst_def_literal("initr0", (uintptr_t) RF_R0);
  rf_inst_def_literal("tib", (uintptr_t) RF_TIB);

  /* code address literals */
  for (i = 0; i < RF_INST_CODE_LIT_LIST_SIZE; ++i) {
    rf_inst_code_t *code = &rf_inst_code_lit_list[i];
    /* model source builds code word with the address */
    if (code->name) {
      rf_inst_def_literal(code->name, (uintptr_t) code->value);
    }
    /* model source requires these to be defined already */
    if (code->word) {
      rf_inst_def_code(code->word, code->value);
    }
  }

  /* for +ORIGIN */
  rf_inst_def_literal("origin", (uintptr_t) RF_ORIGIN);

  /* disc buffer literals */
  rf_inst_def_literal("first", (uintptr_t) RF_FIRST);
  rf_inst_def_literal("limit", (uintptr_t) RF_LIMIT);

  /* stack limit literals */
  rf_inst_def_literal("s0", (uintptr_t) RF_S0);
  rf_inst_def_literal("s1", (uintptr_t) ((uintptr_t *) RF_S0 - RF_STACK_SIZE));

  /* COLD routine forward references */
  rf_inst_def_literal("coldforth", (uintptr_t) &rf_cold_forth);
  rf_inst_def_literal("coldabort", (uintptr_t) &rf_cold_abort);

  /* installed flag now set from Forth */
  rf_inst_def_literal("installed", (uintptr_t) &rf_installed);

  /* - */
  rf_inst_colon("-");
  rf_inst_compile("MINUS + ;S");

  /* HERE */
  rf_inst_colon("HERE");
  rf_inst_compile("DP @ ;S");

  /* BLANKS */
  rf_inst_colon("BLANKS");
  rf_inst_compile(
    "LIT 32 SWAP >R OVER C! DUP LIT 1 + R> LIT 1 - CMOVE ;S");

  /* ?DISC */
  rf_inst_colon("?DISC");
  rf_inst_compile(
    "LIT 1 D/CHAR DROP 0BRANCH ^2 ;S LIT 4 D/CHAR DROP DROP ;S");

  /* BLOCK */
  rf_inst_colon("BLOCK");
  rf_inst_compile(
    "DUP prev @ - 0BRANCH ^15 DUP block-cmd LIT 10 BLOCK-WRITE ?DISC prev "
    "cl + BLOCK-READ ?DISC DUP prev ! DROP prev cl + ;S");

  /* WORD */
  rf_inst_colon("WORD");
  /* wider align may need more blanks in edge case of long words */
  /* maybe not here but in final model source version of WORD */
  rf_inst_compile(
    "BLK @ BLOCK IN @ + SWAP ENCLOSE HERE LIT 34 BLANKS IN +! "
    "OVER - >R R HERE C! + HERE LIT 1 + R> CMOVE ;S");
 
  /* -FIND */
  rf_inst_colon("-FIND");
  rf_inst_compile("LIT 32 WORD HERE CONTEXT @ @ (FIND) ;S");

  /* , */
  rf_inst_colon(",");
  rf_inst_compile("HERE ! cl DP +! ;S");

  /* COMPILE */
  rf_inst_colon("COMPILE");
  rf_inst_compile("R> DUP cl + >R @ , ;S");

  /* (NUMBER) */
  rf_inst_colon("(NUMBER)");
  rf_inst_compile("LIT 0 SWAP DUP >R C@ BASE @ DIGIT 0BRANCH ^13 "
    "SWAP BASE @ U* DROP + R> LIT 1 + BRANCH ^-19 R> DROP ;S");

  /* NUMBER */
  rf_inst_colon("NUMBER");
  rf_inst_compile("LIT 1 + DUP C@ LIT 45 - 0= DUP >R + (NUMBER) "
    "R> 0BRANCH ^2 MINUS ;S");

  /* INTERPRET */
  /* LIT must be resolved later to final value of LIT CFA */
  rf_inst_colon("INTERPRET");
  rf_inst_compile(
    "-FIND 0BRANCH ^17 STATE @ - 0< 0BRANCH ^6 cl - , BRANCH ^4 cl - "
    "EXECUTE BRANCH ^-18 HERE NUMBER STATE @ 0BRANCH ^-24 COMPILE LIT , "
    "BRANCH ^-29");

  /* CREATE */
  rf_inst_colon("CREATE");
  rf_inst_compile(
    "-FIND 0BRANCH ^3 DROP DROP HERE DUP C@ LIT 1 + DP +! DP C@ "
    "LIT 253 - 0= DP +!");
#ifdef RF_ALIGN
  rf_inst_compile("HERE ln DP !");
#endif
  rf_inst_compile(
    "DUP LIT 160 TOGGLE HERE LIT 1 - LIT 128 TOGGLE CURRENT @ @ "
    ", CURRENT @ ! HERE cl + , ;S");

  /* LOAD */
  rf_inst_colon("LOAD");
  rf_inst_compile(
    "BLK @ >R IN @ >R LIT 0 IN ! LIT 8 U* DROP BLK ! INTERPRET R> IN ! R> BLK "
    "! ;S");

  /* inst load sequence */
  rf_inst_colon("load");
  rf_inst_load_cfa = (rf_code_t *) RF_USER_DP - 1;
  rf_inst_compile("LIT 1 LOAD xt");

  /* X */  
  here = (uint8_t *) RF_USER_DP;
  rf_inst_colon("X");
  rf_inst_compile(
    "LIT 1 BLK +! LIT 0 IN ! BLK @ LIT 7 AND 0= 0BRANCH ^3 R> DROP ;S");
  here[1] ^= 0x58;
  rf_inst_immediate();

  /* [ */
  rf_inst_colon("[");
  rf_inst_compile("LIT 0 STATE ! ;S");
  rf_inst_immediate();

  /* DECIMAL */
  rf_inst_colon("DECIMAL");
  rf_inst_compile("LIT 10 BASE ! ;S");
}

static void rf_inst_emptybuffers(void)
{
  rf_inst_memset((uint8_t *) RF_FIRST, '\0', (char *) RF_LIMIT - (char *) RF_FIRST);
}

static void rf_inst_load(void)
{
  /* initialise buffers */
  rf_inst_emptybuffers();

  /* initialise RP */
  RF_RP_SET((uintptr_t *) RF_USER_R0);

  /* jump to "load" */
  RF_IP_SET((uintptr_t *) &rf_inst_load_cfa);
  RF_JUMP(rf_next);
  rf_trampoline();
}

#ifdef RF_INST_SAVE
static char rf_inst_disc_eot = RF_ASCII_EOT;

/* write block */
static void rf_inst_disc_w(char *b, uintptr_t blk)
{
  /* static char here fails for some reason on BBC build */
  char d[2];

  /* send command */
  rf_inst_disc_cmd_set('O', blk);
  rf_disc_write((char *) cmd, 11);

  /* expect ENQ EOT */
  rf_disc_read(d, 2);

  /* send data */
  rf_disc_write(b, RF_BBLK);
  rf_disc_write(&rf_inst_disc_eot, 1);

  /* expect ACK EOT */
  rf_disc_read(d, 2);
}

/* return an ASCII hex digit */
static char __FASTCALL__ rf_inst_hex(uint8_t b)
{
  return b + (b < 10 ? 48 : 55);
}

/* disc buffer start */
static uint8_t * buf;

/* save the installation as hex on DR1 */
void rf_inst_save(void)
{
  /* write to DR1 */
  unsigned int blk = 2000;
#ifdef RF_INST_RELINK
  /* start from ORIGIN, if code is separate and to be relinked */
  char *i = (char *) RF_ORIGIN;
#else
  /* start from ORG */
  char *i = (char *) RF_ORG;
#endif
  char *e = (char *) RF_USER_DP;
  uint8_t j;

#ifdef RF_INST_RELINK
  /* write table of code addresses after HERE */
  for (j = 0; j < RF_INST_CODE_LIT_LIST_SIZE; j++) {
    *((rf_code_t *) e) = rf_inst_code_lit_list[j].value;
    e += RF_WORD_SIZE;
  }
  /* and write two links used in COLD */
  *((rf_code_t *) e) = (rf_code_t) rf_cold_forth;
  e += RF_WORD_SIZE;
  *((rf_code_t *) e) = (rf_code_t) rf_cold_abort;
  e += RF_WORD_SIZE;
#endif

  /* now write hex blocks to DR1 */
  buf = (uint8_t *) RF_FIRST + RF_WORD_SIZE;
  while (i < e) {
    for (j = 0; j < 128;) {
      uint8_t b = *i++;
      buf[j++] = rf_inst_hex(b >> 4);
      buf[j++] = rf_inst_hex(b & 15);
    }
    rf_inst_disc_w(buf, blk++);
  }
  /* write a block of 'Z's as a signal to terminate */
  rf_inst_memset(buf, 'Z', 128);
  rf_inst_disc_w(buf, blk);
}
#endif

void rf_inst(void)
{
#ifndef RF_INST_LOCAL_DISC
  /* wait for disc server to init */
  /* TODO remove if not necessary */
#ifdef __RC2014
  z80_delay_ms(5000);
#else
#endif
#endif

  /* cold start */
  rf_inst_cold();

  /* define required words */
  rf_inst_forward();

#ifdef RF_INST_LOCAL_DISC
  /* "insert" the inst disc */
  rf_persci_insert_bytes(0, "model.disc", model_disc, model_disc_len);
#endif

  /* LOAD all Forth model source from disc */
  rf_inst_load();

#ifdef RF_INST_LOCAL_DISC
  /* now "eject" the inst disc */
  rf_persci_eject(0);
#endif

#ifdef RF_INST_SAVE
  /* save the result to disc */
  rf_inst_save();
#endif
}
