#ifndef ORTER_IO_H_
#define ORTER_IO_H_

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

/* source, buffer and sink comprise a pipe */
typedef struct orter_io_pipe_t {
    int in;
    char buf[256];
    char *off;
    size_t len;
    int out;
} orter_io_pipe_t;

/* flag for cleanup and exit */
extern int orter_io_finished;

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

/* operate pipes until end or interrupted */
int orter_io_pipe_loop(orter_io_pipe_t **pipes, int num, void (*process)(void));

/* read 16 bit LE int */
uint16_t orter_io_read_16le(void);

/* read 32 bit LE int */
uint32_t orter_io_read_32le(void);

/* write 16 bit BE int */
void orter_io_write_16be(uint16_t u);

/* write 16 bit LE int */
void orter_io_write_16le(uint16_t u);

/* write 32 bit LE int */
void orter_io_write_32le(uint32_t u);

/* get 16 bit LE int */
uint16_t orter_io_get_16le(uint8_t *p);

/* get 32 bit LE int */
uint32_t orter_io_get_32le(uint8_t *p);

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
