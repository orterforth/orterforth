#ifndef RF_H_
#define RF_H_

/* C COMPILER SETTINGS */

#ifndef __SCCZ80
#define __FASTCALL__
#endif

/* Clang */

#ifdef __clang__
#include <stdint.h>
typedef uintptr_t rf_word_t;
#if (__WORDSIZE == 32)

/* 32 bit */
#define RF_WORD_SIZE 4
typedef uint64_t rf_double_t;

#elif (__WORDSIZE == 64)

/* 64 bit */
#define RF_WORD_SIZE 8
typedef __uint128_t rf_double_t;

#endif

#else

/* gcc */

#ifdef __GNUC__

#ifndef QDOS

#include <stdint.h>
typedef uintptr_t rf_word_t;
#if __SIZEOF_POINTER__ == 4

/* 32 bit */
#define RF_WORD_SIZE 4
typedef uint64_t rf_double_t;

#elif __SIZEOF_POINTER__ == 8

/* 64 bit */
#define RF_WORD_SIZE 8
typedef __uint128_t rf_double_t;

#endif

#endif

#endif

#endif

/* TARGET ARCHITECTURE */

/* cc65 */

#ifdef __CC65__
#include <stdint.h>
typedef uintptr_t rf_word_t;
#define RF_WORD_SIZE 2
typedef uint32_t rf_double_t;
#define RF_LE
#ifdef __BBC__
#define RF_TARGET 0x00003948 /* BBC */
#ifndef RF_TARGET_H
#define RF_TARGET_H "target/bbc.h"
#endif
#endif
#endif

/* z88dk */

#ifdef __SCCZ80
#include <stdint.h>
typedef uintptr_t rf_word_t;
#define RF_WORD_SIZE 2
typedef uint32_t rf_double_t;
#define RF_LE
#ifdef SPECTRUM
#define RF_TARGET 0x6774e16f /* SPECTR */
#ifndef RF_TARGET_H
#define RF_TARGET_H "target/spectrum.h"
#endif
#endif
#endif

/* C68 */

#ifdef __C68__
#define RF_WORD_SIZE 4
#define RF_BE
typedef long intptr_t;
typedef unsigned long rf_word_t;
typedef unsigned long long rf_double_t;
#ifdef QDOS
#define RF_TARGET 0x000003bd /* QL */
#endif
#endif

/* modern platforms */

#ifdef __i386__
#define RF_LE
#endif
#ifdef __x86_64__
#define RF_LE
#endif
#ifdef __arm__
#define RF_LE
#endif

#ifdef __CYGWIN__
#define RF_TARGET 0x2eb31a9f /* CYGWIN */
#endif

#ifdef __MACH__
#define RF_TARGET 0x2fee7b5f /* DARWIN */
#endif

#ifdef __linux__
#define RF_TARGET 0x02277e49 /* LINUX */
#endif

#ifdef __MINGW32__
#define RF_TARGET 0x02411d50 /* MINGW */
#endif

#ifdef _WIN32
#define RF_TARGET 0x75327710 /* WINDOW */
#endif

/* DERIVED WORD AND DOUBLE SIZE */

#if (RF_WORD_SIZE == 2)
#define RF_WORD_SIZE_BITS 16
#define RF_DOUBLE_SIZE 4
#define RF_DOUBLE_SIZE_BITS 32
#elif (RF_WORD_SIZE == 4)
#define RF_WORD_SIZE_BITS 32
#define RF_DOUBLE_SIZE 8
#define RF_DOUBLE_SIZE_BITS 64
#elif (RF_WORD_SIZE == 8)
#define RF_WORD_SIZE_BITS 64
#define RF_DOUBLE_SIZE 16
#define RF_DOUBLE_SIZE_BITS 128
#endif

/* TARGET SPECIFIC INCLUDE FILE */

#ifdef RF_TARGET_H
#include RF_TARGET_H
#endif

/* OTHERWISE DEFAULT TARGET = HOST PLATFORM */

#ifndef RF_TARGET_H

/* RP and SP operations inline, code is larger but faster */
#define RF_INLINE_RP
#define RF_INLINE_SP

/* hide output during inst time */
#define RF_INST_SILENT

/* uncouple inst time code */
#define RF_INST_OVERWRITE

