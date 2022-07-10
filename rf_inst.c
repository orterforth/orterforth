#include <stdlib.h>
#include <unistd.h>

#include "rf.h"
#ifdef RF_INST_LOCAL_DISC
#include "rf_persci.h"
#endif

/* INST TIME DISC OPERATIONS */

/* convert block number into drive, track and sector */
static void rf_inst_disc_blk(uintptr_t blk, uint8_t *drive, uint8_t *track, uint8_t *sector)
{
  uintptr_t blk_offset;
  
  blk_offset = blk % 2000;
  *drive = blk / 2000;
  *track = blk_offset / 26;
  *sector = (blk_offset % 26) + 1;
}

/* ASCII CONTROL CHARS */

#define RF_ASCII_SOH 1
#define RF_ASCII_EOT 4
#define RF_ASCII_ENQ 5
#define RF_ASCII_ACK 6
#define RF_ASCII_LF 10
#define RF_ASCII_CR 13
#define RF_ASCII_NAK 21

static uint8_t cmd[12] = {
  'I', ' ', '0', '0', ' ', '0', '0', ' ', '/', '0', '0', '\x04'
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
  uint8_t drive, track, sector;

  /* calculate params */
  rf_inst_disc_blk(blk, &drive, &track, &sector);

  /* create command */
  cmd[0] = c;
  rf_inst_puti(2, track);
  rf_inst_puti(5, sector);
  rf_inst_puti(9, drive);
}

#ifdef RF_INST_SAVE
/* write disc command */
static void rf_inst_disc_cmd(char c, uintptr_t blk)
{
  rf_inst_disc_cmd_set(c, blk);
  rf_disc_write((char *) cmd, 12);
}

/* read the next byte from disc, fail if not the expected value */
static void __FASTCALL__ rf_inst_disc_expect(char e)
{
  char c;

  rf_disc_read(&c, 1);
  if (c != e) {
    exit(1);
  }
}

/* write block */
static void rf_inst_disc_w(char *b, uintptr_t blk)
{
  static char eot = RF_ASCII_EOT;

  /* send command */
  rf_inst_disc_cmd('O', blk);

  /* get response */
  rf_inst_disc_expect(RF_ASCII_ENQ);
  rf_inst_disc_expect(RF_ASCII_EOT);

  /* send data */
  rf_disc_write(b, RF_BBLK);
  rf_disc_write(&eot, 1);

  /* get response */
  rf_inst_disc_expect(RF_ASCII_ACK);
  rf_inst_disc_expect(RF_ASCII_EOT);
}
#endif

/* INST TIME CODE */

/* flag to indicate completion of install */
extern char rf_installed;

/* PREV */
static uintptr_t *rf_inst_prev;

/* do nothing */
static void rf_inst_code_noop(void)
{
  RF_START;
  RF_JUMP_NEXT;
}

/* prev */
static void rf_inst_code_prev(void)
{
  RF_START;
  RF_SP_PUSH((uintptr_t) rf_inst_prev);
  RF_JUMP_NEXT;
}

/* block-cmd */
static void rf_inst_code_block_cmd(void)
{
  RF_START;
  {
    uintptr_t block;

    /* create command */
    block = RF_SP_POP;
    rf_inst_disc_cmd_set('I', block);

    /* return command addr */
    RF_SP_PUSH((uintptr_t) cmd);
  }
  RF_JUMP_NEXT;
}

/* replaces strlen */
static int __FASTCALL__ rf_inst_strlen(const char *s)
{
  int i;

  for (i = 0; *(s++); ++i) {
  }
  return i;
}

/* replaces memcpy */
static void rf_inst_memcpy(uint8_t *dst, uint8_t *src, uint8_t length)
{
  while (length--) {
    *dst++ = *src++;
  }
}

/* replaces memset */
static void rf_inst_memset(char *ptr, char value, unsigned int num)
{
  while (num--) {
    *((char *) ptr++) = value;
  }
}

static void __FASTCALL__ rf_inst_comma(uintptr_t word)
{
  uintptr_t *dp;

  dp = (uintptr_t *) RF_USER_DP;
  *dp = word;
  RF_USER_DP = (uintptr_t) (dp + 1);
}

/* LATEST */
static char *rf_inst_latest(void)
{
  return *((char **) RF_USER_CURRENT);
}

