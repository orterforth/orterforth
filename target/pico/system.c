#include <stdio.h>

/*#include "pico/stdlib.h"*/
#include "../../mux.h"
#include "../../rf.h"
#include "../../persci.h"

/* use heap memory */
char *rf_origin = 0;

void rf_init(void)
{
  /* init UART */
  stdio_init_all();
/*
  while (!tud_cdc_connected()) {
    sleep_ms(500);
  }
*/
  /* allocate memory */
  rf_origin = malloc(RF_MEMORY_SIZE);
  /* on failure, repeat message */
  if (!rf_origin) {
    for (;;) {
      perror("memory init failed");
      sleep_ms(1000);
    }
  }
}

char rf_system_local_disc = 1;

void rf_disc_read(char *p, uint8_t len)
{
  if (rf_system_local_disc) {
    for (; len; --len) {
      *(p++) = rf_persci_getc();
    }
  } else {
    rf_mux_disc_read(p, len);
  }
}

void rf_disc_write(char *p, uint8_t len)
{
  if (rf_system_local_disc) {
    for (; len; --len) {
      if (rf_persci_putc(*(p++)) == -1) {
        /* on failure, repeat message */
        for (;;) {
          fprintf(stderr, "rf_persci_putc invalid state\n");
          sleep_ms(1000);
        }
      }
    }
  } else {
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
