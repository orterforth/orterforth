#ifndef ORTER_IO_H_
#define ORTER_IO_H_

#include <stddef.h>

/* function pointer type for a read or write operation */
typedef size_t (*orter_io_rdwr_t)(char *, size_t);

/* flag for cleanup and exit */
extern int orter_io_finished;

/* read and write with flow control */
void orter_io_relay(orter_io_rdwr_t rd, orter_io_rdwr_t wr, char *buf, char **offset, size_t *pending);

#endif /* ORTER_IO_H_ */
