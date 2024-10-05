#include <stdint.h>
#include <stdlib.h>

void rf_init(void)
{
  /* 8N1 9600 baud, RTS high */
  /* CMR */
  *((uint8_t *) 12042) = 0x02;
  /* CR */
  *((uint8_t *) 12043) = 0x1E;
}

void __FASTCALL__ rf_console_put(uint8_t b)
{
  /* FF to BS */
  if (b == 0x0C) {
    fputc_cons(0x08);
    fputc_cons(0x20);
    fputc_cons(0x08);
    return;
  }

  fputc_cons(b);
}

uint8_t rf_console_get(void)
{
  uint8_t b;

  /* draw cursor */
  fputc_cons('c');
  fputc_cons(0x08);
  /* fetch byte */
  b = fgetc_cons();
  /* erase cursor */
  fputc_cons(0x20);
  fputc_cons(0x08);

  return b;
}

uint8_t rf_console_qterm(void)
{
  return 0;
}

void rf_console_cr(void)
{
  fputc_cons('\n');
}

void __FASTCALL__ rf_serial_put(uint8_t b)
{
  /* 6551 handles CTS itself */
  /* TDRE */
  while (!(*((uint8_t *) 12045) & 0x10)) { }
  /* TDR */
  *((uint8_t *) 12040) = b;
}

uint8_t rf_serial_get(void)
{
  uint8_t b;

  /* CMR - RTS low */
  *((uint8_t *) 12042) = 0x0A;
  /* RDRF */
  while (!(*((uint8_t *) 12045) & 0x08)) { }
  /* RDR */
  b = *((uint8_t *) 12044);
  /* CMR - RTS high */
  *((uint8_t *) 12042) = 0x02;

  return b;
}

void rf_fin(void)
{
}
