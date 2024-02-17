# Modified for orterforth integration and x86_64
# in 2022. Some info in the comments no longer 
# applies (CP/M, 8086 register names, 
# segmentation, byte offsets).

        .intel_syntax noprefix

        .text

        .globl rf_trampoline
        .globl _rf_trampoline
        .p2align 4, 0x90
rf_trampoline:
_rf_trampoline:
        PUSH    RBP                     # enter stack frame
        MOV     RBP,RSP
        MOV     RAX,_rf_origin[RIP]     # S0 to SP, for consistency with i686
        MOV     RAX,72[RAX]
        MOV     _rf_sp[RIP],RAX
trampoline1:
        MOV     RAX,_rf_fp[RIP]
        TEST    RAX,RAX                 # if FP is null skip to exit
        JZ      trampoline2
        MOV     RSI,_rf_ip[RIP]         # IP to RSI
        MOV     RDX,_rf_w[RIP]          # W to RDX
        LEA     RCX,trampoline1[RIP]    # push the return address
        PUSH    RCX
        MOV     rbpsave[RIP],RBP        # save RBP
        MOV     rspsave[RIP],RSP        # save RSP
        MOV     RBP,_rf_rp[RIP]         # RP to RBP
        MOV     RSP,_rf_sp[RIP]         # SP to RSP
        JMP     RAX                     # jump to FP
                                        # will return to trampoline1
trampoline2:
        POP     RBP                     # leave stack frame
        RET                             # bye

        .globl rf_start
        .globl _rf_start
        .p2align 4, 0x90
rf_start:
_rf_start:
        MOV     _rf_w[RIP],RDX          # RDX to W
        MOV     _rf_ip[RIP],RSI         # RSI to IP
                                        # C stack frame and return address have
                                        # been pushed to Forth stack; we need to
                                        # move them to the C stack:
        POP     RAX                     # unwind rf_start return address
        MOV     RCX,RBP                 # stack frame size to RCX
        SUB     RCX,RSP
        MOV     RSI,RSP                 # stack frame start to RSI
        MOV     RSP,RBP                 # empty the stack frame, i.e., make RSP = RBP
        POP     RBP                     # RBP that was pushed (this is RP)
        MOV     _rf_rp[RIP],RBP         # RBP to RP
        MOV     _rf_sp[RIP],RSP         # RSP to SP
        MOV     RBP,rbpsave[RIP]        # restore RBP
        MOV     RSP,rspsave[RIP]        # restore RSP
        PUSH    RBP                     # create new stack frame
        MOV     RBP,RSP
        SUB     RSP,RCX
        MOV     RDI,RSP                 # new stack frame start to RDI
        CLD                             # now copy data from old stack frame
        REP     movsb                   # NB LLVM errors if MOVS... is in upper case!
        JMP     RAX                     # carry on in C
                                        # of course other x86_64 registers could be used
                                        # avoiding this issue, but here we inherit
                                        # from the original 8086 fig-Forth source.

        .globl rf_code_cl
        .globl _rf_code_cl
        .p2align 4, 0x90
rf_code_cl:
_rf_code_cl:
        MOV     RAX,8
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

        .globl rf_code_cs
        .globl _rf_code_cs
        .p2align 4, 0x90
rf_code_cs:
_rf_code_cs:
        SHL     QWORD PTR [RSP],3
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

        .globl rf_code_ln
        .globl _rf_code_ln
        .p2align 4, 0x90
rf_code_ln:
_rf_code_ln:
        POP     RAX
        TEST    RAX,7
        JZ      LN1
        AND     RAX,-8
        ADD     RAX,8
LN1:    # JMP   APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

        .globl rf_code_mon
        .globl _rf_code_mon
        .p2align 4, 0x90
rf_code_mon:
_rf_code_mon:
        PUSH    RBP
        MOV     RBP, RSP
        MOV     RAX,0
        MOV     _rf_fp[RIP],RAX
        CALL    _rf_start
        POP     RBP
        RET

        .globl rf_code_cold
        .globl _rf_code_cold
        .p2align 4, 0x90
