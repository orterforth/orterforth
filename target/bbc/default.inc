/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Unlink inst time dictionary entries and leave them to be overwritten */
#define RF_INST_OVERWRITE

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* for parameter stack, use the BASIC workspace at 0x0700 downwards (string buffer) */
#define RF_S0 0x0700

/* for return stack, use the BASIC workspace at 0x0600 downwards (FOR, RETURN, GOSUB stacks) */
/*#define RF_R0 0x0600*/
/* for return stack, use the BASIC text input buffer at 0x0800 downwards */
#define RF_R0 0x0800

/* for user space, use the BASIC workspace at 0x0400 (integer variables) */
#define RF_USER 0x0400

/* for TIB, use the BASIC text input buffer area at 0x0700 */
#define RF_TIB 0x0700

/* place disc buffers before origin at 0x1300 - 0x1720 */
#define RF_LIMIT 0x1720

/* C code start address */
#define RF_ORG 0x1720

/* origin follows the C code */
#define RF_ORIGIN 0x3000

/* no assembly definitions */
