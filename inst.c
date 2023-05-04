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
static void __FASTCALL__ rf_inst_disc_cmd_set(uintptr_t blk)
{
  /* convert block number into track and sector */
  rf_inst_puti(2, blk / 26);
  rf_inst_puti(5, (blk % 26) + 1);
}

/* block-cmd - write I nn nn /n and return buffer address */
static void rf_inst_code_block_cmd(void)
{
  RF_START;
  {
    uintptr_t block = RF_SP_POP;

    /* create command */
    rf_inst_disc_cmd_set(block);

    /* return command addr */
    RF_SP_PUSH((uintptr_t) cmd);
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
static void __FASTCALL__ rf_inst_def(char *name)
{
  uint8_t *here = (uint8_t *) RF_USER_DP;
  uint8_t *there = here;

  /* name */
  while (*name > ' ') {
    *(++here) = *(name++);
  }

  /* length byte, unsmudged */
  *there = (here++ - there) | 0x80;

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

/* LFA */
static uint8_t __FASTCALL__ **rf_inst_lfa(uint8_t *nfa)
{
  while (!(*(++nfa) & 0x80)) {
  }
  return (uint8_t **) ++nfa;
}

/* (FIND) */
static uint8_t *rf_inst_find(char *t, uint8_t length)
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

/* compile a constant */
static void rf_inst_def_constant(char *name, uintptr_t value)
{
  rf_inst_def_code(name, rf_code_docon);
  rf_inst_comma(value);
}

/* compile a user variable */
static void rf_inst_def_user(char *name, unsigned int idx)
{
  rf_inst_def_code(name, rf_code_douse);
  rf_inst_comma(idx * RF_WORD_SIZE);
}

/* CFA */
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
    t++;
    factor = RF_WORD_SIZE;
  }

  /* - to negate */
  if (*t == '-') {
    t++;
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
static void __FASTCALL__ rf_inst_compile(char *name)
{
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
      nfa = rf_inst_find(name, p - name);
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
  /* 10 +ORIGIN LDA, UP STA, ( LOAD UP ) */
  /* 11 +ORIGIN LDA, UP 1+ STA, */
  rf_up = (uintptr_t *) RF_USER;

  /* set USER vars */
  /* BEGIN, 0C +ORIGIN ,Y LDA, ( FROM LITERAL AREA ) */
  /* UP )Y STA, ( TO USER AREA ) */
  /* DEY, 0< END, */

  /* warm start */
  RF_USER_S0 = (uintptr_t) RF_S0;
  RF_USER_R0 = (uintptr_t) RF_R0;
  /*RF_USER_TIB = (uintptr_t) RF_TIB;*/
  RF_USER_WIDTH = 31;
  RF_USER_WARNING = 0;

  /* cold start */
  /*RF_USER_FENCE = (uintptr_t) RF_INST_DICTIONARY;*/
  RF_USER_DP = (uintptr_t) RF_INST_DICTIONARY;
  /*RF_USER_VOCLINK = 0;*/

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
  RF_USER_CURRENT = (uintptr_t) &rf_inst_vocabulary;
  /* QUIT */

  /* : QUIT */
  /* 0 BLK ! */
  /*RF_USER_BLK = 0;*/
  /* [COMPILE] [ */
  RF_USER_STATE = 0;
  /* then the outer interpreter loop */
  /* BEGIN RP! CR QUERY INTERPRET */
  /* STATE @ 0= IF ."  OK" ENDIF AGAIN */
}

/* do nothing - only used to create a no op CR */
#ifdef RF_INST_SILENT
static void rf_inst_code_noop(void)
{
  RF_START;
  RF_JUMP_NEXT;
}
#endif

/* Table of inst time code addresses */

typedef struct rf_inst_code_t {
  char *word;
  rf_code_t value;
} rf_inst_code_t;

#define RF_INST_CODE_LIT_LIST_SIZE 62

static const rf_inst_code_t rf_inst_code_lit_list[] = {
  { "cl", rf_code_cl },
  { "cs", rf_code_cs },
  { "ln", rf_code_ln },
  { 0, rf_code_tg },
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
#ifdef RF_INST_SILENT
  { 0, rf_inst_code_noop },
#else
  { 0, rf_code_cr },
#endif
  { "CMOVE", rf_code_cmove },
  { "U*", rf_code_ustar },
  { 0, rf_code_uslas },
  { "AND", rf_code_andd },
  { 0, rf_code_orr },
  { 0, rf_code_xorr },
  { "SP@", rf_code_spat },
  { 0, rf_code_spsto },
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
  { 0, rf_code_cold },
  { 0, rf_code_stod },
  { "D/CHAR", rf_code_dchar },
  { "BLOCK-WRITE", rf_code_bwrit },
  { "BLOCK-READ", rf_code_bread },
  { "block-cmd", rf_inst_code_block_cmd }
};

#ifndef RF_BS
#define RF_BS 0x007F
#endif

/* replaces memset */
static void rf_inst_memset(uint8_t *ptr, uint8_t value, unsigned int num)
{
  while (num--) {
    *(ptr++) = value;
  }
}

/* EMPTY-BUFFERS */
static void rf_inst_emptybuffers(void)
{
  rf_inst_memset((uint8_t *) RF_FIRST, '\0', RF_DISC_BUFFERS_SIZE);
}

/* static location for IP to run a Forth word */
static rf_code_t *rf_inst_load_cfa = 0;

/* look up a Forth word and run the Forth machine */
static void rf_inst_execute(char *name, uint8_t len)
{
  /* set RP, IP */
  RF_RP_SET((uintptr_t *) RF_USER_R0);
  rf_inst_load_cfa = rf_inst_cfa(rf_inst_find(name, len));
  RF_IP_SET((uintptr_t *) &rf_inst_load_cfa);
  /* start at NEXT */
  RF_JUMP_NEXT;
  rf_trampoline();
}

/* look up a code address in the table */
static void rf_inst_code_cd(void)
{
  RF_START;
  {
    uintptr_t idx = RF_SP_POP;
    RF_SP_PUSH((uintptr_t) rf_inst_code_lit_list[idx].value);
  }
  RF_JUMP_NEXT;
}

/* run proto interpreter */
static void rf_inst_code_compile(void)
{
  RF_START;
  {
    char *addr = (char *) RF_SP_POP;
    rf_inst_compile(addr);
  }
  RF_JUMP_NEXT;
}

/* flag to indicate completion of install */
extern char rf_installed;

/* bootstrap the installing Forth vocabulary */
static void rf_inst_forward(void)
{
  int i;

  /* user variables */
  rf_inst_def_user("DP", RF_USER_DP_IDX);
  rf_inst_def_user("BLK", RF_USER_BLK_IDX);
  rf_inst_def_user("IN", RF_USER_IN_IDX);
  rf_inst_def_user("CONTEXT", RF_USER_CONTEXT_IDX);
  rf_inst_def_user("CURRENT", RF_USER_CURRENT_IDX);
  rf_inst_def_user("STATE", RF_USER_STATE_IDX);
  rf_inst_def_user("BASE", RF_USER_BASE_IDX);
  rf_inst_def_user("CSP", RF_USER_CSP_IDX);

  /* boot time literals and s0 for ?STACK */
  /* TODO no need for relrev */
  rf_inst_def_constant("relrev", (uintptr_t) RF_FIGRELFIGREV);
  rf_inst_def_constant("ver", (uintptr_t) RF_USRVER | RF_ATTRWI | RF_ATTRE | RF_ATTRB | RF_ATTRA);
  rf_inst_def_constant("bs", (uintptr_t) RF_BS);
  rf_inst_def_constant("user", (uintptr_t) RF_USER);
  rf_inst_def_constant("s0", (uintptr_t) RF_S0);
  rf_inst_def_constant("r0", (uintptr_t) RF_R0);
  rf_inst_def_constant("tib", (uintptr_t) RF_TIB);

  /* forward defined code words */
  for (i = 0; i < RF_INST_CODE_LIT_LIST_SIZE; ++i) {
    const rf_inst_code_t *code = &rf_inst_code_lit_list[i];
    if (code->word) {
      rf_inst_def_code(code->word, code->value);
    }
  }

  /* code address lookup */
  rf_inst_def_code("cd", rf_inst_code_cd);

  /* for boot-up literals used by tg */
  rf_inst_def_constant("tghi", RF_TARGET_HI);
  rf_inst_def_constant("tglo", RF_TARGET_LO);

  /* for +ORIGIN */
  rf_inst_def_constant("origin", (uintptr_t) RF_ORIGIN);

  /* disc buffer constants */
  rf_inst_def_constant("FIRST", (uintptr_t) RF_FIRST);
  rf_inst_def_constant("LIMIT", (uintptr_t) RF_LIMIT);

  /* stack limit for ?STACK */
  rf_inst_def_constant("s1", (uintptr_t) ((uintptr_t *) RF_S0 - RF_STACK_SIZE));

  /* installed flag now set from Forth */
  rf_inst_def_constant("installed", (uintptr_t) &rf_installed);

  /* ?DISC */
  rf_inst_compile(
    ":?DISC LIT 1 D/CHAR DROP 0BRANCH ^2 ;S LIT 4 D/CHAR DROP DROP ;S");

  /* BLOCK */
  rf_inst_compile(
    ":BLOCK DUP FIRST @ MINUS + 0BRANCH ^15 DUP block-cmd LIT 10 BLOCK-WRITE ?DISC FIRST "
    "cl + BLOCK-READ ?DISC DUP FIRST ! DROP FIRST cl + ;S");

  /* read from disc and run proto interpreter */
  rf_inst_def_code("compile", rf_inst_code_compile);
  rf_inst_compile(
    ":proto LIT 641 DUP LIT -659 + 0BRANCH ^9 DUP BLOCK compile LIT 1 + BRANCH ^-13 DROP xt");
  rf_inst_emptybuffers();
  rf_inst_execute("proto", 5);
}

static void rf_inst_load(void)
{
  /* TODO don't need emptybuffers again */
  rf_inst_emptybuffers();
  rf_inst_execute("load", 4);
}

#ifdef RF_INST_SAVE
static char rf_inst_disc_eot = 4;

/* write block */
static void rf_inst_disc_w(char *b, uintptr_t blk)
{
  /* static char here fails for some reason on BBC build */
  char d[2];

  /* send command */
  rf_inst_disc_cmd_set(blk);
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

/* inner hex loop */
char *rf_inst_save_hex(char *i)
{
  uint8_t j;

  for (j = 0; j < 128;) {
    uint8_t b = *i++;
    buf[j++] = rf_inst_hex(b >> 4);
    buf[j++] = rf_inst_hex(b & 15);
  }

  return i;
}

/* save the installation as hex on DR1 */
void rf_inst_save(void)
{
  /* write to DR1 - offset to DR1 is now assumed */
  unsigned int blk = 0;
#ifdef RF_INST_LINK
  /* start from ORIGIN, if code is separate and to be relinked */
  char *i = (char *) RF_ORIGIN;
#else
  /* start from ORG */
  char *i = (char *) RF_ORG;
#endif
  char *e = (char *) RF_USER_DP;
  uint8_t j;

#ifdef RF_INST_LINK
  /* write table of code addresses after HERE */
  for (j = 0; j < RF_INST_CODE_LIT_LIST_SIZE; j++) {
    *((rf_code_t *) e) = rf_inst_code_lit_list[j].value;
    e += RF_WORD_SIZE;
  }
#endif

  /* now write hex blocks to DR1 */
  cmd[0] = 'O';
  cmd[9] = '1';
  buf = (uint8_t *) RF_FIRST + RF_WORD_SIZE;
  while (i < e) {
    i = rf_inst_save_hex(i);
    rf_inst_disc_w(buf, blk++);
  }
  /* write a block of 'Z's as a signal to terminate */
  rf_inst_memset(buf, 'Z', 128);
  rf_inst_disc_w(buf, blk);
}
#endif

#ifdef PICO
extern char rf_system_local_disc;
#endif

#ifndef RF_INST_LOCAL_DISC
/* TODO remove if not necessary */
#ifdef __RC2014
#include <z80.h>
#endif

static void rf_inst_sleep(void)
{
#ifdef __RC2014
  z80_delay_ms(5000);
#else
/*
  sleep(5);
*/
#endif
}
#endif

void rf_inst(void)
{
#ifndef RF_INST_LOCAL_DISC
  /* wait for disc server to init */
  rf_inst_sleep();
#endif

  /* cold start */
  rf_inst_cold();

#ifdef RF_INST_LOCAL_DISC
  /* "insert" the inst disc */
  rf_persci_insert_bytes(0, model_disc);
#endif

  /* define required words */
  rf_inst_forward();

  /* LOAD all Forth model source from disc */
  rf_inst_load();

#ifdef RF_INST_LOCAL_DISC
  /* now "eject" the inst disc */
  rf_persci_eject(0);
#ifdef PICO
  rf_system_local_disc = 0;
#endif
#endif

#ifdef RF_INST_SAVE
  /* save the result to disc */
  rf_inst_save();
#endif
}
