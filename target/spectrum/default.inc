/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Unlink inst time dictionary entries and leave them to be overwritten */
#define RF_INST_OVERWRITE

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* RF_ORIGIN is defined at command line */

/* disc buffers occupy high memory and finish at 0xFFFF */
/* other addresses work back from these */
#define RF_LIMIT 0x0000

/* BS character */
#define RF_BS 0x000C

/* skip C based definitions of functions defined in Z80 assembler */
#define RF_TARGET_TRAMPOLINE
#define RF_TARGET_CODE_LIT
#define RF_TARGET_NEXT
#define RF_TARGET_CODE_EXEC
#define RF_TARGET_CODE_BRAN
#define RF_TARGET_CODE_ZBRAN
#define RF_TARGET_CODE_XLOOP
#define RF_TARGET_CODE_XPLOO
#define RF_TARGET_CODE_XDO
#define RF_TARGET_CODE_DODOE
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
#define RF_TARGET_CODE_SPAT
#define RF_TARGET_CODE_SPSTO
#define RF_TARGET_CODE_RPSTO
#define RF_TARGET_CODE_SEMIS
#define RF_TARGET_CODE_LEAVE
#define RF_TARGET_CODE_TOR
#define RF_TARGET_CODE_FROMR
#define RF_TARGET_CODE_ZEQU
#define RF_TARGET_CODE_ZLESS
#define RF_TARGET_CODE_PLUS
#define RF_TARGET_CODE_DPLUS
#define RF_TARGET_CODE_MINUS
#define RF_TARGET_CODE_DMINU
#define RF_TARGET_CODE_OVER
#define RF_TARGET_CODE_DROP
#define RF_TARGET_CODE_SWAP
#define RF_TARGET_CODE_DUP
#define RF_TARGET_CODE_PSTOR
#define RF_TARGET_CODE_TOGGL
#define RF_TARGET_CODE_AT
#define RF_TARGET_CODE_CAT
#define RF_TARGET_CODE_STORE
#define RF_TARGET_CODE_CSTOR
#define RF_TARGET_CODE_DOCOL
#define RF_TARGET_CODE_DOCON
#define RF_TARGET_CODE_DOVAR
#define RF_TARGET_CODE_DOUSE
#define RF_TARGET_CODE_CELL
#define RF_TARGET_CODE_CELLS
#define RF_TARGET_CODE_STOD
#define RF_TARGET_CODE_COLD
#define RF_TARGET_CODE_TARGET
