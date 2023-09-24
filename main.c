/* ORTERFORTH */

#include "rf.h"
#include "inst.h"
#ifdef RF_INST_LOCAL_DISC
#ifdef RF_ARGS
#include "persci.h"
#endif
#endif

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
    rf_inst();
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
  rf_fp = rf_code_cold;
  rf_trampoline();

  /* finalise */
  rf_fin();

  /* exit */
  return 0;
}
