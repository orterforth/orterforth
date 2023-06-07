/* SYSTEM BINDINGS */

void rf_mux_disc_read(char *c, unsigned char len);

void rf_mux_disc_write(char *c, unsigned char len);

void rf_init(void)
{
}

void rf_disc_read(char *c, unsigned char len)
{
  rf_mux_disc_read(c, len);
}

void rf_disc_write(char *c, unsigned char len)
{
  rf_mux_disc_write(c, len);
}

void rf_fin(void)
{
}