/* CREATE */
static void rf_inst_create(uint8_t length, uint8_t *address)
{
  uint8_t *here, *there;

  here = (uint8_t *) RF_USER_DP;
  there = here;

  /* length byte */
  *here = length | 0xA0;
  ++here;

  /* name */
  rf_inst_memcpy(here, address, length);
  here += length;
  *here = 0x20;

#ifdef __CC65__
  /* 6502 bug workaround */
  if (((uintptr_t) here & 0xFF) == 0xFD) {
    ++here;
  }
#endif
#ifdef RF_ALIGN
  /* word alignment */
  if ((uintptr_t) here % RF_ALIGN) here += RF_ALIGN - ((uintptr_t) here % RF_ALIGN);
#endif

  /* terminating bit */
  *(here - 1) |= 0x80;

  /* link field */
  RF_USER_DP = (uintptr_t) here;
  rf_inst_comma((uintptr_t) rf_inst_latest());

  /* vocabulary */
  *((uint8_t **) RF_USER_CURRENT) = there;
}

/* create and smudge */
static void __FASTCALL__ rf_inst_def(char *name)
{
  rf_inst_create(rf_inst_strlen(name), (uint8_t *) name);
  /* un-smudge */
  *(rf_inst_latest()) ^= 0x20;
}

/* NUMBER */
static intptr_t __FASTCALL__ rf_inst_number(char *t) {

  intptr_t l;
  uint8_t sign;
  uint8_t c;
  uint8_t d;
  uint8_t b = RF_USER_BASE;

  sign = 0;
  l = 0;
  for (;;) {
    c = *(t++);

    /* sign */
    if (c == '-') {
      ++sign;
      continue;
    }

    /* digit */
    if ((d = rf_digit(b, c)) == 0xFF) {
      break;
    }

    l *= b;
    l += d;
  }

  return sign ? -l : l;
}

/* find a definition */
static char __FASTCALL__ *rf_inst_find_string(char *t)
{
  return rf_find(t, rf_inst_strlen(t), rf_inst_latest());
}

/* COMPILE */
static void __FASTCALL__ rf_inst_compile(char *name)
{
  char *p;

  for (;;) {
    /* read until space or null */
    for (p = name; *p != ' ' && *p != '\0'; p++) { }

    /* compile word */
    rf_inst_comma((uintptr_t) rf_cfa(rf_find(name, p - name, rf_inst_latest())));

    /* look for more */
    if (!*p) break;
    name = ++p;
  }
}

/* COMPILE */
static void rf_inst_code_compile(void)
{
  RF_START;
  {
    uintptr_t *a;

    /* ?COMP */
    /* R> */
    a = RF_IP_GET;
    /* DUP rcll + >R */
    RF_IP_INC;
    /* @ , */
    rf_inst_comma(*a);
  }
  RF_JUMP_NEXT;
}

/* IMMEDIATE */
static void rf_inst_immediate(void)
{
  *(rf_inst_latest()) ^= 0x40;
}

#define rf_inst_qstack()

/* INTERPRET */
static void rf_inst_code_interpret_word(void)
{
  RF_START;
  {
    uintptr_t found;
    uintptr_t len;
    uintptr_t *pfa;
    intptr_t number;

    /* BEGIN (outside this in inst time version of INTERPRET) */
    
    /* -FIND  */
    found = RF_SP_POP;

    /* IF  */
    if (found) {
      len = RF_SP_POP;
      pfa = (uintptr_t *) RF_SP_POP;

      /* STATE @ < IF  */
      if (len < RF_USER_STATE) {
        /* CFA , */
        rf_inst_comma((uintptr_t) ((uintptr_t *) pfa - 1));
      } else {
        /* ELSE CFA EXECUTE */
        rf_w = (rf_code_t *) ((uintptr_t *) pfa - 1);
        RF_JUMP(*rf_w);
        return;
      }
      /* ENDIF */
      /* ?STACK */
      rf_inst_qstack();
    } else {
      /* ELSE */
      /* HERE NUMBER */
      number = rf_inst_number((char *) RF_USER_DP + 1);

      /* DPL @ 1+ IF */
      /* [COMPILE] DLITERAL  */
      /* ELSE  */
      /* DROP [COMPILE] LITERAL  */
      if (RF_USER_STATE) {
        rf_inst_compile("LIT");
        rf_inst_comma((uintptr_t) number);
      } else {
        RF_SP_PUSH(number); 
      }
      /* ENDIF  */
      /* ?STACK  */
      rf_inst_qstack();
    }
    /* ENDIF AGAIN */
  }
  RF_JUMP_NEXT;
}

