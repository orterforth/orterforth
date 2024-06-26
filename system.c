#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#include <unistd.h>
#endif

#include "persci.h"
#include "rf.h"

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

void rf_console_put(uint8_t b)
{
  putchar(b);
  /* backspace erase */
  if (b == 0x08) {
    putchar(' ');
    putchar(b);
  }
}

uint8_t rf_console_get(void)
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
  return c;
}

uint8_t rf_console_qterm(void)
{
  return 0;
}

void rf_console_cr(void)
{
  putchar('\n');
}

uint8_t rf_serial_get(void)
{
  return (uint8_t) rf_persci_getc();
}

void rf_serial_put(uint8_t b)
{
  rf_persci_putc(b);
}

void rf_fin(void)
{
  /* free memory */
  if (rf_origin) {
    free(rf_origin);
  }
}
