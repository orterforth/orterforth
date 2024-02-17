#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#include <unistd.h>
#endif
#include "rf.h"
#include "persci.h"

/* use heap memory */
char *rf_origin = 0;

/* auto command for boot purposes */
char *rf_system_auto_cmd = 0;

#ifdef _WIN32
static HANDLE hstdin;

static DWORD stdin_type;
#else
static int stdin_isatty;

static struct termios tp, save;
#endif

void rf_init(void)
{
  /* allocate memory */
  rf_origin = malloc(RF_MEMORY_SIZE);
  if (!rf_origin) {
    perror("memory init failed");
    exit(1);
  }

#ifdef _WIN32
  /* Windows console */
  hstdin = GetStdHandle(STD_INPUT_HANDLE);
  stdin_type = GetFileType(hstdin);
  if (stdin_type == FILE_TYPE_CHAR) {
    DWORD mode = 0;
    GetConsoleMode(hstdin, &mode);
    SetConsoleMode(hstdin, mode & (~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT)));
  }
#else
  /* Unix console */
  stdin_isatty = isatty(0);
#endif
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

void rf_code_key(void)
{
  RF_START;
  {
#ifdef _WIN32
    uint8_t c;
    long unsigned int char_read = 0;
#else
    int c;
#endif

    if (rf_system_auto_cmd && *rf_system_auto_cmd) {
      /* read auto boot command */
      c = *(rf_system_auto_cmd++);
    } else {
      /* get key */
#ifdef _WIN32
      if (stdin_type == FILE_TYPE_CHAR) {
        ReadConsole(hstdin, &c, 1, &char_read, NULL);
      } else {
        ReadFile(hstdin, &c, 1, &char_read, NULL);
      }
      /* exit if eof */
      if (char_read == 0) {
        exit(0);
      }
#else
      if (stdin_isatty) {
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
      c = fgetc(stdin);
      if (stdin_isatty) {
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
#endif
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

void rf_code_dchar(void)
{
  RF_START;
  {
    char a, c;

    a = (char) RF_SP_POP;
    c = rf_persci_getc();
    RF_SP_PUSH(c == a);
    RF_SP_PUSH(c);
  }
  RF_JUMP_NEXT;
}

void rf_code_bread(void)
{
  RF_START;
  {
    int c, len;
    uint8_t *p = (uint8_t *) RF_SP_POP;

    for (len = RF_BBLK; len; --len) {
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
  RF_JUMP_NEXT;
}

void rf_code_bwrit(void)
{
  RF_START;
  {
    uint8_t a = (uint8_t) RF_SP_POP;
    char *b = (char *) RF_SP_POP;

    for (; a; --a) {
      if (rf_persci_putc(*(b++)) == -1) {
        fprintf(stderr, "rf_persci_putc invalid state\n");
        exit(1);
      }
    }

    if (rf_persci_putc(0x04) == -1) {
      fprintf(stderr, "rf_persci_putc invalid state\n");
      exit(1);
    }
  }
  RF_JUMP_NEXT;
}

void rf_fin(void)
{
  /* free memory */
  if (rf_origin) {
    free(rf_origin);
  }
}
