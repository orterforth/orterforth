#define RF_INST_OVERWRITE

/* saves the install to disc 1 */
#define RF_INST_SAVE

/* links code fields to the loaded job on startup */
#define RF_INST_RELINK

/* assembly code small enough to reserve 72 KB */
/*#define RF_ORIGIN 188416*/
#define RF_ORIGIN 196608

/* memory limit on unexpanded QL */
#define RF_LIMIT 262144

/* small by default (256 bytes) */
#define RF_STACK_SIZE 64

/* small by default (256 bytes) */
#define RF_RETURN_STACK_SIZE 64

/* assembly code definitions */
#define RF_TARGET_TRAMPOLINE
#define RF_TARGET_CODE_LIT
#define RF_TARGET_NEXT
#define RF_TARGET_CODE_EXEC
#define RF_TARGET_CODE_BRAN
#define RF_TARGET_CODE_ZBRAN
#define RF_TARGET_CODE_XLOOP
#define RF_TARGET_CODE_XPLOO
#define RF_TARGET_CODE_XDO
#define RF_TARGET_CODE_CMOVE
/*#define RF_TARGET_CODE_USTAR*/
/*#define RF_TARGET_CODE_USLAS*/
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
#define RF_TARGET_CODE_MINUS
#define RF_TARGET_CODE_DPLUS
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
#define RF_TARGET_CODE_STOD
#define RF_TARGET_CODE_RCLL
#define RF_TARGET_CODE_RCLS
/* there is no dpush so we define this */
#define RF_TARGET_CODE_RTGT