rf_code_cold:
_rf_code_cold:
        MOV     RDX,_rf_origin[RIP]
        MOV     RAX,0x30[RDX]   # FORTH vocabulary init
        MOV     RBX,0xA8[RDX]
        MOV     [RBX],RAX
        MOV     RDI,0x40[RDX]   # UP init
        MOV     UP[RIP],RDI
        CLD                     # USER variables init
        MOV     RCX,11
        LEA     RSI,0x30[RDX]
        REP     movsq
        MOV     RSI,0xB0[RDX]   # IP init to ABORT
        JMP     rf_code_rpsto   # jump to RP!

        .section __DATA.__data,""
        .data

        .p2align 3
rbpsave:.quad 0

        .p2align 3
rspsave:.quad 0

        .globl rf_fp
        .globl _rf_fp
        .p2align 3
rf_fp:
_rf_fp: .quad 0

        .globl rf_ip
        .globl _rf_ip
        .p2align 3
rf_ip:
_rf_ip: .quad 0

        .globl rf_rp
        .globl _rf_rp
        .p2align 3
rf_rp:
_rf_rp: .quad 0

        .globl rf_sp
        .globl _rf_sp
        .p2align 3
rf_sp:
_rf_sp: .quad 0

        .globl rf_up
        .globl _rf_up
        .p2align 3
rf_up:
_rf_up: .quad 0

        .globl rf_w
        .globl _rf_w
        .p2align 3
rf_w:
_rf_w: .quad 0

        .text

# ***************************************
# ***                                 ***
# ***    FIG-FORTH for the 8086/88    ***
# ***                                 ***
# ***           Version 1.0           ***
# ***            2/18/81              ***
# ***                                 ***
# ***     Contains interface for      ***
# ***      CP/M-86 (version 1.0)      ***
# ***                                 ***
# ***                                 ***
# ***     Implementation by           ***
# ***           Thomas Newman         ***
# ***           27444 Berenda Way     ***
# ***           Hayward, Ca. 94544    ***
# ***                                 ***
# ***************************************
#
#
#
# NOTE: This version only supports one
#       memory segment of the 8086 (64k bytes).
#
#
# -----------------------------------------------
#
# All publications of the Forth Interest Group
# are public domain.  They may be further
# distributed by the inclusion of this credit
# notice:
#
# This publication has been made available by the
# FORTH INTEREST GROUP (fig)
# P.O. Box 8231
# San Jose, CA 95155
# -----------------------------------------------
#
# Acknowledgements:
#       John Cassady
#       Kim Harris
#       George Flammer
#       Robt. D. Villwock
#-----------------------------------------------

UP      =       _rf_up

#-----------------------------------------------
#
# FORTH REGISTERS
#
# FORTH 8086    FORTH PRESERVATION RULES
# ----- ----    ------------------------
#
# IP    SI      INTERPRETER POINTER.
#               MUST BE PRESERVED
#               ACROSS FORTH WORDS.
#
# W     DX      WORKING REGISTER.
#               JUMP TO 'DPUSH' WILL
#               PUSH CONTENTS ONTO THE
#               PARAMETER STACK BEFORE
#               EXECUTING 'APUSH'.
#
# SP    SP      PARAMETER STACK POINTER.
#               MUST BE PRESERVED
#               ACROSS FORTH WORDS.
#
# RP    BP      RETURN STACK.
#               MUST BE PRESERVED
#               ACROSS FORTH WORDS.
#
#       AX      GENERAL REGISTER.
#               JUMP TO 'APUSH' WILL PUSH
#               CONTENTS ONTO THE PARAMETER
#               STACK BEFORE EXECUTING 'NEXT'.
#
#       BX      GENERAL PURPOSE REGISTER.
#
#       CX      GENERAL PURPOSE REGISTER.
#
#       DI      GENERAL PURPOSE REGISTER.
#
#       CS      SEGMENT REGISTER.  MUST BE
#               PRESERVED ACROSS FORTH WORDS.
#
#       DS         "    "       "
#
#       SS         "    "       "
#
#       ES      TEMPORARY SEGMENT REGISTER
#               ONLY USED BY A FEW WORDS.
#
################################################

# *************
# *           *
# *   NEXT    *
# *           *
# *   DPUSH   *
# *           *
# *   APUSH   *
# *           *
# *************
#
#
DPUSH:  PUSH    RDX
APUSH:  PUSH    RAX
#
# -----------------------------------------
#
# PATCH THE NEXT 3 LOCATIONS
# (USING A DEBUG MONITOR; I.E. DDT86)
# WITH  (JMP TNEXT)  FOR TRACING THROUGH
# HIGH LEVEL FORTH WORDS.
#
        .globl rf_next
        .globl _rf_next
        .p2align 4, 0x90
