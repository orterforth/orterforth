#ifdef __unix__
#define RF_SYSTEM_POSIX
#endif
#ifdef __MACH__
#define RF_SYSTEM_POSIX
#endif

#include <stdio.h>
#include <stdlib.h>
#ifdef RF_SYSTEM_POSIX
#include <termios.h>
#include <unistd.h>
#endif

#include "rf.h"
#include "rf_persci.h"

/* use heap memory */
char *rf_memory = 0;

void rf_init(void)
{
  /* allocate memory */
  rf_memory = malloc(RF_MEMORY_SIZE);
  if (!rf_memory) {
    perror("memory init failed");
    exit(1);
  }

  /* init disc */
  rf_persci_insert(0, "0.disc");
  rf_persci_insert(1, "1.disc");

#ifdef RF_SYSTEM_POSIX
  /* make sure any output is written before a seg fault */
  if (setvbuf(stdout, NULL, _IONBF, 0)) {
    perror("setvbuf failed");
    exit(1);
  }
#endif
}

extern char rf_installed;

void rf_out(char c)
{
  putchar(c);
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c = RF_SP_POP & 0x7F;

    putchar(c);
    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

void rf_code_key(void)
{
  RF_START;
  {
    int c;

#ifdef RF_SYSTEM_POSIX
    struct termios tp, save;

    if (isatty(0)) {
      /* save terminal settings */
      if (tcgetattr(0, &tp) == -1) {
        perror("tcgetattr failed");
        exit(1);
      }
      save = tp;

      /* turn echo and canonical mode off */
      tp.c_lflag &= ~(ECHO | ICANON);
      if (tcsetattr(0, TCSANOW, &tp) == -1) {
        perror("tcsetattr failed");
        exit(1);
      }
    }
#endif

    /* get key */
    c = fgetc(stdin);

#ifdef RF_SYSTEM_POSIX
    if (isatty(0)) {
      /* restore terminal settings */
      if (tcsetattr(0, TCSANOW, &save) == -1) {
        perror("tcsetattr failed");
        exit(1);
      }
    }
#endif

    /* exit if eof */
    if (c == -1) {
      exit(0);
    }

    /* LF to CR */
    if (c == 10) {
      c = 13;
    }

    /* return key */
    RF_SP_PUSH(c & 0x7F);
  }
  RF_JUMP_NEXT;
}

void rf_code_qterm(void)
{
  RF_START;
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;
}

void rf_code_cr(void)
{
  RF_START;
  putchar('\n');
  RF_JUMP_NEXT;
}

void rf_disc_read(char *p, uint8_t len)
{
  for (; len; --len) {
    *(p++) = rf_persci_getc();
  }
}

void rf_disc_write(char *p, uint8_t len)
{
  for (; len; --len) {
    rf_persci_putc(*(p++));
  }
}

void rf_fin(void)
{
  /* free memory */
  if (rf_memory) {
    free(rf_memory);
  }
}
