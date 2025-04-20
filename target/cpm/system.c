#include <cpm.h>
#include <stdint.h>

void rf_init(void)
{
}

uint8_t rf_console_get(void)
{
  return bdos(CPM_RCON, 0);
}

void __FASTCALL__ rf_console_put(uint8_t b)
{
  bdos(CPM_WCON, b);
}

uint8_t rf_console_qterm(void)
{
  return 0;
}

void rf_console_cr(void)
{
  bdos(CPM_WCON, 13);
}

uint8_t rf_serial_get(void)
{
  return bdos(CPM_RRDR, 0);
}

void __FASTCALL__ rf_serial_put(uint8_t b)
{
  bdos(CPM_WCON, b);
  bdos(CPM_WPUN, b);
}

void rf_fin(void)
{
}
