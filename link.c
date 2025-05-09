#include "rf.h"

static rf_code_t codes[] = {
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
  rf_code_emit,
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
  rf_code_mon
};

extern char rf_installed;

void rf_inst(void)
{
  uint8_t   *pp, *qq;
  uint8_t   b, l;
  uintptr_t *rr;

  /* start relocating/linking */
  pp = qq = (uint8_t *) RF_ORIGIN;
  while ((b = *(pp++)) != 0) {

    /* move bytes */
    rr = (uintptr_t *) qq;
    for (l = b & 0x1F; l; --l) {
      *(qq++) = *(pp++);
    }

    /* now fix up */
    switch (b & 0xE0) {
      case 0x20:
        /* relocate relative to ORIGIN */
        (*rr) += (uintptr_t) RF_ORIGIN;
        break;
      case 0x40:
        /* relocate relative to LIMIT */
        (*rr) += (uintptr_t) RF_LIMIT;
        break;
      case 0x60:
        /* link to code */
        (*rr) = (uintptr_t) codes[*rr];
        break;
    }
  }

  /* now flag as installed */
  rf_installed = 1;
}
