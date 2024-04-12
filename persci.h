#ifndef RF_PERSCI_H_
#define RF_PERSCI_H_

#include <stdint.h>

/* ASCII CONTROL CHARS */

int rf_persci_insert(int drive, char *filename);

int rf_persci_insert_bytes(int drive, const uint8_t *bytes);

int rf_persci_eject(int drive);

int rf_persci_getc(void);

int rf_persci_putc(char c);

#endif /* RF_PERSCI_H_ */
