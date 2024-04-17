/* BBC */
#define RF_TARGET_HI 0x0000
#define RF_TARGET_LO 0x3948

/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

#ifndef RF_ASSEMBLY

/* default parameter stack below TIB */
/*#define RF_S0 xxxx*/

/* default return stack below user space */
/*#define RF_R0 xxxx*/

/* default user space below disc buffers */
/*#define RF_USER xxxx*/

/* default TIB below return stack */
/*#define RF_TIB xxxx*/

/* disc buffers below MODE 7 screen memory */
/* and below C stack if this is at 0x7C00 */
#define RF_LIMIT 0x7B00

#endif

#ifdef RF_ASSEMBLY

/* for parameter stack, use zero page; assembly code will use X as SP */
#define RF_S0 0x0070
#define RF_STACK_SIZE 0x0027

/* for return stack, reserve some space above the stack used by the calling C */
#define RF_R0 0x01C0
#define RF_RETURN_STACK_SIZE 0x005F

/* for user space, use the BASIC workspace */
#define RF_USER 0x0480

/* for TIB, use the BASIC text input buffer area at 0x0700 */
#define RF_TIB 0x0700
/* alternatively can use top of return stack */
/*#define RF_TIB 0x0100*/

/* place disc buffers before origin */
#define RF_LIMIT RF_ORG

#endif