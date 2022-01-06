/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Unlink inst time dictionary entries and leave them to be overwritten */
#define RF_INST_OVERWRITE

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* start address */
#define RF_ORG 0x1300

/* follows the C code */
#define RF_ORIGIN 0x4900

/* disc buffers end before HIMEM, in CC65 this is 0x7200 behind stack and MODE 7 screen memory */
#define RF_LIMIT 0x7200

/* TODO RP/TIB at 0500-05FF or 0700-07FF */
/* TODO SP at 0400-04FF or 0600-06FF */
