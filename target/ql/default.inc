#define RF_INST_OVERWRITE

#define RF_INST_SAVE

#define RF_INST_RELINK

#define RF_ORIGIN 196608
#define RF_LIMIT 262144
#define RF_STACK_SIZE 64
#define RF_RETURN_STACK_SIZE 64

/* C68 has no 64 bit arithmetic */
#define RF_TARGET_CODE_USLAS
#define RF_TARGET_CODE_USTAR
#define RF_TARGET_CODE_DPLUS
#define RF_TARGET_CODE_DMINU

/* there is no dpush so we define this */
#define RF_TARGET_CODE_RTGT
