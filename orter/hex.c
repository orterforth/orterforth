#include <stdio.h>

static int hex_getdigit(void)
{
  int c;

  for (;;) {
    c = getchar();

    /* EOF */
    if (c == -1) {
      return c;
    }

    /* convert */
    if (c >= '0' && c <= '9') {
      return c - 48;
    }
    if (c >= 'A' && c <= 'F') {
      return c - 55;
    }
    if (c >= 'a' && c <= 'f') {
      return c - 87;
    }

    /* ignore non-digits */
  }

  return c;
}

int orter_hex_include(char *name)
{
  unsigned int i;
  int c;

  printf("unsigned char %s[] = {", name);

  /* loop until EOF */
  for (i = 0;;i++) {
    c = getchar();
    if (c == -1) {
      break;
    }
    if (i) {
      putchar(',');
    }
    if (i % 12 == 0) {
      printf("\n  ");
    } else {
      putchar(' ');
    }
    printf("0x%02x", c);
  }

  printf("\n};\nunsigned int %s_len = %u;\n", name, i);

  return 0;
}

/* read hex, write binary */
int orter_hex_read(void)
{
  int b, c;

  /* loop until EOF */
  for (b = 0;;) {
    /* high digit */
    c = hex_getdigit();
    if (c == -1) {
      break;
    }
    b = c << 4;

    /* low digit */
    c = hex_getdigit();
    if (c == -1) {
      fprintf(stderr, "odd number of digits\n");
      return 1;
    }
    b |= c;

    /* write byte */
    if (putchar(b) == -1) {
      perror("putchar failed");
      return 1;
    }
  }

  return 0;
}
