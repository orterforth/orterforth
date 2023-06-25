#include <stdio.h>

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
    for (;;) {
      perror("memory init failed");
      sleep_ms(1000);
    }
  }
}

#ifdef xxxx
void rf_code_emit(void)
{
  RF_START;
  {
    int c = RF_SP_POP & 0x7F;

    /* write char, wait if serial disconnected */
    while (putchar(c) == -1) {
      sleep_ms(1000);
    }

    /* backspace erase */
    if (c == 0x08) {
      putchar(' ');
      putchar(c);
    }

    RF_USER_OUT++;
  }
  RF_JUMP_NEXT;
}
#endif

#ifdef xxxx
void rf_code_key(void)
{
  RF_START;
  {
    int c;

    if (rf_system_auto_cmd && *rf_system_auto_cmd) {
      c = *(rf_system_auto_cmd++);
    } else {

      /* read char, wait if serial disconnected */
      while ((c = fgetc(stdin)) == -1) {
        sleep_ms(1000);
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
#endif

#ifdef xxxx
void rf_code_qterm(void)
{
  RF_START;
  RF_SP_PUSH(0);
  RF_JUMP_NEXT;
}
#endif

#ifdef xxxx
void rf_code_cr(void)
{
  RF_START;
  putchar('\n');
  RF_JUMP_NEXT;
}
#endif

char rf_system_local_disc = 1;

/* TODO mux.h */
void rf_mux_disc_read(char *c, unsigned char len);

void rf_disc_read(char *p, uint8_t len)
{
  if (rf_system_local_disc) {
    for (; len; --len) {
      *(p++) = rf_persci_getc();
    }
  } else {
/*
    for (; len; --len) {
      *(p++) = fgetc(stdin) & 0x7F;
    }
*/
    rf_mux_disc_read(p, len);
  }
}

void rf_mux_disc_write(char *c, unsigned char len);

void rf_disc_write(char *p, uint8_t len)
{
  if (rf_system_local_disc) {
    for (; len; --len) {
      if (rf_persci_putc(*(p++)) == -1) {
        for (;;) {
          fprintf(stderr, "rf_persci_putc invalid state\n");
          sleep_ms(1000);
        }
      }
    }
  } else {
/*
    for (; len; --len) {
      putchar(*(p++) | 0x80);
    }
*/
    rf_mux_disc_write(p, len);
  }
}

void rf_fin(void)
{
  /* free memory */
  if (rf_origin) {
    free(rf_origin);
  }
}
