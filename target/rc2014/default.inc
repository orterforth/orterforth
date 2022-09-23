/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

#define RF_ORG 0x9000

/* TODO look at .map file to work out high water mark */
#define RF_ORIGIN 0xC300

/* disc buffers leave space for stack in high memory */
#define RF_LIMIT 0xFE00
