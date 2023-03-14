/* Z88 */
#define RF_TARGET_HI 0x0000
#define RF_TARGET_LO 0xB258

/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* For now, don't save result to disc 1 after inst */
#undef RF_INST_SAVE

/* Passed in command line */
/*#define RF_ORG xxxx*/

/* Passed in command line */
/*#define RF_ORIGIN xxxx*/

#define RF_LIMIT 0x7F00