/* DECIMAL */
static void rf_inst_code_decimal(void)
{
  RF_START;
  RF_USER_BASE = 10;
  RF_JUMP_NEXT;
}

/* compile a LIT value */
static void __FASTCALL__ rf_inst_compile_lit(uintptr_t literal)
{
  rf_inst_compile("LIT");
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
    uintptr_t number;
    
    number = *((uintptr_t *) rf_w + 1);
    if (RF_USER_STATE) {
      rf_inst_compile_lit(number);
    } else {
      RF_SP_PUSH(number); 
    }
  }
  RF_JUMP_NEXT;
}

/* compile an inst time literal */
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

/* If required, put inst time definitions in spare memory and unlink them when finished */
#ifdef RF_INST_OVERWRITE
/* NB 3000 may be tight with more extensions */
#define RF_INST_DICTIONARY (RF_ORIGIN + (3000*RF_WORD_SIZE))
#else
#define RF_INST_DICTIONARY (RF_ORIGIN)
#endif

#define RF_FIGRELFIGREV 0x0101 /* 1.1 */
/* IMPLEMENTATION ATTRIBUTES */
/* B +ORIGIN   ...W:IEBA */
/* W: 0=above sufficient 1=other differences exist */
/* I: Interpreter is	0=pre- 1=post incrementing */
/* E: Addr must be even: 0 yes 1 no */
/* B: High byte @	0=low addr. 1=high addr. */
/* A: CPU Addr.		0=BYTE 1=WORD */
/* USRVER = r for retro */
#ifdef RF_LE
#define RF_USRVERATTR 0x0E72
#else
#define RF_USRVERATTR 0x0C72
#endif

/* location for CURRENT and CONTEXT during inst */
static uintptr_t *rf_inst_vocabulary = 0;

static void rf_inst_cold(void)
{
  /* 0C +ORIGIN LDA, 'T FORTH 4 + STA, ( FORTH VOCAB. ) */
  /* 0D +ORIGIN LDA, 'T FORTH 5 + STA, */
  rf_inst_vocabulary = 0;

  /* set UP and user vars */
  rf_up = (uintptr_t *) RF_USER;

  /* USER */

  /* BEGIN, 0C +ORIGIN ,Y LDA, ( FROM LITERAL AREA ) */
  /* UP )Y STA, ( TO USER AREA ) */
  /* DEY, 0< END, */
  RF_USER_S0 = (uintptr_t) RF_S0;
  RF_USER_R0 = (uintptr_t) RF_R0;
  RF_USER_TIB = (uintptr_t) RF_TIB;
  RF_USER_WIDTH = 31;
  RF_USER_WARNING = 0;

  RF_USER_FENCE = (uintptr_t) RF_INST_DICTIONARY;
  RF_USER_DP = (uintptr_t) RF_INST_DICTIONARY;
  RF_USER_VOCLINK = 0;

  /* jump to RP! then to ABORT */
  /* 'T ABORT 100 /MOD # LDA, IP 1+ STA, */
  /* # LDA, IP STA, */
  /* 6C # LDA, W 1 - STA, 'T RP! JMP, ( RUN ) */
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
  /*  0 BLK ! */
  RF_USER_BLK = 0;
  /*  [COMPILE] [ */
  RF_USER_STATE = 0;
  /* ...etc */
}

/* Table of inst time code addresses */

typedef struct rf_inst_code_t {
  char *name;
  rf_code_t value;
} rf_inst_code_t;

#define RF_INST_CODE_LIT_LIST_SIZE 62

