/* SPECTR */
#define RF_TARGET_HI 0x6774
#define RF_TARGET_LO 0xe16f

/* RP and SP operations not inline, code is smaller but slower */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

/* Save result to disc 1 after inst */
#define RF_INST_SAVE

/* disc buffers occupy high memory and finish at 0xFFFF */
/* other addresses work back from these */
#define RF_LIMIT 0x0000

/* BS character */
#define RF_BS 0x000C
