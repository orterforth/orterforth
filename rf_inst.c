#include <stdlib.h>

#include "rf.h"

/* ERROR REPORTING */

/* write a string to output */
static void __FASTCALL__ rf_inst_print(char *string)
{
  while (*string) {
    rf_out(*string++);
  }
}

/* write an error message and stop */
static void __FASTCALL__ rf_inst_error(char *string)
{
  rf_inst_print(string);
  rf_out('\n');
  exit(1);
}

/* return an ASCII hex digit */
static char __FASTCALL__ rf_inst_hex(uint8_t b)
{
  return b + (b < 10 ? 48 : 55);
}

/* write a byte in hex */
void __FASTCALL__ rf_inst_print_hex(uint8_t c)
{
  rf_out(rf_inst_hex(c >> 4));
  rf_out(rf_inst_hex(c & 15));
}

/* INST TIME DISC OPERATIONS */

/* read the next byte from disc, fail if not the expected value */
static void __FASTCALL__ rf_inst_disc_expect(char e)
{
  char c;

  rf_disc_read(&c, 1);
  if (c != e) {
    rf_inst_print("rf_inst_disc_expect failed exp=");
    rf_inst_print_hex(e);
    rf_inst_print(" act=");
    rf_inst_print_hex(c);
    rf_out('\n');
    exit(1);
  }
}

/* convert block number into drive, track and sector */
static void rf_inst_disc_blk(rf_word_t blk, unsigned char *drive, unsigned char *track, unsigned char *sector)
{
  rf_word_t blk_offset;
  
  blk_offset = blk % 2000;
  *drive = blk / 2000;
  *track = blk_offset / 26;
  *sector = (blk_offset % 26) + 1;
}

/* write two place decimal integer to disc */
static void __FASTCALL__ rf_inst_disc_puti(unsigned char i)
{
  char p[2];

  p[0] = 48 + (i / 10);
  p[1] = 48 + (i % 10);
  rf_disc_write(p, 2);
}

/* return the length of a string */
static int __FASTCALL__ rf_inst_strlen(const char *s)
{
  int i;

  for (i = 0; *(s++); ++i) {
  }
  return i;
}

/* write string to disc */
static void __FASTCALL__ rf_inst_disc_puts(char *s)
{
  rf_disc_write(s, rf_inst_strlen(s));
}

/* ASCII CONTROL CHARS */

#define RF_ASCII_SOH 1
#define RF_ASCII_EOT 4
#define RF_ASCII_ENQ 5
#define RF_ASCII_ACK 6
#define RF_ASCII_LF 10
#define RF_ASCII_CR 13
#define RF_ASCII_NAK 21

static char sp = ' ';
static char eot = RF_ASCII_EOT;

/* write PerSci disc command, I or O */
static void rf_inst_disc_cmd(char c, rf_word_t blk)
{
  unsigned char drive, track, sector;

  /* calculate params */
  rf_inst_disc_blk(blk, &drive, &track, &sector);

  /* send command */
  rf_disc_write(&c, 1);
  rf_disc_write(&sp, 1);
  rf_inst_disc_puti(track);
  rf_disc_write(&sp, 1);
  rf_inst_disc_puti(sector);
  rf_inst_disc_puts(" /");
  rf_inst_disc_puti(drive);
  rf_disc_write(&eot, 1);
  rf_disc_flush();
}

/* read block */
static void rf_inst_disc_r(char *b, rf_word_t blk)
{
  /* send command */
  rf_inst_disc_cmd('I', blk);

  /* get response */
  rf_inst_disc_expect(RF_ASCII_SOH);
  rf_disc_read(b, RF_BBLK);
  rf_inst_disc_expect(RF_ASCII_ACK);
  rf_inst_disc_expect(RF_ASCII_EOT);
}

/* write block */
#ifdef RF_INST_SAVE
static void rf_inst_disc_w(char *b, rf_word_t blk)
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
  rf_disc_flush();

  /* get response */
  rf_inst_disc_expect(RF_ASCII_ACK);
  rf_inst_disc_expect(RF_ASCII_EOT);
}
#endif

/* INST TIME CODE */

/* fails with "notimpl" if called */
static void rf_inst_code_notimpl(void)
{
  RF_START;
  rf_inst_error("notimpl");
}

/* flag to indicate completion of install */
extern char rf_installed;

/* use to validate calls that are made post inst */
#define RF_INST_ONLY

/* empty assert */
#define assert(a)

/* do nothing */
static void rf_inst_code_noop(void)
{
  RF_START;
  RF_INST_ONLY;
  RF_JUMP_NEXT;
}

/* !CSP */
static void rf_inst_code_storecsp(void)
{
  RF_START;
  RF_INST_ONLY;
  RF_USER_CSP = (rf_word_t) RF_SP_GET;
  RF_JUMP_NEXT;
}

/* USE */
static rf_word_t *rf_inst_use;

/* PREV */
static rf_word_t *rf_inst_prev;

/* +BUF */
static rf_word_t __FASTCALL__ *rf_inst_pbuf(rf_word_t *p)
{
  p = (rf_word_t *) (((rf_word_t) p) + RF_DISC_BUFFER_SIZE);
  if (p == (rf_word_t *) RF_LIMIT) {
    p = (rf_word_t *) RF_FIRST;
  }
  return p;
}