static rf_inst_code_t rf_inst_code_lit_list[] = {
  { 0, rf_code_rcll },
  { 0, rf_code_rcls },
  { 0, rf_code_rcod },
  { 0, rf_code_rlns },
  { 0, rf_code_rtgt },
  { 0, rf_code_rxit },
  { "lit", rf_code_lit },
  { "exec", rf_code_exec },
  { "bran", rf_code_bran },
  { "zbran", rf_code_zbran },
  { "xloop", rf_code_xloop },
  { "xploo", rf_code_xploo },
  { "xdo", rf_code_xdo },
  { "digit", rf_code_digit },
  { "pfind", rf_code_pfind },
  { "encl", rf_code_encl },
  { "emit", rf_code_emit },
#ifdef RF_INST_SILENT
  { "emitsilent", rf_code_drop },
#else
  { "emitsilent", rf_code_emit },
#endif
  { "key", rf_code_key },
  { "qterm", rf_code_qterm },
  { "cr", rf_code_cr },
#ifdef RF_INST_SILENT
  { "crsilent", rf_inst_code_noop },
#else
  { "crsilent", rf_code_cr },
#endif
  { "cmove", rf_code_cmove },
  { "ustar", rf_code_ustar },
  { "uslas", rf_code_uslas },
  { "andd", rf_code_andd },
  { "orr", rf_code_orr },
  { "xorr", rf_code_xorr },
  { "spat", rf_code_spat },
  { "spsto", rf_code_spsto },
  { "rpsto", rf_code_rpsto },
  { "semis", rf_code_semis },
  { "leave", rf_code_leave },
  { "tor", rf_code_tor },
  { "fromr", rf_code_fromr },
  { "rr", rf_code_rr },
  { "zequ", rf_code_zequ },
  { "zless", rf_code_zless },
  { "plus", rf_code_plus },
  { "dplus", rf_code_dplus },
  { "minus", rf_code_minus },
  { "dminu", rf_code_dminu },
  { "over", rf_code_over },
  { "drop", rf_code_drop },
  { "swap", rf_code_swap },
  { "dup", rf_code_dup },
  { "pstor", rf_code_pstor },
  { "toggl", rf_code_toggl },
  { "at", rf_code_at },
  { "cat", rf_code_cat },
  { "store", rf_code_store },
  { "cstor", rf_code_cstor },
  { "docol", rf_code_docol },
  { "docon", rf_code_docon },
  { "dovar", rf_code_dovar },
  { "douse", rf_code_douse },
  { "dodoe", rf_code_dodoe },
  { "cold", rf_code_cold },
  { "stod", rf_code_stod },
  { "dchar", rf_code_dchar },
  { "bwrit", rf_code_bwrit },
  { "bread", rf_code_bread }
};

static void rf_inst_code_ext(void)
{
  RF_START;
  rf_inst_def_code("rcll", rf_code_rcll);
  rf_inst_def_code("rcls", rf_code_rcls);
  rf_inst_def_code("rcod", rf_code_rcod);
  rf_inst_def_code("rlns", rf_code_rlns);
  rf_inst_def_code("rtgt", rf_code_rtgt);
  rf_inst_def_code("rxit", rf_code_rxit);
  RF_JUMP_NEXT;
}

/* list of forward declared words used in inst */

#define RF_INST_CODE_LIST_SIZE 39

static rf_inst_code_t rf_inst_code_list[] = {
  { "LIT", rf_code_lit },
  { "BRANCH", rf_code_bran },
  { "0BRANCH", rf_code_zbran },
  { "(FIND)", rf_code_pfind },
  { "ENCLOSE", rf_code_encl },
  { "CMOVE", rf_code_cmove },
  { "U*", rf_code_ustar },
  { "AND", rf_code_andd },
  { "SP@", rf_code_spat },
  { ";S", rf_code_semis },
  { ">R", rf_code_tor },
  { "R>", rf_code_fromr },
  { "R", rf_code_rr },
  { "0=", rf_code_zequ },
  { "+", rf_code_plus },
  { "MINUS", rf_code_minus },
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
  { "DECIMAL", rf_inst_code_decimal },
  { "COMPILE", rf_inst_code_compile },
  { "rxit", rf_code_rxit },
  { "rcll", rf_code_rcll },
  { "rcls", rf_code_rcls },
  { "rlns", rf_code_rlns },
  { "interpret-word", rf_inst_code_interpret_word },
  { "ext", rf_inst_code_ext },
  { "prev", rf_inst_code_prev },
  { "block-cmd", rf_inst_code_block_cmd },
  { "D/CHAR", rf_code_dchar },
  { "BLOCK-READ", rf_code_bread },
  { "BLOCK-WRITE", rf_code_bwrit }
};

