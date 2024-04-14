#ifndef RF_MUX_H_
#define RF_MUX_H_

#include <stdint.h>

uint8_t rf_mux_serial_get(void);

void __FASTCALL__ rf_mux_serial_put(uint8_t b);

void rf_mux_disc_read(char *c, unsigned char len);

void rf_mux_disc_write(char *c, unsigned char len);

#endif /* RF_MUX_H_ */