/* BUFFER */
static char __FASTCALL__ *rf_inst_buffer(rf_word_t block)
{
  /* USE @ DUP >R ( BUFFER ADDRESS TO BE ASSIGNED ) */
  rf_word_t *p = rf_inst_use;

  /* BEGIN */
  do {
    /* +BUF */
    p = rf_inst_pbuf(p);
    /* UNTIL ( AVOID PREV ) */
  } while (p == rf_inst_prev);
  /* USE ! ( FOR NEXT TIME ) */
  rf_inst_use = p;
  /* R @ 0< ( TEST FOR UPDATE IN THIS BUFFER ) IF ( UPDATED, FLUSH TO DISC ) */
  if (*p & 0x8000) {
    /* R 2+ ( STORAGE LOC. ) */
    /* R @ 7FFF AND ( ITS BLOCK # ) */
    /* 0 R/W ( WRITE SECTOR TO DISC ) */
    rf_inst_error("inst disc write not impl");
    /* ENDIF */
  }
  /* R ! ( WRITE NEW BLOCK # INTO THIS BUFFER ) */
  *p = block;
  /* R PREV ! ( ASSIGN THIS BUFFER AS 'PREV' ) */
  rf_inst_prev = p;
  /* R> 2+ ( MOVE TO STORAGE LOCATION ) */
  return ((char *) p) + RF_WORD_SIZE;
}

/* BLOCK */
static char __FASTCALL__ *rf_inst_block(rf_word_t block)
{
  rf_word_t *p;

  /* OFFSET @ + >R   ( RETAIN BLOCK # ON RETURN STACK ) */
  block += RF_USER_OFFSET;
  /* PREV @ DUP @ R - DUP + ( BLOCK = PREV ? ) IF ( NOT PREV ) */
  if (block != *rf_inst_prev) {
    p = rf_inst_prev;
    /* BEGIN */
    do {
      /* +BUF */
      p = rf_inst_pbuf(p);
      /* 0= ( TRUE UPON REACHING 'PREV' ) IF ( WRAPPED ) */
      if (p == rf_inst_prev) {
        /* DROP R BUFFER */
        char *s = rf_inst_buffer(block);
        /* DUP R 1 R/W ( READ SECTOR FROM DISC ) */
        rf_inst_disc_r(s, block);
        /* 2 - ( BACKUP ) */
        p = (rf_word_t *) ((char *) (s - RF_WORD_SIZE));
        /* ENDIF */
      }
      /* DUP @ R - DUP + 0= UNTIL ( WITH BUFFER ADDRESS ) */
    } while (block != *p);
    /* DUP PREV ! */
    rf_inst_prev = p;
    /* ENDIF */
  }
  /* R> DROP 2+ */
  return ((char *) rf_inst_prev) + RF_WORD_SIZE;
}

/* replaces memcpy */
static void rf_inst_memcpy(char *dst, char *src, unsigned char length)
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

/* WORD */
static void __FASTCALL__ rf_inst_word(unsigned char c)
{
  unsigned char length;
  char *here;
  char *addr1;
  unsigned char n1, n2, n3;

  /* BLK @ IF BLK @ BLOCK ELSE TIB @ ENDIF */
  /* IN @ + */
  addr1 = (RF_USER_BLK ? rf_inst_block(RF_USER_BLK) : ((char *) RF_USER_TIB)) + RF_USER_IN;

  /* SWAP ENCLOSE */
  rf_enclose(c, addr1, &n1, &n2, &n3);

  /* HERE 22 BLANKS */
  here = (char *) RF_USER_DP;
  rf_inst_memset(here, ' ', 34);

  /* IN +! */
  RF_USER_IN += n3;

  /* OVER  -  >R ( SAVE CHAR COUNT ) */
  length = n2 - n1;
  /* R HERE C! ( LENGTH STORED FIRST ) */
  here[0] = length;

  /* + HERE 1+ R> CMOVE */
  rf_inst_memcpy(here + 1, addr1 + n1, length);
}

/* BLOCK */
static void rf_inst_code_block(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    char *p = rf_inst_block(RF_SP_POP);
    RF_SP_PUSH((rf_word_t) p);
  }
  RF_JUMP_NEXT;
}

/* WORD */
void rf_inst_code_word(void)
{
  RF_START;
  RF_INST_ONLY;
  rf_inst_word(RF_SP_POP);
  RF_JUMP_NEXT;
}

static void __FASTCALL__ rf_inst_comma(rf_word_t word)
{
  rf_word_t *dp;

  dp = (rf_word_t *) RF_USER_DP;
  *dp = word;
  RF_USER_DP = (rf_word_t) (dp + 1);
}

/* LATEST */
static char *rf_inst_latest(void)
{
  return *((char **) RF_USER_CURRENT);
}

/* CREATE */
static void rf_inst_create(unsigned char length, char *address)
{
  char *here;
  char *p;

  /* below assumes word already written to HERE */
  here = (char *) RF_USER_DP;
  here[0] = length;
  rf_inst_memcpy(here + 1, address, length);

  /* TIB HERE 0A0 + < 2 ?ERROR */
  assert(RF_USER_TIB - (rf_word_t) here >= 0xA0);
  /* TODO address of TIB not value; instead use a portable dictionary limit */

  /* -FIND IF DROP NFA ID. 4 MESSAGE SPACE ENDIF  */
  /* not important at inst time */

  /* HERE DUP C@ WIDTH @ MIN 1+ ALLOT make space */
  p = here;
  p += length + 1;
  /* 6502 bug workaround */
  /* DP C@ 0FD = ALLOT */
  if (((rf_word_t) p & 0xFF) == 0xFD) {
    /* *p = 0; */
    ++p;
  }
  RF_USER_DP = (rf_word_t) p;

  /* DUP A0 TOGGLE  */
  here[0] ^= 0xA0;

  /* HERE 1 - 80 TOGGLE */
  *(--p) ^= 0x80;

  /* LATEST ,  */
  rf_inst_comma((rf_word_t) rf_inst_latest());

  /* CURRENT @ !  */
  *((char **) RF_USER_CURRENT) = here;
}

