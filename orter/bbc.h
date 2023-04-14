#ifndef ORTER_UEF_H_
#define ORTER_UEF_H_

#include <stdint.h>

int orter_bbc_uef_write(char *name, uint16_t load, uint16_t exec);

int orter_bbc(int argc, char *argv[]);

#endif /* ORTER_UEF_H_ */
