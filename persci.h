#ifndef RF_PERSCI_H_
#define RF_PERSCI_H_

#include <stdint.h>

/* ASCII CONTROL CHARS */

#define RF_ASCII_SOH 1
#define RF_ASCII_EOT 4
#define RF_ASCII_ENQ 5
#define RF_ASCII_ACK 6
#define RF_ASCII_LF 10
#define RF_ASCII_CR 13
#define RF_ASCII_NAK 21

void rf_persci_insert(int drive, char *filename);

void rf_persci_insert_bytes(int drive, const uint8_t *bytes);

void rf_persci_eject(int drive);

int rf_persci_getc(void);

int rf_persci_putc(char c);

#endif /* RF_PERSCI_H_ */
