/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Unlink inst time dictionary entries and leave them to be overwritten */
#define RF_INST_OVERWRITE

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

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

/* place disc buffers before origin at 0x1300 - 0x1720 */
#define RF_LIMIT 0x1720

/* C code start address */
#define RF_ORG 0x1720

/* origin passed in command line, follows the C code */
/*#define RF_ORIGIN xxxx*/

/* assembly definitions */
#define RF_TARGET_IP
#define RF_TARGET_UP
#define RF_TARGET_W
#define RF_TARGET_TRAMPOLINE
#define RF_TARGET_CODE_LIT
#define RF_TARGET_NEXT
#define RF_TARGET_CODE_EXEC
#define RF_TARGET_CODE_BRAN
#define RF_TARGET_CODE_ZBRAN
#define RF_TARGET_CODE_XLOOP
#define RF_TARGET_CODE_XPLOO
#define RF_TARGET_CODE_XDO
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
#define RF_TARGET_CODE_RR
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
#define RF_TARGET_CODE_DODOE
#define RF_TARGET_CODE_COLD
#define RF_TARGET_CODE_STOD
#define RF_TARGET_CODE_DCHAR
#define RF_TARGET_CODE_BREAD
#define RF_TARGET_CODE_BWRIT
#define RF_TARGET_CODE_RXIT
#define RF_TARGET_CODE_RCLL
#define RF_TARGET_CODE_RCLS
#define RF_TARGET_CODE_RTGT