/* CREATE */
static void rf_inst_code_create(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    char *here;

    rf_inst_word(32);
    here = (char *) RF_USER_DP;
    rf_inst_create(here[0], here + 1);

    /* HERE 2+ , */
    rf_inst_comma((rf_word_t) ((rf_word_t *) RF_USER_DP + 1));
  }
  RF_JUMP_NEXT;
}

/* -FIND */
static char *rf_inst_hfind(void)
{
  RF_INST_ONLY;
  {
    char *here;
    char *nfa;

    /* BL WORD */
    rf_inst_word(32);
    /* HERE */
    here = (char *) RF_USER_DP;
    /* CONTEXT @ @ (FIND) */
    nfa = rf_find(here + 1, here[0], *((char **) RF_USER_CONTEXT));
    /* DUP 0= IF */
    if (!nfa) {
      /* DROP HERE LATEST (FIND) */
      nfa = rf_find(here + 1, here[0], rf_inst_latest());
    }
    /* ENDIF */
    return nfa;
  }
}

/* create and smudge */
static void __FASTCALL__ rf_inst_def(char *name)
{
  rf_inst_create(rf_inst_strlen(name), name);
  /* un-smudge */
  *(rf_inst_latest()) ^= 0x20;
}

/* [COMPILE] */
static void rf_inst_code_bcompile(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    /* FIND */
    char *nfa = rf_inst_hfind();
    /* 0 ?ERROR */
    assert(nfa); /* 0= 0 ?ERROR */
    /* DROP */
    /* CFA , */
    rf_inst_comma((rf_word_t) rf_cfa(nfa));
  }
  RF_JUMP_NEXT;
}

/* NUMBER */
static long __FASTCALL__ rf_inst_number(char *t) {

  long sign;
  long l;
  int c;
  unsigned char d;

  RF_INST_ONLY;
  sign = 1;
  l = 0;
  while (1) {
    c = *(t++);

    /* sign */
    if (c == '-') {
      sign = -sign;
      continue;
    }

    /* digit */
    if ((d = rf_digit(RF_USER_BASE, c)) == 255) {
      break;
    }

    l *= RF_USER_BASE;
    l += d;
  }

  return l * sign;
}

/* X */
static void rf_inst_code_x(void)
{
  RF_START;
  RF_INST_ONLY;
  /* BLK @ IF */
  if (RF_USER_BLK) {
    /* 1 BLK +! */
    RF_USER_BLK++;
    /* 0 IN ! */
    RF_USER_IN = 0;
    /* BLK @ 7 AND 0= IF */
    if (!(RF_USER_BLK & 7)) {
      /* ?EXEC R> DROP */
      assert(!RF_USER_STATE);
      RF_IP_SET((rf_word_t *) RF_RP_POP);
    /* ENDIF */
    }
  /* ELSE */
  } else {
    /* R> DROP */
    RF_IP_SET((rf_word_t *) RF_RP_POP);
  /* ENDIF */
  }
  RF_JUMP_NEXT;
}

/* SMUDGE */
static void rf_inst_code_smudge(void)
{
  RF_START;
  RF_INST_ONLY;
  /* LATEST 20 TOGGLE */
  *(rf_inst_latest()) ^= 0x20;
  RF_JUMP_NEXT;
}

/* CODE */
static void rf_inst_code_code(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    char *here;

    rf_inst_word(32);
    here = (char *) RF_USER_DP;
    rf_inst_create(here[0], here + 1);

    /* HERE 2+ , */
    rf_inst_comma((rf_word_t) ((rf_word_t *) RF_USER_DP + 1));

    /* LATEST 20 TOGGLE */
    *(rf_inst_latest()) ^= 0x20;
  }
  RF_JUMP_NEXT;
}

/* ?PAIRS */
static void __FASTCALL__ rf_inst_qpairs(rf_word_t a)
{
  rf_word_t b;

  b = RF_SP_POP;
  assert(a == b);
  if (a != b) {
    rf_inst_error("?PAIRS failed");
  }
}

/* ENDIF */
static void rf_inst_endif(void)
{
  rf_word_t a;
  intptr_t o;

  /* ?COMP */
  assert(RF_USER_STATE);
  /* 2 ?PAIRS */
  rf_inst_qpairs(2);
  /* HERE OVER - SWAP */
  a = RF_SP_POP;
  o = (intptr_t) (RF_USER_DP - a);
  /* ! */
  *((intptr_t *) a) = o;
}

/* ENDIF */
static void rf_inst_code_endif(void)
{
  RF_START;
  RF_INST_ONLY;
  rf_inst_endif();
  RF_JUMP_NEXT;
}

/* HERE */
static void rf_inst_here(void)
{
  RF_SP_PUSH(RF_USER_DP);
}

/* find a definition */
static char __FASTCALL__ *rf_inst_find_string(char *t)
{
  return rf_find(t, rf_inst_strlen(t), rf_inst_latest());
}

/* COMPILE */
static void __FASTCALL__ rf_inst_compile(char *name)
{
	rf_inst_comma((rf_word_t) rf_cfa(rf_inst_find_string(name)));
}

/* IF */
static void rf_inst_code_if(void)
{
  RF_START;
  RF_INST_ONLY;
  /* COMPILE 0BRANCH */
  rf_inst_compile("0BRANCH");
  /* HERE */
  rf_inst_here();
  /* 0 , */
  rf_inst_comma(0);
  /* 2 */
  RF_SP_PUSH(2);
  RF_JUMP_NEXT;
}