rf_next:
_rf_next:
NEXT:   LODSQ           # AX<- (IP)
        MOV     RDX,RAX # (W) <- (IP)
#
# -----------------------------------------
#
NEXT1:  JMP     QWORD PTR [RDX] # TO 'CFA'

#
# *********************************************
# ******   DICTIONARY WORDS START HERE   ******
# *********************************************
#
#
# ***********
# *   LIT   *
# ***********
#
        .globl rf_code_lit
        .globl _rf_code_lit
        .p2align 4, 0x90
rf_code_lit:
_rf_code_lit:
        LODSQ           # AX <- LITERAL
#       JMP     APUSH   # TO TOP OF STACK
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***************
# *   EXECUTE   *
# ***************
#
        .globl rf_code_exec
        .globl _rf_code_exec
        .p2align 4, 0x90
rf_code_exec:
_rf_code_exec:
        POP     RDX     # GET CFA
#       JMP     NEXT1   # EXECUTE NEXT
        JMP     QWORD PTR [RDX]


# **************
# *   BRANCH   *
# **************
#
        .globl rf_code_bran
        .globl _rf_code_bran
        .p2align 4, 0x90
rf_code_bran:
_rf_code_bran:
BRAN1:  ADD     RSI,[RSI] # (IP) <- (IP) + ((IP))
#       JMP     NEXT    # JUMP TO OFFSET
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***************
# *   0BRANCH   *
# ***************
#
        .globl rf_code_zbran
        .globl _rf_code_zbran
        .p2align 4, 0x90
rf_code_zbran:
_rf_code_zbran:
        POP     RAX     # GET STACK VALUE
        OR      RAX,RAX # ZERO?
        JZ      BRAN1   # YES, BRANCH
        ADD     RSI,8   # NO, CONTINUE...
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **************
# *   (LOOP)   *
# **************
#
        .globl rf_code_xloop
        .globl _rf_code_xloop
        .p2align 4, 0x90
rf_code_xloop:
_rf_code_xloop:
        MOV     RBX,1   # INCREMENT
XLOO1:  ADD     [RBP],RBX # INDEX=INDEX+INCR
        MOV     RAX,[RBP] # GET NEW INDEX
        SUB     RAX,8[RBP] # COMPARE WITH LIMIT
        XOR     RAX,RBX # TEST SIGN (BIT-16)
        JS      BRAN1   # KEEP LOOPING...

# END OF 'DO' LOOP.
        ADD     RBP,16  # ADJ. RETURN STK
        ADD     RSI,8   # BYPASS BRANCH OFFSET
#       JMP     NEXT    # CONTINUE...
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***************
# *   (+LOOP)   *
# ***************
#
        .globl rf_code_xploo
        .globl _rf_code_xploo
        .p2align 4, 0x90
rf_code_xploo:
_rf_code_xploo:
        POP     RBX     # GET LOOP VALUE
        JMP     XLOO1


# ************
# *   (DO)   *
# ************
#
        .globl rf_code_xdo
        .globl _rf_code_xdo
        .p2align 4, 0x90
rf_code_xdo:
_rf_code_xdo:
        POP     RDX     # INITIAL INDEX VALUE
        POP     RAX     # LIMIT VALUE
        XCHG    RBP,RSP # GET RETURN STACK
        PUSH    RAX
        PUSH    RDX
        XCHG    RBP,RSP # GET PARAMETER STACK
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *********
# *   I   *
# *********
#
        .globl rf_code_rr
        .globl _rf_code_rr
        .p2align 4, 0x90
rf_code_rr:
_rf_code_rr:
        MOV     RAX,[RBP] # GET INDEX VALUE
#       JMP     APUSH   # TO PARAMETER STACK
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *************
# *   DIGIT   *
# *************
#
        .globl rf_code_digit
        .globl _rf_code_digit
        .p2align 4, 0x90
rf_code_digit:
_rf_code_digit:
        POP     RDX     # NUMBER BASE
        POP     RAX     # ASCII DIGIT
        SUB     AL,'0'
        JB      DIGI2   # NUMBER ERROR
        CMP     AL,9
        JBE     DIGI1   # NUMBER = 0 THRU 9
        SUB     AL,7
        CMP     AL,10   # NUMBER 'A' THRU 'Z' ?
        JB      DIGI2   # NO
