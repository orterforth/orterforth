/* Z88 */
#define RF_TARGET_HI 0x0000
#define RF_TARGET_LO 0xB258

/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* LOMEM */
#define RF_LIMIT 0xB000
