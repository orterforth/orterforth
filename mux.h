#ifndef RF_MUX_H_
#define RF_MUX_H_

#include <stdint.h>

#include "rf.h"

uint8_t rf_mux_serial_get(void);

void __FASTCALL__ rf_mux_serial_put(uint8_t b);

#endif /* RF_MUX_H_ */