/* allocated memory is proportional to word size */
#define RF_MEMORY_SIZE (65536*RF_WORD_SIZE)

/* points to start of memory, whether heap or static */
extern char *rf_memory;

/* ORIGIN at start of memory */
#define RF_ORIGIN (rf_memory)

/* LIMIT at end of memory */
#define RF_LIMIT ((char *) rf_memory + RF_MEMORY_SIZE)

#endif

/* DISC BUFFERS */

#define RF_BBLK 128
#define RF_BSCR 8
#define RF_DISC_BUFFER_SIZE (RF_BBLK+2+RF_WORD_SIZE)
#define RF_DISC_BUFFERS_SIZE (8*RF_DISC_BUFFER_SIZE)

/* S0, TIB, R0, USER, FIRST defined in relation to LIMIT */

#define RF_FIRST (RF_LIMIT - RF_DISC_BUFFERS_SIZE)
#define RF_USER ((char *) (RF_FIRST - (32 * RF_WORD_SIZE)))
#define RF_R0 (RF_USER - RF_WORD_SIZE) 
#define RF_RETURN_STACK_SIZE 128
#define RF_TIB (RF_USER - (RF_RETURN_STACK_SIZE * RF_WORD_SIZE))
#define RF_S0 RF_TIB
#define RF_STACK_SIZE 128

/* USER VARIABLES */

#define RF_USER_S0_IDX 3
#define RF_USER_S0 rf_up[RF_USER_S0_IDX]
#define RF_USER_R0_IDX 4
#define RF_USER_R0 rf_up[RF_USER_R0_IDX]
#define RF_USER_TIB_IDX 5
#define RF_USER_TIB rf_up[RF_USER_TIB_IDX]
#define RF_USER_WIDTH_IDX 6
#define RF_USER_WIDTH rf_up[RF_USER_WIDTH_IDX]
#define RF_USER_WARNING_IDX 7
#define RF_USER_WARNING rf_up[RF_USER_WARNING_IDX]
#define RF_USER_FENCE_IDX 8
#define RF_USER_FENCE rf_up[RF_USER_FENCE_IDX]
#define RF_USER_DP_IDX 9
#define RF_USER_DP rf_up[RF_USER_DP_IDX]
#define RF_USER_VOCLINK_IDX 10
#define RF_USER_VOCLINK rf_up[RF_USER_VOCLINK_IDX]
#define RF_USER_BLK_IDX 11
#define RF_USER_BLK rf_up[RF_USER_BLK_IDX]
#define RF_USER_IN_IDX 12
#define RF_USER_IN rf_up[RF_USER_IN_IDX]
#define RF_USER_OUT_IDX 13
#define RF_USER_OUT rf_up[RF_USER_OUT_IDX]
#define RF_USER_OFFSET_IDX 15
#define RF_USER_OFFSET rf_up[RF_USER_OFFSET_IDX]
#define RF_USER_CONTEXT_IDX 16
#define RF_USER_CONTEXT rf_up[RF_USER_CONTEXT_IDX]
#define RF_USER_CURRENT_IDX 17
#define RF_USER_CURRENT rf_up[RF_USER_CURRENT_IDX]
#define RF_USER_STATE_IDX 18
#define RF_USER_STATE rf_up[RF_USER_STATE_IDX]
#define RF_USER_BASE_IDX 19
#define RF_USER_BASE rf_up[RF_USER_BASE_IDX]
#define RF_USER_CSP_IDX 22
#define RF_USER_CSP rf_up[RF_USER_CSP_IDX]

/* FORTH MACHINE */

/* parameter stack pointer */
extern rf_word_t *rf_sp;

#define RF_SP_GET rf_sp
#define RF_SP_SET(a) { rf_sp = (a); }

#ifdef RF_INLINE_SP
#define RF_SP_POP (*(rf_sp++))
#define RF_SP_PUSH(a) { *(--rf_sp) = (a); }
#else
rf_word_t rf_sp_pop(void);

void __FASTCALL__ rf_sp_push(rf_word_t a);

#define RF_SP_POP rf_sp_pop()
#define RF_SP_PUSH(a) rf_sp_push(a)
#endif

/* return stack pointer */
extern rf_word_t *rf_rp;

