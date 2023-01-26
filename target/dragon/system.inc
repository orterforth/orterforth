/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

#define RF_INST_SAVE

/* backspace key */
#define RF_BS 0x0008

/* C code start address */
#define RF_ORG 0x0600

/* Forth ORIGIN start address */
#define RF_ORIGIN 0x3300

/* End of disc buffers and usable RAM */
#define RF_LIMIT 0x7E00

/* assembly code definitions */
#ifdef RF_ASSEMBLY
#define RF_TARGET_TRAMPOLINE
#define RF_TARGET_NEXT
#define RF_TARGET_CODE_SPAT
#define RF_TARGET_CODE_LIT
#define RF_TARGET_CODE_EXEC
#define RF_TARGET_CODE_ZBRAN
#define RF_TARGET_CODE_BRAN
#define RF_TARGET_CODE_DIGIT
#define RF_TARGET_CODE_PFIND
#define RF_TARGET_CODE_ENCL
#define RF_TARGET_CODE_CMOVE
#define RF_TARGET_CODE_USTAR
#define RF_TARGET_CODE_USLAS
#define RF_TARGET_CODE_ANDD
#define RF_TARGET_CODE_ORR
#define RF_TARGET_CODE_XORR
#define RF_TARGET_CODE_PLUS
#define RF_TARGET_CODE_DPLUS
#define RF_TARGET_CODE_MINUS
#define RF_TARGET_CODE_DMINU
#endif
