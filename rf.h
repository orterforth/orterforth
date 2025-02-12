#ifndef RF_H_
#define RF_H_

/* C COMPILER SETTINGS */

/* clang, gcc */

#ifdef __GNUC__
#ifndef QDOS
#include <stdint.h>
#if __SIZEOF_POINTER__ == 4
typedef uint64_t rf_double_t;
#elif __SIZEOF_POINTER__ == 8
typedef __uint128_t rf_double_t;
#endif

#define RF_WORD_SIZE __SIZEOF_POINTER__
#define RF_DOUBLE_ARITH
#define RF_ALIGN RF_WORD_SIZE
#endif
#endif

/* MS Visual C */

#ifdef _WIN32
#include <stdint.h>
#undef RF_DOUBLE_ARITH
#define RF_BS 0x08
#ifdef _WIN64
#define RF_WORD_SIZE 8
#else
#define RF_WORD_SIZE 4
#endif
#define RF_ALIGN RF_WORD_SIZE
#endif

/* TARGET ARCHITECTURE */

/* cc65 */

#ifdef __CC65__
#include <stdint.h>
#define RF_WORD_SIZE 2
#define RF_DOUBLE_ARITH
typedef uint32_t rf_double_t;
#define RF_LE
#ifdef __APPLE2__
#define RF_TARGET_INC "target/apple2/apple2.inc"
#endif
#ifdef __BBC__
#define RF_TARGET_INC "target/bbc/bbc.inc"
#endif
#ifdef __C64__
#define RF_TARGET_INC "target/c64/c64.inc"
#endif
/* 6502 */
#define RF_CPU_HI 0x0004
#define RF_CPU_LO 0x5ED2
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
#define RF_TARGET_INC "target/dragon/dragon.inc"
#endif
/* 6809 */
#define RF_CPU_HI 0x0004
#define RF_CPU_LO 0x6E09
#endif

/* z88dk */

#ifdef __SCCZ80
#include <stdint.h>
#define RF_WORD_SIZE 2
#define RF_DOUBLE_ARITH
typedef uint32_t rf_double_t;
#define RF_LE
#endif

#ifndef __Z80
#ifdef Z80
#define __Z80
#endif
#endif
#ifdef __Z80
#ifdef CPM
#define RF_TARGET_INC "target/cpm/cpm.inc"
#endif
#ifdef __RC2014
#define RF_TARGET_INC "target/rc2014/rc2014.inc"
#endif
#ifdef SPECTRUM
#define RF_TARGET_INC "target/spectrum/spectrum.inc"
#endif
#ifdef Z88
#define RF_TARGET_INC "target/z88/z88.inc"
#endif
#ifdef ZX81
#define RF_TARGET_INC "target/zx81/zx81.inc"
#endif
#ifndef __8085__
/* Z80 */
#define RF_CPU_HI 0x0000
#define RF_CPU_LO 0xB250
#endif
#endif
#ifdef __8085__
#ifdef __M100__
#define RF_TARGET_INC "target/m100/m100.inc"
#endif
/* 8085 */
#define RF_CPU_HI 0x0005
#define RF_CPU_LO 0xB325
#endif
#ifndef __SCCZ80
#define __FASTCALL__
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
#define RF_TARGET_INC "target/ql/ql.inc"
#endif
/* 68000 */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x009F7800
#endif

/* CC6303 */

#ifdef CC6303
#define RF_WORD_SIZE 2
#define RF_BE
#define RF_DOUBLE_ARITH
#include <stdint.h>
typedef uint32_t rf_double_t;
#define RF_TARGET_INC "target/hx20/hx20.inc"
#endif

/* VBCC */

#ifdef __VBCC__
#define RF_WORD_SIZE 4
#define RF_ALIGN 2
#define RF_BE
#define RF_DOUBLE_ARITH
#include <stdint.h>
typedef uint64_t rf_double_t;
#define RF_TARGET_INC "target/amiga/amiga.inc"
/* AMIGA */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x011050EA
/* 68000 */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x009F7800
#endif

/* modern platforms */

#ifdef _M_IX86
#define RF_LE
/* X86 */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x0000A836
#endif

#ifdef __i386__
#define RF_LE
/* X86 */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x0000A836
#endif

#ifdef _M_AMD64
#define RF_LE
/* X8664 */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x0353923C
#endif

#ifdef __x86_64__
#define RF_LE
/* X8664 */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x0353923C
#endif

#ifdef __arm__
#define RF_LE
/* ARM */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x00003682
#endif

#ifdef __aarch64__
#define RF_LE
/* ARM64 */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x0113F2FC
#endif

#ifdef __riscv
#define RF_LE
#define RF_ALIGN 4
/* RISCV */
#define RF_CPU_HI 0x00000000
#define RF_CPU_LO 0x02C15B0F
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
#define RF_NOEXIT
#endif

#ifdef ESP_PLATFORM
/* ESP32 */
#define RF_TARGET_HI 0x00000000
#define RF_TARGET_LO 0x017B3BFE
#define RF_NOEXIT
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

#ifndef RF_S1
#define RF_S1 (RF_S0 - (RF_STACK_SIZE * RF_WORD_SIZE))
#endif

/* FORTH MACHINE */

/* SP */
extern uintptr_t *rf_sp;

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

/* NEXT */
void rf_next(void);

#define RF_JUMP(a) { rf_fp = (a); }
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

void rf_code_mon(void);

/* CONSOLE */

void rf_code_emit(void);

void rf_code_key(void);

void rf_code_qterm(void);

void rf_code_cr(void);

/* DISC */

void rf_code_bread(void);

void rf_code_bwrit(void);

void rf_code_dchar(void);

/* ADDITIONAL */

void rf_code_cl(void);

void rf_code_cs(void);

void rf_code_ln(void);

#endif /* RF_H_ */