#define RF_RP_GET rf_rp
#define RF_RP_SET(a) { rf_rp = (a); }

#ifdef RF_INLINE_RP
#define RF_RP_POP (*(rf_rp++))
#define RF_RP_PUSH(a) { *(--rf_rp) = ((rf_word_t) (a)); }
#else
rf_word_t rf_rp_pop(void);

void __FASTCALL__ rf_rp_push(rf_word_t a);

#define RF_RP_POP rf_rp_pop()
#define RF_RP_PUSH(a) { rf_rp_push((rf_word_t) (a)); }
#endif

/* interpretive pointer */
extern rf_word_t *rf_ip;

#define RF_IP_GET rf_ip
#define RF_IP_INC { rf_ip++; }
#define RF_IP_SET(a) { rf_ip = (a); }

/* code field pointer */
typedef void (*rf_code_t)(void);
extern rf_code_t *rf_w;

/* user area pointer */
extern rf_word_t *rf_up;

/* TRAMPOLINE */

/* function pointer */
extern rf_code_t rf_trampoline_fp;

/* start trampoline */
void rf_trampoline(void);

#define RF_JUMP(a) { rf_trampoline_fp = (a); }

/* NEXT */

void rf_next(void);

#define RF_JUMP_NEXT { rf_trampoline_fp = rf_next; }

/* C CODE START - save registers */

void rf_start(void);

#define RF_START rf_start()

/* SYSTEM SPECIFIC */

void rf_init(void);

void __FASTCALL__ rf_out(char c);

void rf_fin(void);

/* UTILITIES */

rf_code_t __FASTCALL__ *rf_cfa(char *nfa);

rf_word_t __FASTCALL__ *rf_lfa(char *nfa);

rf_word_t __FASTCALL__ *rf_pfa(char *nfa);

char *rf_find(char *t, char t_length, char *nfa);

unsigned char rf_digit(char base, char c);

void rf_enclose(char c, char *addr1, unsigned char *s3, unsigned char *s2, unsigned char *s1);

/* COLD START */

extern rf_word_t *rf_cold_forth;

extern rf_word_t *rf_cold_abort;

/* CODE */

void rf_code_lit(void);

void rf_code_exec(void);

void rf_code_bran(void);

void rf_code_zbran(void);

void rf_code_xloop(void);

void rf_code_xploo(void);

void rf_code_xdo(void);

void rf_code_digit(void);

void rf_code_pfind(void);

void rf_code_encl(void);

void rf_code_cmove(void);

void rf_code_ustar(void);

void rf_code_uslas(void);

void rf_code_andd(void);

void rf_code_orr(void);

void rf_code_xorr(void);

void rf_code_spsto(void);

void rf_code_spat(void);

void rf_code_rpsto(void);

void rf_code_semis(void);

void rf_code_leave(void);

void rf_code_tor(void);

void rf_code_fromr(void);

void rf_code_rr(void);

void rf_code_zequ(void);

void rf_code_zless(void);

void rf_code_plus(void);

void rf_code_dplus(void);

void rf_code_minus(void);

void rf_code_dminu(void);

void rf_code_over(void);

void rf_code_drop(void);

void rf_code_swap(void);

void rf_code_dup(void);

void rf_code_pstor(void);

void rf_code_toggl(void);

void rf_code_at(void);

void rf_code_cat(void);

void rf_code_store(void);

void rf_code_cstor(void);

void rf_code_docol(void);

void rf_code_docon(void);

void rf_code_dovar(void);

void rf_code_douse(void);

void rf_code_dodoe(void);

void rf_code_cold(void);

void rf_code_stod(void);

/* FOR EMIT, KEY, CR, ?TERM */

void rf_code_emit(void);

void rf_code_key(void);

void rf_code_qterm(void);

void rf_code_cr(void);

/* DISC */

void rf_disc_read(char *c, unsigned char len);

void rf_disc_write(char *p, unsigned char len);

void rf_disc_flush(void);

void rf_code_bread(void);

void rf_code_bwrit(void);

void rf_code_dchar(void);

/* EXTENSIONS */

void rf_code_cell(void);

void rf_code_cells(void);

void rf_code_code(void);

void rf_code_exit(void);

void rf_code_target(void);

#endif /* RF_H_ */
