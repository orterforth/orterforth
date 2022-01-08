/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Unlink inst time dictionary entries and leave them to be overwritten */
#define RF_INST_OVERWRITE

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* stack in 0-page, assembly code will use X as SP */
#define RF_S0 0x0070
#define RF_STACK_SIZE 0x0037

/* return stack at 0x0600, BBC BASIC uses this page for FOR, GOSUB, REPEAT */
#define RF_R0 0x0600

/* start address */
#define RF_ORG 0x1300

/* follows the C code */
#define RF_ORIGIN 0x4900

/* disc buffers end before HIMEM, in CC65 this is 0x7200 behind stack and MODE 7 screen memory */
#define RF_LIMIT 0x7200
