#ifdef __unix__
#define _DEFAULT_SOURCE
#define _XOPEN_SOURCE 500
#endif
#include <errno.h>
#include <fcntl.h>
#ifdef __unix__
#include <pty.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>
#ifdef __MACH__
#include <util.h>
#endif

#include "io.h"
#include "pty.h"

int orter_pty_master_fd = -1;
static int orter_pty_slave_fd = -1;
static char *orter_pty_link = 0;

int orter_pty_close(void)
{
    int ret = errno;

    /* link */
    if (orter_pty_link && unlink(orter_pty_link)) {
        perror("unlink failed");
    }
    /* fds */
    if (orter_pty_master_fd != -1 && close(orter_pty_master_fd)) {
        perror("close master failed");
    }
    orter_pty_master_fd = -1;
    if (orter_pty_slave_fd != -1 && close(orter_pty_slave_fd)) {
        perror("close slave failed");
    }
    orter_pty_slave_fd = -1;

    return ret;
}

int orter_pty_open(char *link)
{
    char *name;
    struct termios attr;

    /* validate not yet open */
    if (orter_pty_master_fd != -1) {
        fprintf(stderr, "master already open");
        return 1;
    }
    if (orter_pty_slave_fd != -1) {
        fprintf(stderr, "slave already open");
        return 1;
    }

    /* open */
    cfmakeraw(&attr);
    if (openpty(&orter_pty_master_fd, &orter_pty_slave_fd, 0, &attr, 0)) {
        perror("openpty failed");
        return errno;
    }
    if (fcntl(orter_pty_master_fd, F_SETFL, O_NOCTTY | O_NONBLOCK)) {
        perror("fcntl failed");
        return orter_pty_close();
    }

    /* link pts */
    if (link) {
        name = ptsname(orter_pty_master_fd);
        if (!name) {
            perror("ptsname failed");
            return orter_pty_close();
        }
        if (symlink(name, link)) {
            perror("symlink failed");
            return orter_pty_close();
        }
        orter_pty_link = link;
    }

    return 0;
}

int orter_pty(char *name)
{
    int ret;

    orter_io_pipe_t pipes[2];
    orter_io_pipe_t *p[2];

    /* init */
    if ((ret = orter_io_std_open())) {
        return ret;
    }
    if ((ret = orter_pty_open(name))) {
        orter_io_std_close();
        return ret;
    }
    orter_io_pipe_init(&pipes[0], 0, 0, 0, orter_pty_master_fd);
    orter_io_pipe_init(&pipes[1], orter_pty_master_fd, 0, 0, 1);

    /* run */
    p[0] = &pipes[0];
    p[1] = &pipes[1];
    ret = orter_io_pipe_loop(p, 2);

    /* finally */
    orter_pty_close();
    orter_io_std_close();

    return ret;
}
