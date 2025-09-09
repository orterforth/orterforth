#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"

static int orter_dragon_bin_header(uint8_t type, uint16_t start, uint16_t size, uint16_t exec)
{
    /* 55 */
    putchar(0x55);
    /* type 2=binary */
    putchar(type);
    /* start */
    orter_io_write_16be(start);
    /* size */
    orter_io_write_16be(size);
    /* exec */
    orter_io_write_16be(exec);
    /* AA */
    putchar(0xAA);
    return 0;
}

int orter_dragon_cas_write(void)
{
    /* header and sync */
    fputs("UUUUUUUUUUUUUUUU", stdout);
    fputs("UUUUUUUUUUUUUUU<", stdout);
    /* namefile block */
    fputc('\x00', stdout);
    /* length */
    fputc('\x0f', stdout);
    /* name */
    fputs("DRAGON/H", stdout);
    /* binary file */
    fputc('\x02', stdout);
    fputc('\x00', stdout);
    /* continuous */
    fputc('\x00', stdout);
    /* exec, load */
    
    fputc('\x28', stdout);
    fputc('\x00', stdout);
    fputc('\x28', stdout);
    fputc('\x00', stdout);
    /* checksum */
    fputc('\x93', stdout);
    /* trailer */
    fputc('U', stdout);

    /* header and sync */
    fputs("UUUUUUUUUUUUUUUU", stdout);
    fputs("UUUUUUUUUUUUUUU<", stdout);
    /* data block */
    fputc('\x00', stdout);

    return 0;
}

int orter_dragon(int argc, char *argv[])
{
    if (argc == 8 && !strcmp("bin", argv[2]) && !strcmp("header", argv[3])) {
      return orter_dragon_bin_header(
        strtol(argv[4], 0, 0), 
        strtol(argv[5], 0, 0), 
        strtol(argv[6], 0, 0), 
        strtol(argv[7], 0, 0));
    }

    /* usage */
    fprintf(stderr, "Usage: orter dragon bin header <type> <start> <size> <exec>\n");
    return 1;
}
