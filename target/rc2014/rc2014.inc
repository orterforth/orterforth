#undef RF_INST_LOCAL_DISC

/* RC2014 */
#define RF_TARGET_HI 0x6284
#define RF_TARGET_LO 0x44a8

/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* pause before beginning inst, to allow disc server to start */
#define RF_INST_WAIT

/* stay quiet during inst (for now) */
#define RF_INST_SILENT

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* end of disc buffers - leave space for C stack in high memory */
#define RF_LIMIT 0xFF00
