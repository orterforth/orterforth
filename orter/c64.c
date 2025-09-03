#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"
#include "wav.h"

static uint16_t prg_start = 0;

static uint8_t *prg_data = 0;

static uint16_t prg_data_len = 0;

static void prg_read(void)
{
    int b;
    size_t siz = 0;

    /* start addr */
    prg_start = orter_io_read_16le();
    /* data */
    prg_data_len = 0;
    while ((b = getchar()) != EOF) {
        if (prg_data_len >= siz) {
            siz += 256;
            prg_data = realloc(prg_data, siz);
        }
        prg_data[prg_data_len++] = b;
    }
    /* TODO end of tape */
}

#define SHORT 0x30
#define MEDIUM 0x42
#define LONG 0x56

static uint8_t *tap_filename = 0;

static uint8_t *tap_data = 0;

static size_t tap_data_siz = 0, tap_data_len = 0;

static uint8_t tap_checksum = 0;

static void tap_start(const char *filename)
{
    tap_data = 0;
    tap_data_siz = 0;
    tap_data_len = 0;
    tap_filename = (uint8_t *) filename;
}

static void tap_write_cycle(uint8_t c)
{
    if (tap_data_len >= tap_data_siz) {
        tap_data_siz += 256;
        tap_data = realloc(tap_data, tap_data_siz);
    }
    tap_data[tap_data_len++] = c;
}

static void tap_write_leader(uint16_t size)
{
    int i;

    for (i = 0; i < size; ++i) {
        tap_write_cycle(SHORT);
    }
}

static void tap_write_data_marker(int more)
{
    tap_write_cycle(LONG);
    tap_write_cycle(more ? MEDIUM : SHORT);
}

static void tap_write_bit(uint8_t bit)
{
    if (bit) {
        tap_write_cycle(MEDIUM);
        tap_write_cycle(SHORT);
    } else {
        tap_write_cycle(SHORT);
        tap_write_cycle(MEDIUM);
    }
}

static void tap_write_byte(uint8_t value, int more)
{
    uint8_t check_bit = 1;
    uint8_t i;

    for (i = 1; i; i <<= 1) {
        uint8_t bit = (value & i) != 0;
        tap_write_bit(bit);
        check_bit ^= bit;
    }

    tap_write_bit(check_bit);
    tap_write_data_marker(more);
    tap_checksum ^= value;
}

static void tap_write_sync(int repeated)
{
    uint8_t value = repeated ? 0x09 : 0x89;
    int i;

    tap_write_data_marker(1);
    for (i = 0; i < 9; ++i) {
        tap_write_byte(value--, 1);
    }
}

static void tap_write_filename(void)
{
    int i;
    uint8_t buf[0x10];
    size_t len;

    /* pad with spaces to 16 bytes */
    memset(buf, 0x20, 0x10);
    len = strlen((char *) tap_filename);
    if (len > 0x10) len = 0x10;
    memcpy(buf, tap_filename, len);
    /* write 16 bytes */
    for (i = 0; i < 0x10; ++i) {
        uint8_t b = buf[i];

        /* PETSCII */
        if (b >= 'a' && b <= 'z') {
            b ^= 0x20;
        }
        tap_write_byte(b, 1);
    }
}

static void tap_write_header(void)
{
    uint16_t end;
    int i, j;

    end = prg_start + prg_data_len;
    for (i = 0; i < 2; ++i) {
        /* pilot */
        tap_write_leader(i ? 0x004F : 0x6A00);
        /* sync */
        tap_write_sync(i);
        /* header */
        tap_checksum = 0;
        /* file type: 0x03 = non relocatable */
        tap_write_byte(0x03, 1);
        /* start and end address */
        tap_write_byte(prg_start, 1);
        tap_write_byte(prg_start >> 8, 1);
        tap_write_byte(end, 1);
        tap_write_byte(end >> 8, 1);
        /* file name */
        tap_write_filename();
        /* body */
        for (j = 0; j < 171; ++j) {
            tap_write_byte(0x20, 1);
        }
        /* checkbyte */
        tap_write_byte(tap_checksum, 0);
    }
    /* trailer */
    tap_write_leader(0x004E);
}

static void tap_write_data(void)
{
    int i, j;

    for (i = 0; i < 2; ++i) {
        /* pilot */
        tap_write_leader(i ? 0x004F : 0x1A00);
        /* sync */
        tap_write_sync(i);
        tap_checksum = 0;
        for (j = 0; j < prg_data_len; ++j) {
            tap_write_byte(prg_data[j], 1);
        }
        tap_write_byte(tap_checksum, 0);
    }
    /* trailer */
    tap_write_leader(0x004E);
}

static void tap_end(void)
{
    /* header */
    fwrite("C64-TAPE-RAW\0\0\0\0", 1, 16, stdout);
    orter_io_put_32le(tap_data_len);
    /* data */
    fwrite(tap_data, 1, tap_data_len, stdout);
    fflush(stdout);
    /* done */
    free(tap_data);
    tap_data = 0;
    tap_data_len = 0;
    tap_data_siz = 0;
}

#define PAL_CYCLES 985248.0

static void wav_write_tap_cycle(int value)
{
    orter_wav_write_cycle((float) value * 8.0 / PAL_CYCLES);
}

int orter_c64(int argc, char *argv[])
{
    if (argc == 6 && !strcmp("prg", argv[2]) && !strcmp("to", argv[3]) && !strcmp("tap", argv[4])) {
        prg_read();
        tap_start(argv[5]);
        /* header */
        tap_write_header();
        tap_write_data();
        tap_end();

        return 0;
    }

    if (argc == 5 && !strcmp("tap", argv[2]) && !strcmp("to", argv[3]) && !strcmp("wav", argv[4])) {

        uint8_t buf[16];
        int b;

        /* read and validate header */
        if (fread(buf, 1, 16, stdin) != 16) {
            fprintf(stderr, "TAP header read failed\n");
            return 1;
        }
        /* magic value */
        if (memcmp(buf, "C64-TAPE-RAW", 12)) {
            fprintf(stderr, "no TAP header\n");
            return 1;
        }
        /* version */
        if (buf[12]) {
            fprintf(stderr, "TAP version %u not supported\n", buf[12]);
            return 1;
        }
        /* platform */
        if (buf[13]) {
            fprintf(stderr, "Platform %u not supported (C64 only)\n", buf[13]);
            return 1;
        }
        /* video standard */
        if (buf[14]) {
            fprintf(stderr, "Video standard %u not supported (PAL only)\n", buf[14]);
            return 1;
        }
        /* size */
        orter_io_read_32le();

        /* write WAV */
        orter_wav_start();
        while ((b = getchar()) != EOF) {
            wav_write_tap_cycle(b);
        }
        orter_wav_end();

        return 0;
    }

    fprintf(stderr, "Usage: orter c64 prg to tap <filename>\n");
    fprintf(stderr, "       orter c64 tap to wav\n");
    return 1;
}

