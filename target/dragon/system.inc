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
#define RF_TARGET_CODE_DOCOL
#define RF_TARGET_NEXT
#define RF_TARGET_CODE_SEMIS
#define RF_TARGET_CODE_EXEC
#define RF_TARGET_CODE_SPAT
#define RF_TARGET_CODE_LIT
#define RF_TARGET_CODE_ZBRAN
#define RF_TARGET_CODE_BRAN
#define RF_TARGET_CODE_XLOOP
#define RF_TARGET_CODE_XPLOO
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
#define RF_TARGET_CODE_STOD
#define RF_TARGET_CODE_ZEQU
#define RF_TARGET_CODE_ZLESS
#define RF_TARGET_CODE_OVER
#define RF_TARGET_CODE_DROP
#define RF_TARGET_CODE_SWAP
#define RF_TARGET_CODE_DUP
#define RF_TARGET_CODE_PSTOR
#define RF_TARGET_CODE_AT
#define RF_TARGET_CODE_CAT
#define RF_TARGET_CODE_STORE
#define RF_TARGET_CODE_CSTOR
/*#define RF_TARGET_CODE_TOGGL*/
#define RF_TARGET_CODE_DOCON
#define RF_TARGET_CODE_DOVAR
#define RF_TARGET_CODE_DOUSE
#endif