/* ELSE */
static void rf_inst_code_else(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    rf_word_t a;
    rf_word_t b;

    /* 2 ?PAIRS */
    rf_inst_qpairs(2);
    /* COMPILE BRANCH */
    rf_inst_compile("BRANCH");
    /* HERE */
    rf_inst_here();
    /* 0 , */
    rf_inst_comma(0);
    /* SWAP */
    a = RF_SP_POP;
    b = RF_SP_POP;
    RF_SP_PUSH(a);
    RF_SP_PUSH(b);
    /* 2 */
    RF_SP_PUSH(2);
    /* [COMPILE] ENDIF */
    rf_inst_endif();
    /* 2 */
    RF_SP_PUSH(2);
  }
  RF_JUMP_NEXT;
}

/* BACK */
static void rf_inst_back(void)
{
  /* HERE */
  rf_word_t b = RF_USER_DP;
  /* - */
  intptr_t c = RF_SP_POP - b;
  /* , */
  rf_inst_comma(c);
}

/* BEGIN */
static void rf_inst_code_begin(void)
{
  RF_START;
  RF_INST_ONLY;
  /* ?COMP */
  assert(RF_USER_STATE);
  /* HERE */
  rf_inst_here();
  /* 1 */
  RF_SP_PUSH(1);
  RF_JUMP_NEXT;
}

/* WHILE */
static void rf_inst_code_while(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    rf_word_t n;

    /* [COMPILE] IF */
    rf_inst_compile("0BRANCH");
    rf_inst_here();
    rf_inst_comma(0);
    RF_SP_PUSH(2);
    /* 2+ */
    n = RF_SP_POP;
    RF_SP_PUSH(n + 2);
  }
  RF_JUMP_NEXT;
}

/* AGAIN */
static void rf_inst_again(void)
{
  /* 1 ?PAIRS */
  rf_inst_qpairs(1);
  /* COMPILE BRANCH */
  rf_inst_compile("BRANCH");
  /* BACK */
  rf_inst_back();
}

/* AGAIN */
static void rf_inst_code_again(void)
{
  RF_START;
  RF_INST_ONLY;
  rf_inst_again();
  RF_JUMP_NEXT;
}

/* REPEAT */
static void rf_inst_code_repeat(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    rf_word_t x;

    /* >R */
    RF_RP_PUSH(RF_SP_POP);
    /* >R */
    RF_RP_PUSH(RF_SP_POP);
    /* [COMPILE] AGAIN */
    rf_inst_again();
    /* R> */
    RF_SP_PUSH((rf_word_t) RF_RP_POP);
    /* R> */
    RF_SP_PUSH((rf_word_t) RF_RP_POP);
    /* 2 - */
    x = RF_SP_POP;
    assert(x == 4);
    RF_SP_PUSH(x - 2);
    /* [COMPILE] ENDIF */
    rf_inst_endif();
  }
  RF_JUMP_NEXT;
}

/* DO */
static void rf_inst_code_do(void)
{
  RF_START;
  RF_INST_ONLY;
  /* COMPILE (DO) */
  rf_inst_compile("(DO)");
  /* HERE */
  rf_inst_here();
  /* 3 */
  RF_SP_PUSH(3);
  RF_JUMP_NEXT;
}

/* LOOP */
static void rf_inst_code_loop(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    /* 3 ?PAIRS */
    rf_inst_qpairs(3);
    /* COMPILE (LOOP) */
    rf_inst_compile("(LOOP)");
    /* BACK */
    rf_inst_back();
  }
  RF_JUMP_NEXT;
}

/* UNTIL */
static void rf_inst_code_until(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    /* 1 ?PAIRS */
    rf_inst_qpairs(1);
    /* COMPILE 0BRANCH */
    rf_inst_compile("0BRANCH");
    /* BACK */
    rf_inst_back();
  }
  RF_JUMP_NEXT;
}

