#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "z88.h"

/* TODO move to util */
static int hex(char c)
{
    if (c >= '0' && c <= '9') {
        return c - '0';
    }
    if (c >= 'A' && c <= 'F') {
        return c - '7';
    }
    return -1;
}

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
                    c = hex(h) << 4;
                    GETCHAR(h);
                    c += hex(h);
                    if (state == STATE_FILEDATA) {
                        PUTCHAR(c);
                    } else if (state == STATE_FILENAME) {
                        fputc(c, stderr);
                    }
                    break;

                /* end file */
                case 'E':
                    /* TODO handling multiple files */
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
        
        /* unescaped */
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
    if (c >= 0x20 && c <= 0x7E) {
        /* write unescaped */
        PUTCHAR(c);
    } else {
        /* write escaped */
        if (printf("\033B%02X", c) < 0) {
            perror("printf failed");
            return errno;
        }            
    }

    return 0;
}

#define PUTS(s) if (fputs((s), stdout) < 0) { perror("fputs failed"); return errno; }

static int orter_z88_impexport_write(char *filename)
{
    int r;
    int c;

    PUTS("\033N");
    while (*filename) {
        if ((r = orter_z88_impexport_putchar(*(filename++)))) {
            return r;
        }
    }
    PUTS("\033F");

    for (;;) {

        /* read byte */
        if ((c = getchar()) == -1) {
            if (feof(stdin)) {
                fputs("\033E", stdout);
                return 0;
            } else {
                perror("getchar failed");
                return errno;
            }
        }

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
    /* filename e.g. :RAM.0/KARMA */
    return orter_z88_impexport_write(argv[4]);
  }

  fprintf(stderr, "Usage: orter z88 imp-export read\n");
  fprintf(stderr, "                            write <filename>\n");
  return 1;
}
