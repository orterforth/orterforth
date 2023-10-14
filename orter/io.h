#ifndef ORTER_IO_H_
#define ORTER_IO_H_

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/select.h>

/* source, buffer and sink comprise a pipe */
typedef struct orter_io_pipe_t {
    int in;
    char buf[256];
    char *off;
    size_t len;
    int out;
} orter_io_pipe_t;

/* exit code to return after cleanup */
extern int orter_io_exit;

/* flag for cleanup and exit */
extern int orter_io_finished;

/* select handling */
extern fd_set orter_io_readfds, orter_io_writefds, orter_io_exceptfds;

/* set up signal handler */
void orter_io_signal_init(void);

/* stdio file size */
int orter_io_file_size(FILE *ptr, long *size);

/* set up nonblocking stdin/stdout */
int orter_io_std_open(void);

/* restore stdin/stdout */
int orter_io_std_close(void);

/* space left in buffer */
size_t orter_io_pipe_left(orter_io_pipe_t *buf);

/* get byte */
int orter_io_pipe_get(orter_io_pipe_t *buf);

/* put byte */
int orter_io_pipe_put(orter_io_pipe_t *buf, char b);

/* set up pipe */
void orter_io_pipe_init(orter_io_pipe_t *pipe, int in, int out);

/* set up pipe source */
void orter_io_pipe_read_init(orter_io_pipe_t *pipe, int in);

/* set up pipe sink */
void orter_io_pipe_write_init(orter_io_pipe_t *pipe, int out);

/* add to fd sets based on buffer state */
void orter_io_pipe_fdset(orter_io_pipe_t *pipe);

/* read and write with flow control */
void orter_io_pipe_move(orter_io_pipe_t *pipe);

/* zero fd sets */
void orter_io_select_zero(void);

/* carry out select on fd sets */
int orter_io_select(void);

/* operate pipes until end or interrupted */
int orter_io_pipe_loop(orter_io_pipe_t **pipes, int num, void (*process)(void));

/* write 16 bit BE int */
void orter_io_put_16be(uint16_t u);

/* write 16 bit LE int */
void orter_io_put_16le(uint16_t u);

/* write 32 bit LE int */
void orter_io_put_32le(uint32_t u);

/* get 32 bit BE int */
uint32_t orter_io_get_32be(uint8_t *p);

/* set 16 bit BE int */
void orter_io_set_16be(uint16_t u, uint8_t *p);

/* set 16 bit LE int */
void orter_io_set_16le(uint16_t u, uint8_t *p);

/* set 32 bit BE int */
void orter_io_set_32be(uint32_t u, uint8_t *p);

/* set 32 bit LE int */
void orter_io_set_32le(uint32_t u, uint8_t *p);

#endif /* ORTER_IO_H_ */
