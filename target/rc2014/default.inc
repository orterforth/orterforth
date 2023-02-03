#undef RF_INST_LOCAL_DISC

/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* stay quiet during inst (for now) */
#define RF_INST_SILENT

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* Start of C code */
/*#define RF_ORG xxxx*/

/* Start of Forth origin */
/*#define RF_ORIGIN xxxx*/

/* Offset of C inst code */
/*#define RF_INST_OFFSET xxxx*/

/* end of disc buffers - leave space for C stack in high memory */
#define RF_LIMIT 0xFF00
