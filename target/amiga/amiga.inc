/* AMIGA */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x011050EA

extern char *rf_origin;

#define RF_ORIGIN (rf_origin)

#define RF_MEMORY_SIZE 131072

#define RF_LIMIT (rf_origin + RF_MEMORY_SIZE)

#define RF_BS 0x00000008

#define RF_INST_DYNAMIC

#define RF_INST_SAVE

#define RF_INST_LINK
