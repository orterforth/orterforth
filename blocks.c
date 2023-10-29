#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(exit, function) exit = (function); if (exit) return exit;

#define RF_BBLK 128

static char line[66];

static int lineno = 0;

static int disc_create_line(char *block)
{
  size_t len;

  /* read line from stdin */
  if (!fgets(line, 66, stdin)) {
    if (feof(stdin)) {
      return 0;
    }
    perror("fgets failed");
    return errno;
  }

  /* count lines */
  lineno++;

  /* strip newline */
  len = strlen(line);
  if (line[len - 1] == '\n') {
    --len;
  }
  /* fail if too long */
  if (len > 64) {
    fprintf(stderr, "line %u too long\n", lineno);
    return 1;
  }

  /* write to the block */
  memcpy(block, line, len);

  /* ok */
  return 0;
}

static int disc_create(void)
{
  char block[RF_BBLK];
  int i, status;

  /* 77 tracks x 26 sectors */
  lineno = 0;
  for (i = 0; i < 2002; i++) {

    /* clear buffer with spaces */
    memset(&block, ' ', RF_BBLK);

    /* read two lines */
    CHECK(status, disc_create_line(block));
    CHECK(status, disc_create_line(block + 64));

    /* write block to stdout */
    if (fwrite(block, 1, RF_BBLK, stdout) != RF_BBLK) {
      perror("fwrite failed");
      return errno;
    }
  }

  /* ok */
  return 0;
}

int main(int argc, char *argv[])
{
  /* Text file to Forth block disc image */
  if (argc == 2 && !strcmp("create", argv[1])) {
    return disc_create();
  }

  /* Usage */
  fputs("Usage: blocks create   Convert text file (stdin) into Forth block format (stdout)\n", stderr);
  return 1;
}
