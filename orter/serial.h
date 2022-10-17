#ifndef ORTER_SERIAL_H_
#define ORTER_SERIAL_H_

int orter_serial_open(char *name, int baud);

size_t orter_serial_rd(char *off, size_t len);

size_t orter_serial_wr(char *off, size_t len);

int orter_serial_close(void);

/* command line */
int orter_serial(int argc, char **argv);

#endif /* ORTER_SERIAL_H_ */
