/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* space is tight so we move the inst code back for now */
#define RF_INST_DICTIONARY (RF_ORIGIN + (1000*RF_WORD_SIZE))

/* For now, don't save result to disc 1 after inst */
#undef RF_INST_SAVE

/* Passed in command line */
/*#define RF_ORG xxxx*/

/* Passed in command line */
/*#define RF_ORIGIN xxxx*/

#define RF_LIMIT 0x7F00
