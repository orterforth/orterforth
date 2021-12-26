/* ORTERFORTH */

#include "rf.h"
#include "rf_inst.h"

/* indicates whether installation has been completed */
/* inst time functions will fail fast if so */
char rf_installed = 0;

int main(int argc, char *argv[])
{
  /* initialise */
  rf_init();

  /* install */
  if (!rf_installed) {
    rf_inst();
  }

  /* run COLD */
  rf_trampoline_fp = rf_code_cold;
  rf_trampoline();

  /* finalise */
  rf_fin();

  /* exit */
  return 0;
}
