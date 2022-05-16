/* SYSTEM TARGET = HOST PLATFORM */

/* disc impl is process local; insert and eject the inst disc */
#define RF_INST_LOCAL_DISC

/* RP and SP operations inline, code is larger but faster */
#define RF_INLINE_RP
#define RF_INLINE_SP

/* hide output during inst time */
#define RF_INST_SILENT

/* uncouple inst time code */
#define RF_INST_OVERWRITE

/* allocated memory is proportional to word size */
#define RF_MEMORY_SIZE (65536*RF_WORD_SIZE)

/* points to start of memory, whether heap or static */
extern char *rf_memory;

/* ORIGIN at start of memory */
#define RF_ORIGIN (rf_memory)

/* LIMIT at end of memory */
#define RF_LIMIT ((char *) rf_memory + RF_MEMORY_SIZE)

/* assembly code definitions */
#define RF_TARGET_TRAMPOLINE
#define RF_TARGET_NEXT
#define RF_TARGET_CODE_LIT
#define RF_TARGET_CODE_EXEC
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
#define RF_TARGET_CODE_DMINUS
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
