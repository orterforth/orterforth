#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>

#include "rf.h"
#include "persci.h"

/* use heap memory */
char *rf_origin = 0;

/* auto command for boot purposes */
char *rf_system_auto_cmd = 0;

void rf_init(void)
{
  /* allocate memory */
  rf_origin = malloc(RF_MEMORY_SIZE);
  if (!rf_origin) {
    perror("memory init failed");
    exit(1);
  }
}

void rf_code_emit(void)
{
  RF_START;
  {
    uint8_t c = RF_SP_POP & 0x7F;

    putchar(c);

    /* backspace erase */
    if (c == 0x08) {
      putchar(' ');
      putchar(c);
    }

    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}

static struct termios tp, save;

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    if (rf_system_auto_cmd && *rf_system_auto_cmd) {
      /* read auto boot command */
      c = *(rf_system_auto_cmd++);
    } else {

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

      /* get key */
      c = fgetc(stdin);

      if (isatty(0)) {
        /* restore terminal settings */
        if (tcsetattr(0, TCSANOW, &save) == -1) {
          perror("tcsetattr failed");
          exit(1);
        }
      }

      /* exit if eof */
      if (c == -1) {
        exit(0);
      }

      /* LF to CR */
      if (c == 10) {
        c = 13;
      }
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
  int c;

  for (; len; --len) {
    c = rf_persci_getc();
    if (c == -1) {
      break;
    }
    *(p++) = c;
    if (c == 0x04) {
      break;
    }
  }
}

void rf_disc_write(char *p, uint8_t len)
{
  for (; len; --len) {
    if (rf_persci_putc(*(p++)) == -1) {
      fprintf(stderr, "rf_persci_putc invalid state\n");
      exit(1);
    }
  }
}

void rf_fin(void)
{
  /* free memory */
  if (rf_origin) {
    free(rf_origin);
  }
}
