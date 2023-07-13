#ifndef ORTER_SERIAL_H_
#define ORTER_SERIAL_H_

extern int orter_serial_fd;

int orter_serial_open(char *name, int baud);

int orter_serial_close(void);

/* command line */
int orter_serial(int argc, char **argv);

#endif /* ORTER_SERIAL_H_ */
