#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"
#include "wav.h"

static int orter_eg2000_bin_to_cmd(uint16_t sta, uint16_t exe)
{
    uint8_t dat[254];
    uint16_t len;

    /* Load Block */
    while ((len = fread(dat, 1, 254, stdin))) {
        putchar(0x01);
        putchar(len + 2);
        orter_io_write_16le(sta);
        fwrite(dat, 1, len, stdout);
        sta += len;
    }
    /* Execution Address */
    putchar(0x02);
    putchar(0x02);
    orter_io_write_16le(exe);

    return 0;
}

static int orter_eg2000_cmd_to_cas(char *nam)
{
    int typ;
    uint16_t len, idx;
    uint16_t sta, exe;
    uint8_t *dat;
    uint8_t byt, chk;

    /* cas header */
    putchar(0x66);
    /* filename */
    putchar(0x55);
    idx = strlen(nam);
    if (idx > 6) idx = 6;
    fwrite(nam, 1, idx, stdout);
    while (idx++ < 6) {
        putchar(' ');
    }

    /* read blocks */
    while ((typ = getchar()) != -1) {
        switch (typ) {
            /* load block */
            case 1:
            /* read length */
            len = getchar();
            len = (len <= 2) ? len + 254 : len - 2;
            /* read start address */
            sta = orter_io_read_16le();
            /* read data */
            dat = malloc(len);
            fread(dat, 1, len, stdin);

            /* write block */
            putchar(0x3C);
            putchar(len);
            orter_io_write_16le(sta);
            chk = sta + (sta >> 8);
            for (idx = 0; idx < len; ++idx) {
                putchar(byt = dat[idx]);
                chk += byt;
            }
            free(dat);
            /* write checksum */
            putchar(chk);

            break;
            /* execution address */
            case 2:
                len = getchar();
                if (len != 2) {
                    fprintf(stderr, "typ=%02X len=%02X\n", typ, len);
                    return 1;
                }
                /* read addr */
                exe = orter_io_read_16le();
                /* write addr */
                putchar(0x78);
                orter_io_write_16le(exe);
                break;
            /* ignored */
            default:
                fprintf(stderr, "typ=%u\n", typ);
                return 1;
        }
    }

    return 0;
}

static uint8_t wav_state;

static void wav_signal(int len)
{
    int i;

    /* TODO duty */
    for (i = 0; i < len; ++i) {
        orter_wav_write_16le(wav_state ? -32767 : 32767);
    }
    wav_state ^= 1;
}

static void wav_bit(uint8_t bit)
{
    /* 1200 baud @ 44100 sample rate */
    int len = bit ? 18 : 37;

    wav_signal(len);
    if (bit) wav_signal(len);
}

static void wav_byte(uint8_t b)
{
    uint8_t bit = 0x80;

    while (bit) {
        wav_bit(!!(b & bit));
        bit >>= 1;
    }
}

static int orter_eg2000_cas_to_wav(void)
{
    int b;

    /* validate header */
    b = getchar();
    if (b != 0x66) {
        fprintf(stderr, "expected 0x66\n");
        return 1;
    }

    orter_wav_start();

    /* leader */
    wav_state = 0;
    for (b = 256; b; --b) {
        wav_byte(0xAA);
    }
    wav_byte(0xA5);
    /* data */
    wav_byte(0x66);
    while ((b = getchar()) != EOF) {
        wav_byte(b);
    }

    orter_wav_end();
    return 0;
}

int orter_eg2000(int argc, char *argv[])
{
    if (argc == 7 && !strcmp(argv[2], "bin") && !strcmp(argv[3], "to") && !strcmp(argv[4], "cmd")) {
        return orter_eg2000_bin_to_cmd(strtol(argv[5], 0, 0), strtol(argv[6], 0, 0));
    }
    if (argc == 6 && !strcmp(argv[2], "cmd") && !strcmp(argv[3], "to") && !strcmp(argv[4], "cas")) {
        return orter_eg2000_cmd_to_cas(argv[5]);
    }
    if (argc == 5 && !strcmp(argv[2], "cas") && !strcmp(argv[3], "to") && !strcmp(argv[4], "wav")) {
        return orter_eg2000_cas_to_wav();
    }

    /* usage */
    fprintf(stderr, "Usage: orter eg2000 bin to cmd\n");
    fprintf(stderr, "Usage:              cmd to cas <filename>\n");
    fprintf(stderr, "                    cas to wav\n");
    return 1;
}
