/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

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

/* C code start address */
#define RF_ORG 0x1720

/* origin passed in command line, follows the C code */
/*#define RF_ORIGIN xxxx*/

/* no assembly definitions */
