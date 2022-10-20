/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Save result to disc 1 after inst */
#undef RF_INST_SAVE

#define RF_ORG 0x4082

#define RF_ORIGIN 0x6D00

#define RF_LIMIT 0x7F00
