/* DRAGON */
#define RF_TARGET_HI 0x3195
#define RF_TARGET_LO 0xC1F7

/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* backspace key */
#define RF_BS 0x0008

/* save to DR1 once installed */
#define RF_INST_SAVE

/* End of disc buffers and usable RAM */
#define RF_LIMIT 0x7E80

/* C code start address */
/* passed in command line */
/*#define RF_ORG 0xxxxx*/

/* Forth ORIGIN start address */
/* passed in command line */
/*#define RF_ORIGIN 0xxxxx*/

/* assembly code definitions */
#ifdef RF_ASSEMBLY
#define RF_TARGET_FP
#define RF_TARGET_IP
#define RF_TARGET_RP
#define RF_TARGET_SP
#define RF_TARGET_UP
#define RF_TARGET_W
#define RF_TARGET_TRAMPOLINE
#define RF_TARGET_CODE_DOCOL
#define RF_TARGET_NEXT
#define RF_TARGET_CODE_SEMIS
#define RF_TARGET_CODE_EXEC
#define RF_TARGET_CODE_SPAT
#define RF_TARGET_CODE_SPSTO
#define RF_TARGET_CODE_RPSTO
#define RF_TARGET_CODE_LIT
#define RF_TARGET_CODE_BRAN
#define RF_TARGET_CODE_ZBRAN
#define RF_TARGET_CODE_XLOOP
#define RF_TARGET_CODE_XPLOO
#define RF_TARGET_CODE_XDO
#define RF_TARGET_CODE_RR
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
#define RF_TARGET_CODE_LEAVE
#define RF_TARGET_CODE_TOR
#define RF_TARGET_CODE_FROMR
#define RF_TARGET_CODE_OVER
#define RF_TARGET_CODE_DROP
#define RF_TARGET_CODE_SWAP
#define RF_TARGET_CODE_DUP
#define RF_TARGET_CODE_PSTOR
#define RF_TARGET_CODE_AT
#define RF_TARGET_CODE_CAT
#define RF_TARGET_CODE_STORE
#define RF_TARGET_CODE_CSTOR
#define RF_TARGET_CODE_DODOE
#define RF_TARGET_CODE_TOGGL
#define RF_TARGET_CODE_DOCON
#define RF_TARGET_CODE_DOVAR
#define RF_TARGET_CODE_DOUSE
#define RF_TARGET_CODE_COLD
#define RF_TARGET_CODE_CL
#define RF_TARGET_CODE_CS
#define RF_TARGET_CODE_LN
#define RF_TARGET_CODE_MON
#define RF_TARGET_CODE_EMIT
#define RF_TARGET_CODE_KEY
#define RF_TARGET_CODE_CR
#define RF_TARGET_CODE_QTERM
#define RF_TARGET_CODE_DCHAR
#define RF_TARGET_CODE_BREAD
#define RF_TARGET_CODE_BWRIT
#endif
