#ifndef ORTER_SERIAL_H_
#define ORTER_SERIAL_H_

void orter_serial_open(char *name, unsigned int baud);

void orter_serial_read(char *p, int len);

void orter_serial_write(char *p, int len);

int orter_serial_getc();

int orter_serial_putc(int c);

void orter_serial_flush();

void orter_serial_close();

#endif /* ORTER_SERIAL_H_ */