#
DIGI1:  CMP     AL,DL   # COMPARE NUMBER TO BASE
        JAE     DIGI2   # NUMBER ERROR
        SUB     RDX,RDX # ZERO
        MOV     DL,AL   # NEW BINARY NUMBER
        MOV     AL,1    # TRUE FLAG
#       JMP     DPUSH   # ADD TO STACK
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

# NUMBER ERROR
#
DIGI2:  SUB     RAX,RAX # FALSE FLAG
#       JMP     APUSH   # BYE
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *************
# *   PFIND   *
# *************
#
        .globl rf_code_pfind
        .globl _rf_code_pfind
        .p2align 4, 0x90
rf_code_pfind:
_rf_code_pfind:
#       MOV     AX,DS
#       MOV     ES,AX   # ES = DS
        POP     RBX     # NFA
        POP     RCX     # STRING ADDR
#
# SEARCH LOOP
PFIN1:  MOV     RDI,RCX # GET ADDR
        MOV     AL,[RBX] # GET WORD LENGTH
        MOV     DL,AL   # SAVE LENGTH
        XOR     AL,[RDI]
        AND     AL,0x3F # CHECK LENGTHS
        JNZ     PFIN5   # LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
PFIN2:  INC     RBX
        INC     RDI     # NEXT CHAR OF NAME
        MOV     AL,[RBX]
        XOR     AL,[RDI] # COMPARE NAMES
        ADD     AL,AL   # THIS WILL TEST BIT-8
        JNZ     PFIN5   # NO MATCH
        JNB     PFIN2   # MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
        ADD     RBX,17  # BX = PFA
        PUSH    RBX     # (S3) <- PFA
        MOV     RAX,1   # TRUE VALUE
#       SUB     DH,DH   # CLEAR HIGH LENGTH
        AND     RDX,0xFF
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
PFIN5:  INC     RBX     # NEXT ADDR
        JB      PFIN6   # END OF NAME
        MOV     AL,[RBX] # GET NEXT CHAR
        ADD     AL,AL   # SET/RESET CARRY
        JMP     PFIN5   # LOOP UNTIL FOUND
#
PFIN6:  MOV     RBX,[RBX] # GET LINK FIELD ADDR
        OR      RBX,RBX # START OF DICT. (0)?
        JNZ     PFIN1   # NO, LOOK SOME MORE
        MOV     RAX,0   # FALSE FLAG
#       JMP     APUSH   # DONE (NO MATCH FOUND)
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***************
# *   ENCLOSE   *
# ***************
#
        .globl rf_code_encl
        .globl _rf_code_encl
        .p2align 4, 0x90
rf_code_encl:
_rf_code_encl:
        POP     RAX     # S1 - TERMINATOR CHAR.
        POP     RBX     # S2 - TEXT ADDR
        PUSH    RBX     # ADDR BACK TO STACK
#       MOV     AH,0    # ZERO
        AND     RAX,0xFF
        MOV     RDX,-1  # CHAR OFFSET COUNTER
        DEC     RBX     # ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
ENCL1:  INC     RBX     # ADDR +1
        INC     RDX     # COUNT +1
        CMP     AL,[RBX]
        JZ      ENCL1   # WAIT FOR NON-TERMINATOR
        PUSH    RDX     # OFFSET TO 1ST TEXT CHR
        CMP     AH,[RBX] # NULL CHAR?
        JNZ     ENCL2   # NO

# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
        MOV     RAX,RDX # COPY COUNTER
        INC     RDX     # +1
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
ENCL2:  INC     RBX     # ADDR+1
        INC     RDX     # COUNT +1
        CMP     AL,[RBX] # TERMINATOR CHAR?
        JZ      ENCL4   # YES
        CMP     AH,[RBX] # NULL CHAR
        JNZ     ENCL2   # NO, LOOP AGAIN

# FOUND NULL AT END OF TEXT
#
ENCL3:  MOV     RAX,RDX # COUNTERS ARE EQUAL
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

# FOUND TERINATOR CHARACTER
ENCL4:  MOV     RAX,RDX
        INC     RAX     # COUNT +1
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *************
# *   CMOVE   *
# *************
#
        .globl rf_code_cmove
        .globl _rf_code_cmove
        .p2align 4, 0x90
