/* ZX81 */
#define RF_TARGET_HI 0x0019
#define RF_TARGET_LO 0x92f1

/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* space is tight so we move the inst code back for now */
#define RF_INST_DICTIONARY (RF_ORIGIN + (3000*RF_WORD_SIZE))

/* save result to disc 1 after inst */
#define RF_INST_SAVE

/* Leave room for stack etc */
#define RF_LIMIT 0x7F80
