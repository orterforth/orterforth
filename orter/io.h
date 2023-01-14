#ifndef ORTER_IO_H_
#define ORTER_IO_H_

#include <stddef.h>

/* function pointer type for a read or write operation */
typedef size_t (*orter_io_rdwr_t)(char *, size_t);

/* source, buffer and sink comprise a pipe */
typedef struct orter_io_pipe_t {
    int in;
    orter_io_rdwr_t rd;
    char buf[256];
    char *off;
    size_t len;
    orter_io_rdwr_t wr;
    int out;
} orter_io_pipe_t;

/* flag to indicate EOF */
extern int orter_io_eof;

/* exit code to return after cleanup */
extern int orter_io_exit;

/* flag for cleanup and exit */
extern int orter_io_finished;

/* select handling */
extern fd_set orter_io_readfds, orter_io_writefds, orter_io_exceptfds;

/* set up signal handler */
void orter_io_signal_init(void);

/* nonblocking read from fd */
size_t orter_io_fd_rd(int fd, char *off, size_t len);

/* nonblocking write to fd */
size_t orter_io_fd_wr(int fd, char *off, size_t len);

/* nonblocking read from stdin */
size_t orter_io_stdin_rd(char *off, size_t len);

/* nonblocking write to stdout */
size_t orter_io_stdout_wr(char *off, size_t len);

/* read and write with flow control TODO migrate to orter_io_move */
void orter_io_relay(orter_io_rdwr_t rd, orter_io_rdwr_t wr, char *buf, char **offset, size_t *pending);

/* set up pipe */
void orter_io_pipe_init(orter_io_pipe_t *pipe, int in, orter_io_rdwr_t rd, orter_io_rdwr_t wr, int out);

/* add to fd sets based on buffer state */
void orter_io_pipe_fdset(orter_io_pipe_t *pipe);

/* read and write with flow control */
void orter_io_pipe_move(orter_io_pipe_t *pipe);

/* zero fd sets */
void orter_io_select_zero(void);

/* carry out select on fd sets */
int orter_io_select(void);

#endif /* ORTER_IO_H_ */
