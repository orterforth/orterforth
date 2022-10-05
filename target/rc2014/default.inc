#undef RF_INST_LOCAL_DISC

/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* stay quiet during inst (for now) */
#define RF_INST_SILENT

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

#define RF_ORG 0x9000

/* TODO look at .map file to work out high water mark */
#define RF_ORIGIN 0xBF00

/*
#define RF_ORIGIN 0xC300
*/
/* disc buffers leave space for stack in high memory */
#define RF_LIMIT 0xFD00
