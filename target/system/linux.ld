/* gcc does not prepend leading underscores, and assembly code expects them */
_rf_fp = rf_fp;
_rf_ip = rf_ip;
_rf_rp = rf_rp;
_rf_sp = rf_sp;
_rf_up = rf_up;
_rf_w = rf_w;

/* conversely, for compatibility across compilers, assembly code must provide 
symbols with and without leading underscores */
