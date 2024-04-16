#include "mux.h"

void rf_init(void)
{
}

uint8_t rf_serial_get(void)
{
  return rf_mux_serial_get();
}

void __FASTCALL__ rf_serial_put(uint8_t b)
{
  rf_mux_serial_put(b);
}

void rf_fin(void)
{
}
