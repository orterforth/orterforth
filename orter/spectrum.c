#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io.h"
#include "pty.h"
#include "spectrum.h"

static orter_io_pipe_t pin;
static orter_io_pipe_t pout;
static orter_io_pipe_t cin;
static orter_io_pipe_t cout;
static orter_io_pipe_t *pipes[4] = {&pin, &pout, &cin, &cout};

static int esc = 0;
static int esc2 = 0;
static int dtr = 1;
static int cts = 1;

static void fuse_log(char *message)
{
  fprintf(stderr, "fuse: %s\n", message);
}

static void process(void)
{
  int c;

  /* read from Fuse */
  while (orter_io_pipe_left(&pout) && (c = orter_io_pipe_get(&cin)) != -1) {

    /* escaped tx */
    if (esc) {
      esc = 0;
      if (c == 0) {
        dtr = 1;
        fuse_log("DTR low");
        continue;
      }
      if (esc && c == 1) {
        dtr = 0;
        fuse_log("DTR high");
        continue;
      }
      if (esc && c == 2) {
        cts = 1;
        fuse_log("CTS low");
        continue;
      }
      if (esc && c == 3) {
        cts = 0;
        fuse_log("CTS high");
        continue;
      }
      if (esc && c == 42) {
        c = 0;
      }
      if (esc && c == 63) {
        fuse_log("lost");
        continue;
      }
    } else if (c == 0) {
      esc = 1;
      continue;
    }

    /* from tx */
    if (orter_io_pipe_put(&pout, c) == -1) {
      fuse_log("put to pty failed");
      break;
    }
  }

  /* write to Fuse */
  while (cts && dtr && orter_io_pipe_left(&cout)) {

    /* escaped rx */
    if (esc2) {
      if (orter_io_pipe_put(&cout, 42) == -1) {
        fuse_log("put * to stdout failed");
        break;
      }
      esc2 = 0;
      continue;
    }

    /* to rx */
    if ((c = orter_io_pipe_get(&pin)) == -1) {
      break;
    }
    if (orter_io_pipe_put(&cout, c) == -1) {
      fuse_log("put to stdout failed");
      break;
    }
    if (c == 0) {
      esc2 = 1;
    }
  }
}

static int orter_spectrum_fuse_serial_pty(char *pty)
{
  int exit = 0;

  /* open pty */
  exit = orter_pty_open(pty);
  if (exit) {
    return exit;
  }
  exit = orter_io_std_open();
  if (exit) {
    orter_io_std_close();
    return exit;
  }

  /* create pipelines */
  orter_io_pipe_read_init(&pin, orter_pty_master_fd);
  orter_io_pipe_write_init(&pout,orter_pty_master_fd);
  orter_io_pipe_read_init(&cin, 0);
  orter_io_pipe_write_init(&cout, 1);

  /* run server */
  exit = orter_io_pipe_loop(pipes, 4, process);

  /* close and exit */
  orter_io_std_close();
  orter_pty_close();
  return exit;
}

static int orter_spectrum_header(const char *filename, unsigned char type_, unsigned short p1, unsigned short p2)
{
  int c;
  long size;

  /* open file */
  FILE *ptr = fopen(filename, "rb");
  if (!ptr) {
    perror("file not found");
    return errno;
  }

  /* get file size */
  if (orter_io_file_size(ptr, &size)) {
    perror("orter_io_file_size failed");
    return errno;
  }

  /* write header */
  putchar(type_);
  orter_io_put_16le(size);
  orter_io_put_16le(p1);
  orter_io_put_16le(p2);
  putchar(255);
  putchar(255);

  /* write data */
  while ((c = fgetc(ptr)) != -1) {
    if (putchar(c) == -1) {
      perror("write failed");
      return errno;
    }
  };

  /* close file */
  if (fclose(ptr)) {
    perror("fclose failed");
    return errno;
  }

  /* flush output */
  if (fflush(stdout)) {
    perror("fflush failed");
    return errno;
  }

  return 0;
}

int orter_spectrum(int argc, char *argv[])
{
  /* use unbuffered stdin/stdout */
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);

  /* Fuse Emulator serial escape handling */
  if (argc == 6 && !strcmp("fuse", argv[2]) && !strcmp("serial", argv[3]) && !strcmp("pty", argv[4])) {
    return orter_spectrum_fuse_serial_pty(argv[5]);
  }
  /* prepend a file with a header suitable for LOAD *"b" or LOAD *"n" */
  if (argc == 7 && !strcmp("header", argv[2])) {
    return orter_spectrum_header(argv[3], atoi(argv[4]), atoi(argv[5]), atoi(argv[6]));
  }

  /* usage */
  fprintf(stderr, "Usage: orter spectrum header <filename> <type> <p1> <p2>\n");
  fprintf(stderr, "                      fuse serial pty <symlink>\n");
  return 1;
}
