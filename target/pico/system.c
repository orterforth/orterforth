#include <stdio.h>
#include <stdlib.h>

/*#include "pico/stdlib.h"*/
#include "../../rf.h"
#include "../../persci.h"

/* use heap memory */
char *rf_origin = 0;

/* auto command for boot purposes */
char *rf_system_auto_cmd = 0;

void rf_init(void)
{
  /* init UART */
  stdio_init_all();

  /* allocate memory */
  rf_origin = malloc(RF_MEMORY_SIZE);
  if (!rf_origin) {
    /* TODO loop forever for visibility */
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

void rf_code_key(void)
{
  RF_START;
  {
    int c;

    if (rf_system_auto_cmd && *rf_system_auto_cmd) {
      c = *(rf_system_auto_cmd++);
    } else {

      /* get key */
      c = getchar();

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

char rf_system_local_disc = 1;

void rf_disc_read(char *p, uint8_t len)
{
  if (rf_system_local_disc) {
    for (; len; --len) {
      *(p++) = rf_persci_getc();
    }
  } else {
    for (; len; --len) {
      *(p++) = getchar() & 0x7F;
    }
  }
}

void rf_disc_write(char *p, uint8_t len)
{
  if (rf_system_local_disc) {
    for (; len; --len) {
      if (rf_persci_putc(*(p++)) == -1) {
        /* TODO loop forever for visibility */
        fprintf(stderr, "rf_persci_putc invalid state\n");
        exit(1);
      }
    }
  } else {
    for (; len; --len) {
      putchar(*(p++) | 0x80);
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