#ifndef RF_BS
#define RF_BS 0x007F
#endif

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

  /* inst time code field declarations */
  for (i = 0; i < RF_INST_CODE_LIST_SIZE; ++i) {
    rf_inst_code_t *code = &rf_inst_code_list[i];
    rf_inst_def_code(code->name, code->value);
  }

  /* boot time literals */
  rf_inst_def_literal("relrev", (uintptr_t) RF_FIGRELFIGREV);
  rf_inst_def_literal("ver", (uintptr_t) RF_USRVERATTR);
  rf_inst_def_literal("bs", (uintptr_t) RF_BS);
  rf_inst_def_literal("user", (uintptr_t) RF_USER);
  rf_inst_def_literal("inits0", (uintptr_t) RF_S0);
  rf_inst_def_literal("initr0", (uintptr_t) RF_R0);
  rf_inst_def_literal("tib", (uintptr_t) RF_TIB);

  /* code address literals */
  for (i = 0; i < RF_INST_CODE_LIT_LIST_SIZE; ++i) {
    rf_inst_code_t *code = &rf_inst_code_lit_list[i];
    if (code->name) {
      rf_inst_def_literal(code->name, (uintptr_t) code->value);
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

  /* inst switch literals */
#ifdef RF_INST_OVERWRITE
  rf_inst_def_literal("overwrite", 1);
#else
  rf_inst_def_literal("overwrite", 0);
#endif

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
  rf_inst_compile_lit(0x20);
  rf_inst_compile("SWAP >R OVER C! DUP");
  rf_inst_compile_lit(1);
  rf_inst_compile("+ R>");
  rf_inst_compile_lit(1);
  rf_inst_compile("- CMOVE ;S");

  /* ?DISC */
  rf_inst_colon("?DISC");
  /* SOH */
  rf_inst_compile_lit(RF_ASCII_SOH);
  rf_inst_compile("D/CHAR DROP 0BRANCH");
  rf_inst_comma(2 * RF_WORD_SIZE);
  rf_inst_compile(";S");
  /* ACK EOT, ENQ EOT */
  rf_inst_compile_lit(0);
  rf_inst_compile("D/CHAR DROP DROP ;S");

  /* BLOCK */
  rf_inst_colon("BLOCK");
  /* prev */
  rf_inst_compile("DUP prev @ - 0BRANCH");
	rf_inst_comma(15 * RF_WORD_SIZE);
  /* not prev */
  rf_inst_compile("DUP");
  /* I tt ss /dr */
  rf_inst_compile("block-cmd");
  rf_inst_compile_lit(11);
  rf_inst_compile("BLOCK-WRITE");
  /* SOH */
  rf_inst_compile("?DISC");
  /* 128 bytes */
  rf_inst_compile("prev rcll + BLOCK-READ");
  /* ACK EOT */
  rf_inst_compile("?DISC");
  /* prev = new */
  rf_inst_compile("DUP prev !");
  /* return addr */
  rf_inst_compile("DROP prev rcll + ;S");

  /* WORD */
  rf_inst_colon("WORD");
  /* block addr */
  rf_inst_compile("BLK @ BLOCK");
  /* offset by IN */
  rf_inst_compile("IN @ +");
  /* parse word */
  rf_inst_compile("SWAP ENCLOSE");
  /* clear field */
  rf_inst_compile("HERE");
  rf_inst_compile_lit(0x22);
  rf_inst_compile("BLANKS");
  /* advance IN */
  rf_inst_compile("IN +!");
  /* length */
  rf_inst_compile("OVER - >R R HERE C!");
  /* move word to field */
  rf_inst_compile("+ HERE");
  rf_inst_compile_lit(1);
  rf_inst_compile("+ R> CMOVE ;S");
 
  /* -FIND */
  rf_inst_colon("-FIND");
  rf_inst_compile_lit(32);
  rf_inst_compile("WORD HERE CONTEXT @ @ (FIND) ;S");

  /* INTERPRET */
  rf_inst_colon("INTERPRET");
  rf_inst_compile("-FIND interpret-word BRANCH");
	rf_inst_comma((uintptr_t) (-3 * RF_WORD_SIZE));

  /* CREATE */
  rf_inst_colon("CREATE");
  rf_inst_compile("-FIND 0BRANCH");
	rf_inst_comma(3 * RF_WORD_SIZE);
  rf_inst_compile("DROP DROP HERE DUP C@");
  rf_inst_compile_lit(1);
  rf_inst_compile("+ DP +! DP C@");
  rf_inst_compile_lit(0xFD);
  rf_inst_compile("- 0= DP +!");
#ifdef RF_ALIGN
  rf_inst_compile("HERE rlns DP !");
#endif
  rf_inst_compile("DUP");
  rf_inst_compile_lit(0xA0);
  rf_inst_compile("TOGGLE HERE");
  rf_inst_compile_lit(1);
  rf_inst_compile("-");
  rf_inst_compile_lit(0x80);
  rf_inst_compile("TOGGLE CURRENT @ @ HERE ! rcll DP +! CURRENT @ ! HERE rcll + HERE ! rcll DP +! ;S");

  /* LOAD */
  rf_inst_colon("LOAD");
  rf_inst_compile("BLK @ >R IN @ >R");
  rf_inst_compile_lit(0);
  rf_inst_compile("IN !");
  rf_inst_compile_lit(RF_BSCR);
  rf_inst_compile("U* DROP BLK ! INTERPRET R> IN ! R> BLK ! ;S");

  /* inst load sequence */
  rf_inst_colon("load");
  rf_inst_compile_lit(80);
  rf_inst_compile("LOAD rxit");

  /* X */  
  here = (uint8_t *) RF_USER_DP;
  rf_inst_colon("X");
  rf_inst_compile_lit(1);
  rf_inst_compile("BLK +!");
  rf_inst_compile_lit(0);
  rf_inst_compile("IN ! BLK @");
  rf_inst_compile_lit(7);
  rf_inst_compile("AND 0= 0BRANCH");
  rf_inst_comma(3 * RF_WORD_SIZE);
  rf_inst_compile("R> DROP ;S");
  here[0] = 0x81;
  here[1] = 0x80;
  rf_inst_immediate();

  /* [ */
  rf_inst_colon("[");
  rf_inst_compile_lit(0);
  rf_inst_compile("STATE ! ;S");
  rf_inst_immediate();
}

static rf_code_t *rf_inst_load_cfa = 0;

static void rf_inst_emptybuffers(void)
{
  rf_inst_memset((char *) RF_FIRST, '\0', (char *) RF_LIMIT - (char *) RF_FIRST);
}

static void rf_inst_load(void)
{
  char *nfa;

  /* initialise buffers */
  rf_inst_prev = (uintptr_t *) RF_FIRST;
  rf_inst_emptybuffers();

  /* load is the starting point */
  nfa = rf_inst_find_string("load");
  rf_inst_load_cfa = rf_cfa(nfa);

  /* initialise RP */
  RF_RP_SET((uintptr_t *) RF_USER_R0);

  /* jump to load */
  RF_IP_SET((uintptr_t *) &rf_inst_load_cfa);
  RF_JUMP(rf_next);
  rf_trampoline();
}

#ifdef RF_INST_SAVE
/* return an ASCII hex digit */
static char __FASTCALL__ rf_inst_hex(uint8_t b)
{
  return b + (b < 10 ? 48 : 55);
}

/* save the installation as hex on DR1 */
static void rf_inst_save(void)
{
  /* write to DR1 */
  unsigned int blk = 2000;
  /* start from ORG */
#ifdef RF_INST_RELINK
  char *i = (char *) RF_ORIGIN;
  char *e = (char *) RF_USER_DP;
#else
  char *i = (char *) RF_ORG;
  char *e = (char *) RF_USER_DP;
#endif
  /* write blocks to disc until HERE */
  char buf[128];
  uint8_t j;
#ifdef RF_INST_RELINK
  /* write table of code addresses */
  for (j = 0; j < RF_INST_CODE_LIT_LIST_SIZE; j++) {
    *((rf_code_t *) e) = rf_inst_code_lit_list[j].value;
    e += RF_WORD_SIZE;
  }
  /* write two links used in COLD */
  *((rf_code_t *) e) = (rf_code_t) rf_cold_forth;
  e += RF_WORD_SIZE;
  *((rf_code_t *) e) = (rf_code_t) rf_cold_abort;
  e += RF_WORD_SIZE;
#endif
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
  /*sleep(5);*/
#endif

  /* cold start */
  rf_inst_cold();

  /* define required words */
  rf_inst_forward();

#ifdef RF_INST_LOCAL_DISC
  rf_persci_insert(0, "orterforth.disc");
#endif

  rf_inst_load();

#ifdef RF_INST_LOCAL_DISC
  rf_persci_eject(0);
#endif

#ifdef RF_INST_SAVE
  /* save the result to disc */
  rf_inst_save();
#endif
}
