/* RP and SP operations not inline, code is smaller */
#undef RF_INLINE_RP
#undef RF_INLINE_SP

#define RF_INST_SAVE

/* backspace key */
#define RF_BS 0x0008

/* C code start address */
#define RF_ORG 0x0600

/* Forth ORIGIN start address */
#define RF_ORIGIN 0x3800

/* End of disc buffers and usable RAM */
#define RF_LIMIT 0x7D00
