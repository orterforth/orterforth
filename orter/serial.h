#ifndef ORTER_SERIAL_H_
#define ORTER_SERIAL_H_

/* function pointer type for a read or write operation */
typedef size_t (*rdwr_t)(char *, size_t);

int orter_serial_open(char *name, int baud);

size_t orter_serial_stdin_rd(char *off, size_t len);

size_t orter_serial_stdout_wr(char *off, size_t len);

size_t orter_serial_rd(char *off, size_t len);

size_t orter_serial_wr(char *off, size_t len);

/* read and write with flow control */
void orter_serial_relay(rdwr_t rd, rdwr_t wr, char *buf, char **offset, size_t *pending);

int orter_serial_close(void);

/* command line */
int orter_serial(int argc, char **argv);

#endif /* ORTER_SERIAL_H_ */
