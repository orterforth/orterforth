/* saves the install to disc 1 */
#define RF_INST_SAVE

/* links code fields to the loaded job on startup */
#define RF_INST_LINK

/* default C impl code is larger and no room to reserve from 188416 */
/*#define RF_ORIGIN 188416*/
#define RF_ORIGIN 196608

/* memory limit on unexpanded QL */
#define RF_LIMIT 262144

/* small by default (256 bytes) */
#define RF_STACK_SIZE 64

/* small by default (256 bytes) */
#define RF_RETURN_STACK_SIZE 64

/* no assembly code definitions by default */
