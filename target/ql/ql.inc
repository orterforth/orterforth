/* QL */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x000003bd

/* saves the install to disc 1 */
#define RF_INST_SAVE

/* links code fields to the loaded job on startup */
#define RF_INST_LINK

/* memory limit from SV_RAMT */
extern char *rf_limit;

#define RF_LIMIT (rf_limit)

/* because RF_LIMIT is dynamic */
#define RF_INST_DYNAMIC

/* small by default (256 bytes) */
#define RF_STACK_SIZE 64

/* small by default (256 bytes) */
#define RF_RETURN_STACK_SIZE 64
