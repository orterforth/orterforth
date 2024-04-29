/* ORTERFORTH */

#include "rf.h"
#ifdef RF_INST_LOCAL_DISC
/* disc controller in process */
#include "persci.h"
/* inst disc binary image */
const
#include "model.inc"
#endif

/* install function */
void rf_inst(void);

/* indicates whether installation has been completed */
char rf_installed = 0;

#ifdef RF_ARGS
int main(int argc, char *argv[])
#else
int main(void)
#endif
{
  /* initialise */
  rf_init();

  /* install */
  if (!rf_installed) {
    /* "insert" the inst disc */
#ifdef RF_INST_LOCAL_DISC
    if (rf_persci_insert_bytes(0, model_img)) return 1;
#endif

    rf_inst();

    /* now "eject" the inst disc */
#ifdef RF_INST_LOCAL_DISC
    if (rf_persci_eject(0)) return 1;
#endif
  }

#ifdef RF_INST_LOCAL_DISC
#ifdef RF_ARGS
  /* insert discs */
  if (argc >= 2) {
    if (rf_persci_insert(0, argv[1])) return 1;
  }
  if (argc >= 3) {
    if (rf_persci_insert(1, argv[2])) return 1;
  }
#endif
#endif

  /* run COLD */
#ifdef RF_NOEXIT
  for (;;) {
#endif
    rf_fp = rf_code_cold;
    rf_trampoline();
#ifdef RF_NOEXIT
  }
#endif

  /* finalise */
  rf_fin();

  /* exit */
  return 0;
}
