#ifndef ORTER_IO_H_
#define ORTER_IO_H_

#include <stddef.h>

/* function pointer type for a read or write operation */
typedef size_t (*orter_io_rdwr_t)(char *, size_t);

/* flag to indicate EOF */
extern int orter_io_eof;

/* flag for cleanup and exit */
extern int orter_io_finished;

/* nonblocking read from fd */
size_t orter_io_fd_rd(int fd, char *off, size_t len);

/* nonblocking write to fd */
size_t orter_io_fd_wr(int fd, char *off, size_t len);

/* nonblocking read from stdin */
size_t orter_io_stdin_rd(char *off, size_t len);

/* nonblocking write to stdout */
size_t orter_io_stdout_wr(char *off, size_t len);

/* read and write with flow control */
void orter_io_relay(orter_io_rdwr_t rd, orter_io_rdwr_t wr, char *buf, char **offset, size_t *pending);

#endif /* ORTER_IO_H_ */
