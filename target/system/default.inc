/* SYSTEM TARGET = HOST PLATFORM */

/* disc impl is process local; insert and eject the inst disc */
#define RF_INST_LOCAL_DISC

/* accept command line arguments */
#ifndef PICO
#define RF_ARGS
#endif

/* RP and SP operations inline, code is larger but faster */
#define RF_INLINE_RP
#define RF_INLINE_SP

/* hide output during inst time */
#define RF_INST_SILENT

/* uncouple inst time code */
#define RF_INST_OVERWRITE

/* allocated memory is proportional to word size */
#define RF_MEMORY_SIZE (32768*RF_WORD_SIZE)

/* points to start of memory, whether heap or static */
extern char *rf_memory;

/* ORIGIN at start of memory */
#define RF_ORIGIN (rf_memory)

/* LIMIT at end of memory */
#define RF_LIMIT ((char *) rf_memory + RF_MEMORY_SIZE)

/* no assembly code definitions */
