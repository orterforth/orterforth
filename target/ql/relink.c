#include "rf.h"

#define SIZE 61

static rf_code_t codes[] = {
  rf_code_cl,
  rf_code_cs,
  rf_code_ln,
  rf_code_tg,
  rf_code_xt,
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
  rf_code_emit,
  rf_code_key,
  rf_code_qterm,
  rf_code_cr,
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
  rf_code_bread
};

extern char rf_installed;

void rf_inst(void)
{
  /* LATEST */
  uint8_t *p = *((uint8_t **) (RF_ORIGIN + 24));
  /* HERE */
  uintptr_t *here = *((uintptr_t **) (RF_ORIGIN + 60));
  int i;
  
  while (p) {
    uint8_t *nfa = p;
    rf_code_t *cfa;
    uintptr_t *pfa;

    /* NFA */
    p++;
    while ((*p & 0x80) == 0) {
      p++;
    }
    p++;
    /* CFA */
    cfa = (((rf_code_t *) p) + 1);
    /* find CFA code address in table */
    for (i = 0; i < SIZE; i++) {
      if (*cfa == (rf_code_t) here[i]) {
        /* update with code from this job */
        *cfa = codes[i];
      }
    }
    /* PFA */
    pfa = (uintptr_t *) cfa + 1;
    /* : */
    if (nfa[0] == 0xC1 && (nfa[1] & 0x7F) == ':') {
      *(pfa + 9) = (uintptr_t) rf_code_docol;
    }
    /* CONSTANT */
    if (nfa[0] == 0x88 && nfa[1] == 'C' && nfa[2] == 'O' && nfa[3] == 'N' && nfa[4] == 'S') {
      *(pfa + 4) = (uintptr_t) rf_code_docon;
    }
    /* VARIABLE */
    if (nfa[0] == 0x88 && nfa[1] == 'V' && nfa[2] == 'A' && nfa[3] == 'R' && nfa[4] == 'I') {
      *(pfa + 2) = (uintptr_t) rf_code_dovar;
    }
    /* USER */
    if (nfa[0] == 0x84 && nfa[1] == 'U' && nfa[2] == 'S' && nfa[3] == 'E' && nfa[4] == 'R') {
      *(pfa + 2) = (uintptr_t) rf_code_douse;
    }
    /* DOES> */
    if (nfa[0] == 0x85 && nfa[1] == 'D' && nfa[2] == 'O' && nfa[3] == 'E' && nfa[4] == 'S') {
      *(pfa + 5) = (uintptr_t) rf_code_dodoe;
    }
    /* LFA */
    p = *((uint8_t **) p);
  }

  /* links used in COLD */
  rf_cold_forth = (uintptr_t *) here[SIZE];
  rf_cold_abort = (uintptr_t *) here[SIZE + 1];

  /* now flag as installed */
  rf_installed = 1;
}
