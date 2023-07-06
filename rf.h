#ifndef RF_H_
#define RF_H_

/* C COMPILER SETTINGS */

#ifndef __SCCZ80
#define __FASTCALL__
#endif

/* Clang */

#ifdef __clang__
#include <stdint.h>
#if (__WORDSIZE == 32)

/* 32 bit */
#define RF_WORD_SIZE 4
#define RF_DOUBLE_ARITH
typedef uint64_t rf_double_t;
#define RF_ALIGN 4

#elif (__WORDSIZE == 64)

/* 64 bit */
#define RF_WORD_SIZE 8
#define RF_DOUBLE_ARITH
typedef __uint128_t rf_double_t;
#define RF_ALIGN 8

#endif

#else

/* gcc */

#ifdef __GNUC__

#ifndef QDOS

#include <stdint.h>
#if __SIZEOF_POINTER__ == 4

/* 32 bit */
#define RF_WORD_SIZE 4
#define RF_DOUBLE_ARITH
typedef uint64_t rf_double_t;
#define RF_ALIGN 4

#elif __SIZEOF_POINTER__ == 8

/* 64 bit */
#define RF_WORD_SIZE 8
#define RF_DOUBLE_ARITH
typedef __uint128_t rf_double_t;
#define RF_ALIGN 8

#endif

#endif

#endif

#endif

/* TARGET ARCHITECTURE */

/* cc65 */

#ifdef __CC65__
#include <stdint.h>
#define RF_WORD_SIZE 2
#define RF_DOUBLE_ARITH
typedef uint32_t rf_double_t;
#define RF_LE
#ifdef __BBC__
/* BBC */
#define RF_TARGET_HI 0x0000
#define RF_TARGET_LO 0x3948
#ifndef RF_TARGET_INC
#define RF_TARGET_INC "target/bbc/default.inc"
#endif
#endif
#ifdef __C64__
#ifndef RF_TARGET_INC
#define RF_TARGET_INC "target/c64/c64.inc"
#endif
#endif
#endif

/* cmoc */

#ifdef _CMOC_VERSION_
#define RF_WORD_SIZE 2
#define RF_DOUBLE_ARITH
typedef unsigned char uint8_t;
typedef int intptr_t;
typedef unsigned int uintptr_t;
typedef unsigned long rf_double_t;
#define RF_BE
#ifdef DRAGON
/* DRAGON */
#define RF_TARGET_HI 0x3195
#define RF_TARGET_LO 0xC1F7
#ifndef RF_TARGET_INC
#define RF_TARGET_INC "target/dragon/system.inc"
#endif
#endif
#endif

/* z88dk */

#ifdef __SCCZ80
#ifndef __Z80
#define __Z80
#endif
#endif
#ifdef __Z80
#include <stdint.h>
#define RF_WORD_SIZE 2
#define RF_DOUBLE_ARITH
typedef uint32_t rf_double_t;
#define RF_LE
#ifdef __RC2014
#ifndef RF_TARGET_INC
#define RF_TARGET_INC "target/rc2014/default.inc"
#endif
#endif
#ifdef SPECTRUM
/* SPECTR */
#define RF_TARGET_HI 0x6774
#define RF_TARGET_LO 0xe16f
#ifndef RF_TARGET_INC
#define RF_TARGET_INC "target/spectrum/default.inc"
#endif
#endif
#ifdef ZX81
/* ZX81 */
#define RF_TARGET_HI 0x0019
#define RF_TARGET_LO 0x92f1
#ifndef RF_TARGET_INC
#define RF_TARGET_INC "target/zx81/system.inc"
#endif
#endif
#endif

/* C68 */

#ifdef C68
#define RF_WORD_SIZE 4
#define RF_ALIGN 2
#define RF_BE
#undef RF_DOUBLE_ARITH
typedef unsigned char uint8_t;
typedef long intptr_t;
typedef unsigned long uintptr_t;
#ifdef QDOS
/* QL */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x000003bd
#ifndef RF_TARGET_INC
#define RF_TARGET_INC "target/ql/default.inc"
#endif
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
/* CYGWIN */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x2eb31a9f
#endif

#ifdef __MACH__
/* DARWIN */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x2fee7b5f
#endif

#ifdef __linux__
/* LINUX */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x02277e49
#endif

#ifdef __MINGW32__
/* MINGW */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x02411d50
#endif

#ifdef _WIN32
/* WINDOW */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x75327710
#endif

#ifdef PICO
/* PICO */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x00122928
#define RF_ALIGN 4
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

/* OTHERWISE DEFAULT TARGET = HOST PLATFORM */