/* COMPILE */
static void rf_inst_code_compile(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    rf_word_t *a;

    /* ?COMP */
    assert(RF_USER_STATE);
    /* R> */
    a = RF_IP_GET;
    /* DUP rf-cell + >R */
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

/* IMMEDIATE */
static void rf_inst_code_immediate(void)
{
  RF_START;
  RF_INST_ONLY;
  rf_inst_immediate();
  RF_JUMP_NEXT;
}

/* ?STACK */
static void rf_inst_qstack(void)
{
  if (rf_sp > (rf_word_t *) RF_S0 || rf_sp < ((rf_word_t *) RF_S0 - RF_STACK_SIZE)) {
    rf_inst_error("stack out of bounds");
  }
}

/* INTERPRET */
static void rf_inst_code_interpret_word(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    char *nfa;
    rf_word_t number;

    /* BEGIN (outside this in inst time version of INTERPRET) */
    
    /* -FIND  */
    nfa = rf_inst_hfind();

    /* IF  */
    if (nfa) {
      /* STATE @ < IF  */
      if (*((unsigned char *) nfa) < RF_USER_STATE) {
        /* CFA , */
        rf_inst_comma((rf_word_t) rf_cfa(nfa));
      } else {
        /* ELSE CFA EXECUTE */
        rf_w = rf_cfa(nfa);
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
        rf_inst_compile(("LIT"));
        rf_inst_comma((rf_word_t) number);
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
  RF_INST_ONLY;
  RF_USER_BASE = 10;
  RF_JUMP_NEXT;
}

/* HEX */
static void rf_inst_code_hex(void)
{
  RF_START;
  RF_INST_ONLY;
  RF_USER_BASE = 16;
  RF_JUMP_NEXT;
}

/* , */
static void rf_inst_code_comma(void)
{
  RF_START;
  RF_INST_ONLY;
  rf_inst_comma(RF_SP_POP); 
  RF_JUMP_NEXT;
}

/* [ */
static void rf_inst_code_lbrac(void)
{
  RF_START;
  RF_INST_ONLY;
  RF_USER_STATE = 0;
  RF_JUMP_NEXT;
}

/* ] */
static void rf_inst_code_rbrac(void)
{
  RF_START;
  RF_INST_ONLY;
  RF_USER_STATE = 0xC0;
  RF_JUMP_NEXT;
}

/* LITERAL */
static void rf_inst_code_literal(void)
{
  RF_START;
  RF_INST_ONLY;
  /* STATE @ IF */
  if (RF_USER_STATE) {
    /* COMPILE LIT */
    rf_inst_compile("LIT");
    /* , */
    rf_inst_comma(RF_SP_POP);
    /* ENDIF */
  }
  RF_JUMP_NEXT;
}

/* +ORIGIN */
static void rf_inst_code_plusorigin(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    rf_word_t a;
    rf_word_t *origin;
    
    a = RF_SP_POP;
    origin = (rf_word_t *) RF_ORIGIN;
    RF_SP_PUSH((rf_word_t) (&origin[a / RF_WORD_SIZE]));
  }
  RF_JUMP_NEXT;
}

/* --> */
static void rf_inst_code_nexts(void)
{
  RF_START;
  RF_INST_ONLY;
  /* ?LOADING */
  assert(RF_USER_BLK);
  /* 0 IN ! */
  RF_USER_IN = 0;
  /* B/SCR BLK @ OVER MOD - BLK +! */
  RF_USER_BLK += (RF_BSCR - (RF_USER_BLK % RF_BSCR));
  RF_JUMP_NEXT;
}

/* BYTE.IN */
static void rf_inst_code_bytein(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    char *nfa;
    rf_word_t a;

    /* -FIND DROP DROP */
    nfa = rf_inst_hfind();
    assert(nfa);

    /* + */
    a = RF_SP_POP;
    RF_SP_PUSH(((rf_word_t) rf_pfa(nfa)) + a);
  }
  RF_JUMP_NEXT;
}

/* REPLACED.BY */
static void rf_inst_code_replacedby(void)
{
  RF_START;
  RF_INST_ONLY;
  {
    char *nfa;
    rf_word_t *a;

    /* -FIND DROP DROP */
    nfa = rf_inst_hfind();
    assert(nfa);

    /* CFA SWAP ! */
    a = (rf_word_t *) RF_SP_POP;
    *a = (rf_word_t) rf_cfa(nfa);
  }
  RF_JUMP_NEXT;
}

/* compile a LIT value */
static void __FASTCALL__ rf_inst_compile_lit(rf_word_t literal)
{
  rf_inst_compile("LIT");
	rf_inst_comma(literal);
}

/* compile a definition and set CFA */
static void rf_inst_def_code(char *name, rf_code_t code)
{
  rf_inst_def(name);
  rf_inst_comma((rf_word_t) code);
}

/* compile an immediate definition and set CFA */
static void rf_inst_def_code_immediate(char *name, rf_code_t code)
{
  rf_inst_def(name);
  rf_inst_comma((rf_word_t) code);
  rf_inst_immediate();
}

/* compile a colon definition */
static void __FASTCALL__ rf_inst_colon(char *name)
{
  rf_inst_def(name);
  rf_inst_comma((rf_word_t) rf_code_docol);
}

/* inst time literal code */
static void rf_inst_code_doliteral(void)
{
  RF_START;
  {
    rf_word_t number;
    
    number = *((rf_word_t *) rf_w + 1);
    if (RF_USER_STATE) {
      rf_inst_compile_lit(number);
    } else {
      RF_SP_PUSH(number); 
    }
  }
  RF_JUMP_NEXT;
}

/* compile an inst time literal */
static void rf_inst_def_literal(char *name, rf_word_t value)
{
  rf_inst_def(name);
  rf_inst_comma((rf_word_t) rf_inst_code_doliteral);
  rf_inst_comma(value);
  rf_inst_immediate();
}

/* compile a user variable */
/* still needed for fwd decls of CURRENT and CONTEXT */
static void rf_inst_def_user(char *name, unsigned int idx)
{
  rf_inst_def(name);
  rf_inst_comma((rf_word_t) rf_code_douse);
  rf_inst_comma(idx * RF_WORD_SIZE);
}

/* If required, put inst time definitions in spare memory and unlink them when finished */
#ifdef RF_INST_OVERWRITE
/* NB 3000 may be tight with more extensions */
#define RF_INST_DICTIONARY (RF_ORIGIN + (3000*RF_WORD_SIZE))
#else
#define RF_INST_DICTIONARY (RF_ORIGIN)
#endif

#define RF_FIGREL 0x01 /* 1.1 */
#define RF_FIGREV 0x01
#define RF_USRVER 0x72 /* r for retro */

static uint8_t rf_inst_attr(void)
{
  uint8_t p;

  /* IMPLEMENTATION ATTRIBUTES */
  /* B +ORIGIN   ...W:IEBA */
  /* W: 0=above sufficient 1=other differences exist */
  p = 0x00;
  /* I: Interpreter is	0=pre- 1=post incrementing */
  p |= 0x08;
  /* E: Addr must be even: 0 yes 1 no */
  p |= 0x04;
  /* B: High byte @	0=low addr. 1=high addr. */
#ifdef RF_LE
  p |= 0x02;
#endif
  /* A: CPU Addr.		0=BYTE 1=WORD */

  return p;
}

/* location for CURRENT and CONTEXT during inst */
rf_word_t *rf_inst_vocabulary = 0;

static void rf_inst_cold(void)
{
  /* 0C +ORIGIN LDA, 'T FORTH 4 + STA, ( FORTH VOCAB. ) */
  /* 0D +ORIGIN LDA, 'T FORTH 5 + STA, */
  rf_inst_vocabulary = 0;

  /* set UP and user vars */
  rf_up = (rf_word_t *) RF_USER;

  /* USER */

  /* BEGIN, 0C +ORIGIN ,Y LDA, ( FROM LITERAL AREA ) */
  /* UP )Y STA, ( TO USER AREA ) */
  /* DEY, 0< END, */
  RF_USER_S0 = (rf_word_t) RF_S0;
  RF_USER_R0 = (rf_word_t) RF_R0;
  RF_USER_TIB = (rf_word_t) RF_TIB;
  RF_USER_WIDTH = 31;
  RF_USER_WARNING = 0;

  RF_USER_FENCE = (rf_word_t) RF_INST_DICTIONARY;
  RF_USER_DP = (rf_word_t) RF_INST_DICTIONARY;
  RF_USER_VOCLINK = 0;

  /* jump to RP! then to ABORT */
  /* 'T ABORT 100 /MOD # LDA, IP 1+ STA, */
  /* # LDA, IP STA, */
  /* 6C # LDA, W 1 - STA, 'T RP! JMP, ( RUN ) */
  RF_RP_SET((rf_word_t *) RF_USER_R0);

  /* : ABORT */
  /* SP! */
  RF_SP_SET((rf_word_t *) RF_USER_S0);
  /* DECIMAL */
  RF_USER_BASE = 10;
  /* DR0 */
  RF_USER_OFFSET = 0;
  /* CR ." FORTH-65 V 4.0" */
  /* [COMPILE] FORTH */
  RF_USER_CONTEXT = (rf_word_t) &rf_inst_vocabulary;
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

#define RF_INST_CODE_LIT_LIST_SIZE 54

static rf_inst_code_t rf_inst_code_lit_list[] = {
  { "inst-lit", rf_code_lit },
  { "inst-exec", rf_code_exec },
  { "inst-bran", rf_code_bran },
  { "inst-zbran", rf_code_zbran },
  { "inst-xloop", rf_code_xloop },
  { "inst-xploo", rf_code_xploo },
  { "inst-xdo", rf_code_xdo },
  { "inst-digit", rf_code_digit },
  { "inst-pfind", rf_code_pfind },
  { "inst-encl", rf_code_encl },
#ifdef RF_INST_SILENT
  { "inst-emit", rf_code_drop },
#else
  { "inst-emit", rf_code_emit },
#endif
  { "inst-key", rf_code_key },
  { "inst-qterm", rf_code_qterm },
#ifdef RF_INST_SILENT
  { "inst-cr", rf_inst_code_noop },
#else
  { "inst-cr", rf_code_cr },
#endif
  { "inst-cmove", rf_code_cmove },
  { "inst-ustar", rf_code_ustar },
  { "inst-uslas", rf_code_uslas },
  { "inst-andd", rf_code_andd },
  { "inst-orr", rf_code_orr },
  { "inst-xorr", rf_code_xorr },
  { "inst-spat", rf_code_spat },
  { "inst-spsto", rf_code_spsto },
  { "inst-rpsto", rf_code_rpsto },
  { "inst-semis", rf_code_semis },
  { "inst-leave", rf_code_leave },
  { "inst-tor", rf_code_tor },
  { "inst-fromr", rf_code_fromr },
  { "inst-rr", rf_code_rr },
  { "inst-zequ", rf_code_zequ },
  { "inst-zless", rf_code_zless },
  { "inst-plus", rf_code_plus },
  { "inst-dplus", rf_code_dplus },
  { "inst-minus", rf_code_minus },
  { "inst-dminu", rf_code_dminu },
  { "inst-over", rf_code_over },
  { "inst-drop", rf_code_drop },
  { "inst-swap", rf_code_swap },
  { "inst-dup", rf_code_dup },
  { "inst-pstor", rf_code_pstor },
  { "inst-toggl", rf_code_toggl },
  { "inst-at", rf_code_at },
  { "inst-cat", rf_code_cat },
  { "inst-store", rf_code_store },
  { "inst-cstor", rf_code_cstor },
  { "inst-docol", rf_code_docol },
  { "inst-docon", rf_code_docon },
  { "inst-dovar", rf_code_dovar },
  { "inst-douse", rf_code_douse },
  { "inst-dodoe", rf_code_dodoe },
  { "inst-cold", rf_code_cold },
  { "inst-stod", rf_code_stod },
  { "inst-dchar", rf_code_dchar },
  { "inst-bwrit", rf_code_bwrit },
  { "inst-bread", rf_code_bread }
};

/* list of forward declared words that will fail until replaced later */

#define RF_INST_NOTIMPL_LIST_SIZE 7

static char *rf_inst_notimpl_list[] = {
  /* used in ?ERROR */
  "ERROR",
  /* used in (ABORT) */
  "ABORT",
  /* used in ERROR */
  "MESSAGE",
  "QUIT",
  /* used in CREATE */
  "MIN",
  /* used in ABORT */
  "DR0",
  /* used in BUFFER, BLOCK */
  "R/W"
};

/* list of forward declared words used in inst */

#define RF_INST_CODE_LIST_SIZE 27

static rf_inst_code_t rf_inst_code_list[] = {
  /* used from the start */
  { "CODE", rf_inst_code_code },
  /* used in ( */
  { ";S", rf_code_semis },
  /* used in ." , also ( */
  { "WORD", rf_inst_code_word },
  { "LIT", rf_code_lit },
  /* DECIMAL, HEX */
  { "DECIMAL", rf_inst_code_decimal },
  { "HEX", rf_inst_code_hex },
  /* : ; are the next to be called */
  { "IMMEDIATE", rf_inst_code_immediate },
  /* used in MESSAGE */
  { ".", rf_code_drop },
  /* used in WORD */
  { "BLOCK", rf_inst_code_block },
  /* interpret loop */
  { "inst-interpret-word", rf_inst_code_interpret_word },
  { "BRANCH", rf_code_bran },
  /* used in CONSTANT, : */
  { "CREATE", rf_inst_code_create },  
  /* : */
  { "?EXEC", rf_inst_code_noop },
  { "!CSP", rf_inst_code_storecsp },
  /* rf_inst_def_user uses this as well as makeshift : */
  { "+", rf_code_plus },
  { "@", rf_code_at },
  { "!", rf_code_store },
  { "]", rf_inst_code_rbrac },
  /* ; */
  { "COMPILE", rf_inst_code_compile },
  { "SMUDGE", rf_inst_code_smudge },
  { "?CSP", rf_inst_code_noop },
  { ",", rf_inst_code_comma },
  /* --> */
  { "-->", rf_inst_code_nexts },
  /* used by +ORIGIN itself */
  { "+ORIGIN", rf_inst_code_plusorigin },
  /* resolving forward declarations */
  { "BYTE.IN", rf_inst_code_bytein },
  { "REPLACED.BY", rf_inst_code_replacedby },
  /* inst-load */
  { "rf-exit", rf_code_exit }
};

static void rf_inst_code_ext(void)
{
  RF_START;
  RF_INST_ONLY;
  rf_inst_def_code("rf-cell", rf_code_cell);
  rf_inst_def_code("rf-cells", rf_code_cells);
  rf_inst_def_code("rf-code", rf_code_code);
  rf_inst_def_code("rf-exit", rf_code_exit);
  rf_inst_def_code("rf-target", rf_code_target);
  RF_JUMP_NEXT;
}

#ifdef SPECTRUM
#define RF_BS 0x000C
#else
#define RF_BS 0x007F
#endif

static void rf_inst_forward(void)
{
  int i;
  unsigned char *here;

  /* boot time literals */
  rf_inst_def_literal("inst-relrev", (rf_word_t) (RF_FIGREL | (RF_FIGREV << 8)));
  rf_inst_def_literal("inst-ver", (rf_word_t) (RF_USRVER | (rf_inst_attr() << 8)));
  rf_inst_def_literal("inst-bs", (rf_word_t) RF_BS);
  rf_inst_def_literal("inst-user", (rf_word_t) RF_USER);
  rf_inst_def_literal("inst-inits0", (rf_word_t) RF_S0);
  rf_inst_def_literal("inst-initr0", (rf_word_t) RF_R0);
  rf_inst_def_literal("inst-tib", (rf_word_t) RF_TIB);

  /* orterforth extension words compiled inline after boot up literals */
  rf_inst_def_code("inst-ext", rf_inst_code_ext);

  /* inst time code field declarations */
  for (i = 0; i < RF_INST_CODE_LIST_SIZE; ++i) {
    rf_inst_code_t *code = &rf_inst_code_list[i];
    rf_inst_def_code(code->name, code->value);
  }

  /* disc buffer literals */
  rf_inst_def_literal("inst-first", (rf_word_t) RF_FIRST);
  rf_inst_def_literal("inst-limit", (rf_word_t) RF_LIMIT);

  /* ( */
  /* rf_inst_compile("LIT"); */
  rf_inst_colon("(");
  rf_inst_compile_lit(0x29);
  rf_inst_compile("WORD");
  rf_inst_compile(";S");
  rf_inst_immediate();

  /* control structures, compile time */
  rf_inst_def_code_immediate("ENDIF", rf_inst_code_endif);
  rf_inst_def_code_immediate("IF", rf_inst_code_if);
  rf_inst_def_code_immediate("ELSE", rf_inst_code_else);
  rf_inst_def_code_immediate("BEGIN", rf_inst_code_begin);
  rf_inst_def_code_immediate("WHILE", rf_inst_code_while);
  rf_inst_def_code_immediate("REPEAT", rf_inst_code_repeat);
  rf_inst_def_code_immediate("UNTIL", rf_inst_code_until);
  rf_inst_def_code_immediate("AGAIN", rf_inst_code_again);
  rf_inst_def_code_immediate("DO", rf_inst_code_do);
  rf_inst_def_code_immediate("LOOP", rf_inst_code_loop);

  /* forward declarations not yet implemented */
  for (i = 0; i < RF_INST_NOTIMPL_LIST_SIZE; ++i) {
    rf_inst_def_code(rf_inst_notimpl_list[i], rf_inst_code_notimpl);
  }

  /* used in ;CODE */
  rf_inst_def_code_immediate("[COMPILE]", rf_inst_code_bcompile);

  rf_inst_colon("inst-interpret");
  rf_inst_compile("inst-interpret-word");
	rf_inst_compile("BRANCH");
	rf_inst_comma((intptr_t) -2 * RF_WORD_SIZE);

  /* : */
  rf_inst_def_user("CURRENT", RF_USER_CURRENT_IDX);
  rf_inst_def_user("CONTEXT", RF_USER_CONTEXT_IDX);

  rf_inst_colon(":");
/*
  rf_inst_compile("?EXEC");
*/
/*
  rf_inst_compile("!CSP");
*/
/*
  rf_inst_compile("CURRENT");
  rf_inst_compile("@");
  rf_inst_compile("CONTEXT");
  rf_inst_compile("!");
*/
  rf_inst_compile("CREATE");
  rf_inst_compile("]");
  /* write docol to CFA... */
  rf_inst_compile_lit((rf_word_t) rf_code_docol);
  /* user vars won't move at inst time so below is ok */
  rf_inst_compile_lit((rf_word_t) &RF_USER_DP);
  rf_inst_compile("@");
  rf_inst_compile_lit((rf_word_t) -RF_WORD_SIZE);
  rf_inst_compile(("+"));
  rf_inst_compile(("!"));
  rf_inst_compile((";S"));
  rf_inst_immediate();

  /* ; */
  rf_inst_def_code("[", rf_inst_code_lbrac);
  rf_inst_immediate();

  rf_inst_colon(";");
/*
  rf_inst_compile("?CSP");
*/
  rf_inst_compile("COMPILE");
  rf_inst_compile(";S");
  rf_inst_compile("SMUDGE");
  rf_inst_compile("[");
  rf_inst_compile(";S");
  rf_inst_immediate();

  /* X */  
  here = (unsigned char *) RF_USER_DP;
  rf_inst_def_code("X", rf_inst_code_x);
  here[0] = 0x81;
  here[1] = 0x80;
  rf_inst_immediate();

  /* used by +ORIGIN itself */
  rf_inst_def_code_immediate("LITERAL", rf_inst_code_literal);

  /* stack limit literals */
  rf_inst_def_literal("inst-s0", (rf_word_t) RF_S0);
  rf_inst_def_literal("inst-s1", (rf_word_t) ((rf_word_t *) RF_S0 - RF_STACK_SIZE));

  /* inst-load */
  rf_inst_colon("inst-load");
  rf_inst_compile("inst-interpret");
  rf_inst_compile("rf-exit");

  /* define code address literals */
  for (i = 0; i < RF_INST_CODE_LIT_LIST_SIZE; ++i) {
    rf_inst_code_t *code = &rf_inst_code_lit_list[i];
    rf_inst_def_literal(code->name, (rf_word_t) code->value);
  }
}

rf_code_t *rf_inst_load_cfa = 0;

static void rf_inst_emptybuffers(void)
{
  rf_inst_memset(RF_FIRST, '\0', (char *) RF_LIMIT - (char *) RF_FIRST);
}

static void __FASTCALL__ rf_inst_load(rf_word_t screen)
{
  /* initialise BLK, IN */
  RF_USER_BLK = screen * RF_BSCR;
  RF_USER_IN = 0;

  /* initialise RP */
  RF_RP_SET((rf_word_t *) RF_USER_R0);

  /* jump to inst-load */
  assert(rf_inst_load_cfa);
  RF_IP_SET((rf_word_t *) &rf_inst_load_cfa);
  RF_JUMP(rf_next);
  rf_trampoline();
}

#ifdef RF_INST_SAVE
static void rf_inst_save(void)
{
  /* write to DR1 */
  unsigned int blk = 2000;
  /* start from ORG */
  char *i = (char *) RF_ORG;
  /* write blocks to disc until HERE */
  char buf[128];
  unsigned char j;
  while (i < (char *) RF_USER_DP) {
    for (j = 0; j < 128;) {
      unsigned char b = *i++;
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
  char *nfa;
  rf_word_t *origin;

  /* fail if called after installed */
  RF_INST_ONLY;

#ifdef SPECTRUM
  /* wait for disc server to init */
  /* TODO Fix the underlying issue with spectrum serial */
  sleep(5);
#endif

  /* cold start */
  rf_inst_cold();

  /* inst forward declarations */
  rf_inst_forward();

#ifdef RF_INST_OVERWRITE
  /* now move DP to target the real dictionary */
  RF_USER_DP = (rf_word_t) RF_ORIGIN;
#endif

  /* inst-load is the starting point to load and interpret */
  nfa = rf_inst_find_string("inst-load");
  assert(nfa);

  rf_inst_load_cfa = rf_cfa(nfa);
  assert(rf_inst_load_cfa);

  /* load */
  rf_inst_emptybuffers();

  rf_inst_use = (rf_word_t *) RF_FIRST;
  rf_inst_prev = (rf_word_t *) RF_FIRST;
  rf_inst_load(12);
  rf_inst_load(33);
  rf_inst_load(72);

  /* finished loading */
  rf_inst_load_cfa = 0;

#ifdef RF_INST_OVERWRITE
  /* break link with inst time code */
  *(rf_lfa(rf_inst_find_string("rf-cell"))) = 0;
#endif

  /* set WARNING = 1 */
  origin = (rf_word_t *) RF_ORIGIN;
  origin[13] = 0x0001;

  /* FORTH and ABORT are used in rf_code_cold */
  rf_cold_forth = rf_pfa(rf_inst_find_string("FORTH"));
  assert(rf_cold_forth);
  rf_cold_abort = rf_pfa(rf_inst_find_string("ABORT"));
  assert(rf_cold_abort);

#ifdef RF_INST_SILENT
  /* enable CR, EMIT after silent install */
  *(rf_cfa(rf_inst_find_string("CR"))) = rf_code_cr;
  *(rf_cfa(rf_inst_find_string("EMIT"))) = rf_code_emit;
#endif

  /* mark as installed; fail if inst time code called */
  rf_installed = 1;

#ifdef RF_INST_SAVE
  /* save the result to disc */
  rf_inst_save();
#endif
}
