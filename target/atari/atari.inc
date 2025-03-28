#define RF_TARGET_HI 0x0115
#define RF_TARGET_LO 0x25BE
#define RF_BS        0x007E
#define RF_LIMIT     0x9C1F

#ifdef RF_ASSEMBLY

/* for return stack, reserve some space above the stack used by the calling C */
#define RF_R0 0x01C0
#define RF_RETURN_STACK_SIZE 0x005F

/* for TIB, share page with return stack */
#define RF_TIB 0x0100

/* TOS */
#define RF_S0 0x00E0
#define RF_STACK_SIZE 0x0022

#endif

#define RF_INST_SAVE