rf_code_cmove:
_rf_code_cmove:
        CLD             # INC DIRECTION
        MOV     RBX,RSI # SAVE IP
        POP     RCX     # COUNT
        POP     RDI     # DEST.
        POP     RSI     # SOURCE
#       MOV     AX,DS
#       MOV     ES,AX   # ES <- DS
        REP     movsb   # THATS THE MOVE
        MOV     RSI,RBX # GET BACK IP
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   U*   *
# **********
#
        .globl rf_code_ustar
        .globl _rf_code_ustar
        .p2align 4, 0x90
rf_code_ustar:
_rf_code_ustar:
        POP     RAX
        POP     RBX
        MUL     RBX     # UNSIGNED
#       XCHG    RAX,RDX # AX NOW = MSW
#       JMP     DPUSH   # STORE DOUBLE WORD
        PUSH    RAX
        PUSH    RDX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   U/   *
# **********
#
        .globl rf_code_uslas
        .globl _rf_code_uslas
        .p2align 4, 0x90
rf_code_uslas:
_rf_code_uslas:
        POP     RBX     # DIVISOR
        POP     RDX     # MSW OF DIVIDEND
        POP     RAX     # LSW OF DIVIDEND
        CMP     RDX,RBX # DIVIDE BY ZERO?
        JNB     DZERO   # ZERO DIVIDE, NO WAY
        DIV     RBX     # 16 BIT DIVIDE
#       JMP     DPUSH   # STORE QUOT/REM
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

# DIVIDE BY ZERO ERROR (SHOW MAX NUMBERS)
#
DZERO:  MOV     RAX,-1
        MOV     RDX,RAX
#       JMP     DPUSH   # STORE QUOT/REM
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***********
# *   AND   *
# ***********
#
        .globl rf_code_andd
        .globl _rf_code_andd
        .p2align 4, 0x90
rf_code_andd:           # (S1) <- (S1) AND (S2)
_rf_code_andd:
        POP     RAX
        POP     RBX
        AND     RAX,RBX
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   OR   *
# **********
#
        .globl rf_code_orr
        .globl _rf_code_orr
        .p2align 4, 0x90
rf_code_orr:            # (S1) <- (S1) OR (S2)
_rf_code_orr:
        POP     RAX
        POP     RBX
        OR      RAX,RBX
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***********
# *   XOR   *
# ***********
#
        .globl rf_code_xorr
        .globl _rf_code_xorr
        .p2align 4, 0x90
rf_code_xorr:           # (S1) <- (S1) XOR (S2)
_rf_code_xorr:
        POP     RAX
        POP     RBX
        XOR     RAX,RBX
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***********
# *   SP@   *
# ***********
#
        .globl rf_code_spat
        .globl _rf_code_spat
        .p2align 4, 0x90
rf_code_spat:           # (S1) <- (SP)
_rf_code_spat:
        MOV     RAX,RSP
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***********
# *   SP!   *
# ***********
#
        .globl rf_code_spsto
        .globl _rf_code_spsto
        .p2align 4, 0x90
rf_code_spsto:
_rf_code_spsto:
        MOV     RBX,UP[RIP] # USER VAR BASE ADDR
        MOV     RSP,24[RBX] # RESET PARAM. STACK PT.
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***********
# *   RP!   *
# ***********
#
        .globl rf_code_rpsto
        .globl _rf_code_rpsto
        .p2align 4, 0x90
rf_code_rpsto:
_rf_code_rpsto:
        MOV     RBX,UP[RIP] # (AX) <- USR VAR. BASE
        MOV     RBP,32[RBX] # RESET RETURN STACK PT.
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   ;S   *
# **********
#
        .globl rf_code_semis
        .globl _rf_code_semis
        .p2align 4, 0x90
rf_code_semis:
_rf_code_semis:
        MOV     RSI,[RBP] # (IP) <- (R1)
        ADD     RBP,8   # ADJUST STACK
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *************
# *   LEAVE   *
# *************
#
        .globl rf_code_leave
        .globl _rf_code_leave
        .p2align 4, 0x90
rf_code_leave:          # LIMIT <- INDEX
_rf_code_leave:
        MOV     RAX,[RBP] # GET INDEX
        MOV     8[RBP],RAX # STORE IT AT LIMIT
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   >R   *
# **********
#
        .globl rf_code_tor
        .globl _rf_code_tor
        .p2align 4, 0x90
