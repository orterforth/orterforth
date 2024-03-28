#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "hex.h"
#include "z88.h"

#define GETCHAR(c) (c) = getchar(); if ((c) == -1 && !feof(stdin)) { perror("getchar failed"); return errno; }
#define PUTCHAR(c) if (putchar(c) < 0) { perror("putchar failed"); return errno; }

#define STATE_START 0
#define STATE_FILENAME 1
#define STATE_FILEDATA 2
#define STATE_DONE 3

static int orter_z88_impexport_read(void)
{
    int c;
    int h;
    int state = STATE_START;

    while (state != STATE_DONE) {

        /* fetch byte */
        GETCHAR(c);

        /* EOF */
        if (c == -1) {
            break;
        }

        /* handle ESC */
        if (c == 27) {
            GETCHAR(c);
            switch (c) {

                /* filename */
                case 'N':
                    state = STATE_FILENAME;
                    break;

                /* file data */
                case 'F':
                    state = STATE_FILEDATA;
                    break;

                /* byte escape */
                case 'B':
                    GETCHAR(h);
                    c = orter_hex_digit(h) << 4;
                    GETCHAR(h);
                    c += orter_hex_digit(h);
                    if (state == STATE_FILEDATA) {
                        PUTCHAR(c);
                    } else if (state == STATE_FILENAME) {
                        fputc(c, stderr);
                    }
                    break;

                /* end file */
                case 'E':
                    state = STATE_START;
                    break;

                /* end batch */
                case 'Z':
                    state = STATE_DONE;
                    break;

                /* unrecognised */
                default:
                    fprintf(stderr, "unrecognised escape 0x1B 0x%02X\n", c);
                    return 1;
                    break;
            }

            continue;
        }
        
        /* write byte (file name or data) */
        if (state == STATE_FILEDATA) {
            PUTCHAR(c);
        } else if (state == STATE_FILENAME) {
            fputc(c, stderr);
        }
    }

    /* finished */
    return 0;
}

static int orter_z88_impexport_putchar(unsigned char c)
{
    /* write unescaped */
    if (c >= 0x20 && c <= 0x7E) {
        PUTCHAR(c);
        return 0;
    }

    /* write escaped */
    if (printf("\033B%02X", c) < 0) {
        perror("printf failed");
        return errno;
    }
    return 0;
}

#define PUTS(s) if (fputs((s), stdout) < 0) { perror("fputs failed"); return errno; }

static int orter_z88_impexport_write(char *filename)
{
    int r;
    int c;

    /* filename */
    PUTS("\033N");
    while (*filename) {
        if ((r = orter_z88_impexport_putchar(*(filename++)))) {
            return r;
        }
    }

    /* file data */
    PUTS("\033F");
    for (;;) {

        /* read byte */
        GETCHAR(c);

        /* EOF */
        if (c == -1) {
            PUTS("\033E");
            return 0;
        }

        /* write byte */
        if ((r = orter_z88_impexport_putchar(c))) {
            return r;
        }
    }

    /* done */
    return 0;
}

int orter_z88(int argc, char **argv)
{
  if (argc == 4 && !strcmp(argv[2], "imp-export") && !strcmp(argv[3], "read")) {
    return orter_z88_impexport_read();
  }

  if (argc == 5 && !strcmp(argv[2], "imp-export") && !strcmp(argv[3], "write")) {
    return orter_z88_impexport_write(argv[4]);
  }

  fprintf(stderr, "Usage: orter z88 imp-export read\n");
  fprintf(stderr, "                            write <filename>\n");
  return 1;
}
