#include "rf.h"

#define SIZE 61

static rf_code_t codes[] = {
  rf_code_cl,
  rf_code_cs,
  rf_code_ln,
  0,
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
  uint8_t *p = *((uint8_t **) ((uintptr_t *) (RF_ORIGIN) + 6));
  /* HERE */
  rf_code_t *here = *((rf_code_t **) ((uintptr_t *) (RF_ORIGIN) + 15));
  int i;

  /* cold start vector */
  *((uintptr_t *) (RF_ORIGIN) + 1) = (uintptr_t) rf_code_cold;

  while (p) {
    uint8_t *nfa = p;
    rf_code_t *cfa;

    /* NFA */
    p++;
    while ((*(p++) & 0x80) == 0) {
    }

    /* CFA */
    cfa = (((rf_code_t *) p) + 1);

    /* find CFA code address in table */
    for (i = 0; i < SIZE; i++) {
      if (*cfa == here[i]) {
        /* update with code from this job */
        *cfa = codes[i];
      }
    }

    /* LFA */
    p = *((uint8_t **) p);
  }

  /* code addresses in body */
  *((rf_code_t *) (here[61])) = rf_code_docol;
  *((rf_code_t *) (here[62])) = rf_code_docon;
  *((rf_code_t *) (here[63])) = rf_code_dovar;
  *((rf_code_t *) (here[64])) = rf_code_douse;
  *((rf_code_t *) (here[65])) = rf_code_dodoe;

  /* now flag as installed */
  rf_installed = 1;

  /* some target code needs RP and SP initialised before COLD */
  /* e.g., 6809 assembly stack frame handling */
  RF_RP_SET((uintptr_t *) RF_R0);
  RF_SP_SET((uintptr_t *) RF_S0);
}