#ifndef RF_TARGET_INC
#define RF_TARGET_INC "system.inc"
#endif

/* TARGET SPECIFIC INCLUDE FILE */

#include RF_TARGET_INC

/* DISC BUFFERS */

#define RF_BBLK 128
#define RF_BSCR 8
#define RF_DISC_BUFFER_SIZE (RF_BBLK+(2*RF_WORD_SIZE))
#define RF_DISC_BUFFERS_SIZE (8*RF_DISC_BUFFER_SIZE)

/* S0, TIB, R0, USER, FIRST defined in relation to LIMIT by default */

#define RF_FIRST (RF_LIMIT - RF_DISC_BUFFERS_SIZE)

#ifndef RF_USER
#define RF_USER ((char *) (RF_FIRST - (32 * RF_WORD_SIZE)))
#endif

#ifndef RF_R0
#define RF_R0 (RF_USER - RF_WORD_SIZE) 
#endif

#ifndef RF_RETURN_STACK_SIZE
#define RF_RETURN_STACK_SIZE 128
#endif

#ifndef RF_TIB
#define RF_TIB (RF_USER - (RF_RETURN_STACK_SIZE * RF_WORD_SIZE))
#endif

#ifndef RF_S0
#define RF_S0 RF_TIB
#endif

#ifndef RF_STACK_SIZE
#define RF_STACK_SIZE 128
#endif

/* USER VARIABLES */

#define RF_USER_S0_IDX 3
#define RF_USER_S0 rf_up[RF_USER_S0_IDX]
#define RF_USER_R0_IDX 4
#define RF_USER_R0 rf_up[RF_USER_R0_IDX]
#define RF_USER_DP_IDX 9
#define RF_USER_DP rf_up[RF_USER_DP_IDX]
#define RF_USER_OUT_IDX 13
#define RF_USER_OUT rf_up[RF_USER_OUT_IDX]

/* FORTH MACHINE */

/* macro for introducing diagnostics */
#define RF_LOG(name)

/* SP */
extern uintptr_t *rf_sp;

#define RF_SP_GET rf_sp
#define RF_SP_SET(a) { rf_sp = (a); }

#ifdef RF_INLINE_SP
/* inline SP operations */
#define RF_SP_POP (*(rf_sp++))
#define RF_SP_PUSH(a) { *(--rf_sp) = (a); }
#else
/* non-inline SP operations */
uintptr_t rf_sp_pop(void);

void __FASTCALL__ rf_sp_push(uintptr_t a);

#define RF_SP_POP rf_sp_pop()
#define RF_SP_PUSH(a) rf_sp_push(a)
#endif

/* RP */
extern uintptr_t *rf_rp;

#define RF_RP_GET rf_rp
#define RF_RP_SET(a) { rf_rp = (a); }

#ifdef RF_INLINE_RP
/* inline RP operations */
#define RF_RP_POP (*(rf_rp++))
#define RF_RP_PUSH(a) { *(--rf_rp) = ((uintptr_t) (a)); }
#else
/* non-inline RP operations */
uintptr_t rf_rp_pop(void);

void __FASTCALL__ rf_rp_push(uintptr_t a);

#define RF_RP_POP rf_rp_pop()
#define RF_RP_PUSH(a) { rf_rp_push((uintptr_t) (a)); }
#endif

/* IP */
extern uintptr_t *rf_ip;

#define RF_IP_GET rf_ip
#define RF_IP_INC { rf_ip++; }
#define RF_IP_SET(a) { rf_ip = (a); }

/* W */
typedef void (*rf_code_t)(void);
extern rf_code_t *rf_w;

/* UP */
extern uintptr_t *rf_up;

/* INNER INTERPRETER */

/* function pointer */
extern rf_code_t rf_fp;

/* start trampoline */
void rf_trampoline(void);

#define RF_JUMP(a) { rf_fp = (a); }

/* NEXT */
void rf_next(void);

#define RF_JUMP_NEXT { rf_fp = rf_next; }

/* C CODE START - save registers */
void rf_start(void);

#define RF_START rf_start()

/* SYSTEM SPECIFIC */

void rf_init(void);

void rf_fin(void);

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

void rf_disc_read(char *c, uint8_t len);

void rf_disc_write(char *p, uint8_t len);

void rf_code_bread(void);

void rf_code_bwrit(void);

void rf_code_dchar(void);

/* ADDITIONAL */

void rf_code_cl(void);

void rf_code_cs(void);

void rf_code_ln(void);

void rf_code_xt(void);

#endif /* RF_H_ */