rf_code_tor:            # (R1) <- (S1)
_rf_code_tor:
        POP     RBX     # GET STACK PARAMETER
        SUB     RBP,8   # MOVE RETURN STACK DOWN
        MOV     [RBP],RBX # ADD TO RETURN STACK
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   R>   *
# **********
#
        .globl rf_code_fromr
        .globl _rf_code_fromr
        .p2align 4, 0x90
rf_code_fromr:          # (S1) <- (R1)
_rf_code_fromr:
        MOV     RAX,[RBP] # GET RETURN STACK VALUE
        ADD     RBP,8   # DELETE FROM STACK
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   0=   *
# **********
#
        .globl rf_code_zequ
        .globl _rf_code_zequ
        .p2align 4, 0x90
rf_code_zequ:
_rf_code_zequ:
        POP     RAX
        OR      RAX,RAX # DO TEST
        MOV     RAX,1   # TRUE
        JZ      ZEQU1   # ITS ZERO
        DEC     RAX     # FALSE
ZEQU1:  # JMP   APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   0<   *
# **********
#
        .globl rf_code_zless
        .globl _rf_code_zless
        .p2align 4, 0x90
rf_code_zless:
_rf_code_zless:
        POP     RAX
        OR      RAX,RAX # SET FLAGS
        MOV     RAX,1   # TRUE
        JS      ZLESS1
        DEC     RAX     # FLASE
ZLESS1: # JMP   APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *********
# *   +   *
# *********
#
        .globl rf_code_plus
        .globl _rf_code_plus
        .p2align 4, 0x90
rf_code_plus:           # (S1) <- (S1) + (S2)
_rf_code_plus:
        POP     RAX
        POP     RBX
        ADD     RAX,RBX
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   D+   *
# **********
#
# XLW XHW  YLW YHW --> SLW SHW
# S4  S3   S2  S1      S2  S1
#
        .globl rf_code_dplus
        .globl _rf_code_dplus
        .p2align 4, 0x90
rf_code_dplus:
_rf_code_dplus:
        POP     RAX     # YHW
        POP     RDX     # YLW
        POP     RBX     # XHW
        POP     RCX     # XLW
        ADD     RDX,RCX # SLW
        ADC     RAX,RBX # SHW
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *************
# *   MINUS   *
# *************
#
        .globl rf_code_minus
        .globl _rf_code_minus
        .p2align 4, 0x90
rf_code_minus:
_rf_code_minus:
        POP     RAX
        NEG     RAX
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **************
# *   DMINUS   *
# **************
#
        .globl rf_code_dminu
        .globl _rf_code_dminu
        .p2align 4, 0x90
rf_code_dminu:
_rf_code_dminu:
        POP     RBX
        POP     RCX
        SUB     RAX,RAX # ZERO
        MOV     RDX,RAX
        SUB     RDX,RCX # MAKE 2'S COMPLEMENT
        SBB     RAX,RBX # HIGH WORD
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ************
# *   OVER   *
# ************
#
        .globl rf_code_over
        .globl _rf_code_over
        .p2align 4, 0x90
rf_code_over:
_rf_code_over:
        POP     RDX
        POP     RAX
        PUSH    RAX
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ************
# *   DROP   *
# ************
#
        .globl rf_code_drop
        .globl _rf_code_drop
        .p2align 4, 0x90
rf_code_drop:
_rf_code_drop:
        POP     RAX
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ************
# *   SWAP   *
# ************
#
        .globl rf_code_swap
        .globl _rf_code_swap
        .p2align 4, 0x90
rf_code_swap:
_rf_code_swap:
        POP     RDX
        POP     RAX
#       JMP     DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ***********
# *   DUP   *
# ***********
#
        .globl rf_code_dup
        .globl _rf_code_dup
        .p2align 4, 0x90
rf_code_dup:
_rf_code_dup:
        POP     RAX
        PUSH    RAX
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   +!   *
# **********
#
        .globl rf_code_pstor
        .globl _rf_code_pstor
        .p2align 4, 0x90
rf_code_pstor:          # ((S1)) <- ((S1)) + (S2)
_rf_code_pstor:
        POP     RBX     # ADDRESS
        POP     RAX     # INCREMENT
        ADD     [RBX],RAX
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **************
# *   TOGGLE   *
# **************
#
        .globl rf_code_toggl
        .globl _rf_code_toggl
        .p2align 4, 0x90
