/* DRAGON */
#define RF_TARGET_HI 0x3195
#define RF_TARGET_LO 0xC1F7

/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* backspace key */
#define RF_BS 0x0008

/* save to DR1 once installed */
#define RF_INST_SAVE

/* extra room needed for save/reloc buffer/code */
#define RF_INST_DICTIONARY ((RF_ORIGIN) + 6500)

/* End of disc buffers and usable RAM */
#define RF_LIMIT 0x7E80

/* cmoc not handling preprocessor arithmetic as constant */
#define RF_INST_DYNAMIC
