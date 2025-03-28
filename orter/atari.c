#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"

static uint8_t data[65536];

static int orter_atari_xex_write(uint16_t load, uint16_t runad)
{
    size_t s;

    /* read whole file */
    s = fread(data, 1, 65536, stdin);

    /* data block */
    fwrite("\xFF\xFF", 1, 2, stdout);
    orter_io_put_16le(load);
    orter_io_put_16le(load + s - 1);
    fwrite(data, 1, s, stdout);

    /* RUNAD block */
    orter_io_put_16le(0x02E0);
    orter_io_put_16le(0x02E1);
    orter_io_put_16le(runad);

    /* end */
    fflush(stdout);
    return 0;
}

int orter_atari(int argc, char *argv[])
{
    if (argc == 6 && !strcmp("xex", argv[2]) && !strcmp("write", argv[3])) {
        return orter_atari_xex_write(strtol(argv[4], 0, 0), strtol(argv[5], 0, 0));
    }

    /* usage */
    fprintf(stderr, "Usage: orter atari xex write <load> <runad>\n");
    return 1;
}