rf_code_toggl:
_rf_code_toggl:
        POP     RAX     # BIT PATTERN
        POP     RBX     # ADDR
        XOR     [RBX],AL
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *********
# *   @   *
# *********
#
        .globl rf_code_at
        .globl _rf_code_at
        .p2align 4, 0x90
rf_code_at:             # (S1) <- ((S1))
_rf_code_at:
        POP     RBX
        MOV     RAX,[RBX]
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   C@   *
# **********
#
        .globl rf_code_cat
        .globl _rf_code_cat
        .p2align 4, 0x90
rf_code_cat:
_rf_code_cat:
        POP     RBX
#       MOV     AL,[RBX]
#       AND     RAX,0xFF
        MOVZX   RAX, BYTE PTR [RBX]
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *********
# *   !   *
# *********
#
        .globl rf_code_store
        .globl _rf_code_store
        .p2align 4, 0x90
rf_code_store:          # ((S1)) <- (S2)
_rf_code_store:
        POP     RBX     # ADDR
        POP     RAX     # DATA
        MOV     [RBX],RAX
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# **********
# *   C!   *
# **********
#
        .globl rf_code_cstor
        .globl _rf_code_cstor
        .p2align 4, 0x90
rf_code_cstor:
_rf_code_cstor:
        POP     RBX     # ADDR
        POP     RAX     # DATA
        MOV     [RBX],AL
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *********
# *   :   *
# *********
#
        .globl rf_code_docol
        .globl _rf_code_docol
        .p2align 4, 0x90
rf_code_docol:
_rf_code_docol:
DOCOL:  ADD     RDX,8   # W=W+1
        SUB     RBP,8   # (RP) <- (RP)-2
        MOV     [RBP],RSI # R1 <- (RP)
        MOV     RSI,RDX # (IP) <- (W)
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ****************
# *   CONSTANT   *
# ****************
#
        .globl rf_code_docon
        .globl _rf_code_docon
        .p2align 4, 0x90
rf_code_docon:
_rf_code_docon:
DOCON:  # ADD   RDX,8   # PFA
#       MOV     RBX,RDX
#       MOV     RAX,[RBX] # GET DATA
        MOV     RAX,8[RDX]
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

# ****************
# *   VARIABLE   *
# ****************
#
        .globl rf_code_dovar
        .globl _rf_code_dovar
        .p2align 4, 0x90
rf_code_dovar:
_rf_code_dovar:
DOVAR:  ADD     RDX,8   # (DE) <- PFA
        PUSH    RDX     # (S1) <- PFA
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]

# ************
# *   USER   *
# ************
#
        .globl rf_code_douse
        .globl _rf_code_douse
        .p2align 4, 0x90
rf_code_douse:
_rf_code_douse:
DOUSE:  # ADD   RDX,8   # PFA
#       MOV     RBX,RDX
#       MOV     BL,[RBX]
#       AND     RBX,0xFF
        MOVZX   RBX, BYTE PTR 8[RDX]
        MOV     RDI,UP[RIP] # USER VARIABLE ADDR
        LEA     RAX,[RBX+RDI] # ADDR OF VARIABLE
#       JMP     APUSH
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# *************
# *   DOES>   *
# *************
#
        .globl rf_code_dodoe
        .globl _rf_code_dodoe
        .p2align 4, 0x90
rf_code_dodoe:
_rf_code_dodoe:
DODOE:  XCHG    RBP,RSP # GET RETURN STACK
        PUSH    RSI     # (RP) <- (IP)
        XCHG    RBP,RSP
#       ADD     RDX,8   # PFA
#       MOV     RBX,RDX
#       MOV     RSI,[RBX] # NEW CFA
#       ADD     RDX,8
        MOV     RSI,8[RDX]
        ADD     RDX,16
        PUSH    RDX     # PFA
#       JMP     NEXT
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]


# ************
# *   S->D   *
# ************
#
        .globl rf_code_stod
        .globl _rf_code_stod
        .p2align 4, 0x90
rf_code_stod:
_rf_code_stod:
        POP     RDX     # S1
        SUB     RAX,RAX # AX = 0
        OR      RDX,RDX # SET FLAGS
        JNS     STOD1   # POSITIVE NUMBER
        DEC     RAX     # NEGITIVE NUMBER
STOD1:  # JMP   DPUSH
        PUSH    RDX
        PUSH    RAX
        LODSQ
        MOV     RDX,RAX
        JMP     QWORD PTR [RDX]
