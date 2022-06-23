/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Unlink inst time dictionary entries and leave them to be overwritten */
#define RF_INST_OVERWRITE

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

#define RF_ORG 0x9000

/* TODO */
#define RF_ORIGIN 0xBD00

/* disc buffers leave space for stack in high memory */
#define RF_LIMIT 0xFE00
