# Modified for orterforth integration and i686
# in 2022. Some info in the comments no longer 
# applies (CP/M, 8086 register names, 
# segmentation, byte offsets).

        .intel_syntax noprefix

        .text

        .globl rf_trampoline
        .globl _rf_trampoline
rf_trampoline:
_rf_trampoline:
        PUSH    EBP                     # enter stack frame
        MOV     EBP,ESP
        PUSH    EBX                     # callee save EBX
        PUSH    ESI                     # callee save ESI
        CALL    __x86.get_pc_thunk.bx
        ADD     EBX,OFFSET _GLOBAL_OFFSET_TABLE_
        PUSH    EBX
        MOV     EAX,_rf_origin@GOTOFF[EBX] # S0 to SP
        MOV     EAX,36[EAX]
        MOV     rf_sp@GOTOFF[EBX],EAX
trampoline1:
        POP     EBX
        PUSH    EBX
        MOV     EAX,rf_fp@GOTOFF[EBX]   # if FP is null skip to exit
        TEST    EAX,EAX
        JE      trampoline2
        MOV     ESI,_rf_ip@GOTOFF[EBX]  # IP to ESI
        MOV     EDX,_rf_w@GOTOFF[EBX]   # W to EDX
        LEA     ECX,trampoline1@GOTOFF[EBX] # push the return address
        PUSH    ECX
        MOV     ebpsave@GOTOFF[EBX],EBP # save EBP
        MOV     EBP,_rf_rp@GOTOFF[EBX]  # RP to EBP
        MOV     espsave@GOTOFF[EBX],ESP # save ESP
        MOV     ESP,_rf_sp@GOTOFF[EBX]  # SP to ESP
        JMP     EAX                     # jump to FP
                                        # will return to trampoline1
trampoline2:
        POP     EBX
        POP     ESI
        POP     EBX
        LEAVE                           # leave stack frame
        RET                             # bye

	.globl	rf_start
	.globl	_rf_start
rf_start:
_rf_start:
        CALL    __x86.get_pc_thunk.ax
        ADD     EAX,OFFSET _GLOBAL_OFFSET_TABLE_
        MOV     _rf_w@GOTOFF[EAX],EDX   # EDX to W
        MOV     _rf_ip@GOTOFF[EAX],ESI  # ESI to IP
                                        # C stack frame and return address have
                                        # been pushed to Forth stack; we need to
                                        # move them to the C stack:
        POP     EDX                     # unwind rf_start return address
        MOV     ECX,EBP                 # stack frame size to ECX
        SUB     ECX,ESP
        MOV     ESI,ESP                 # stack frame start to ESI
        MOV     ESP,EBP                 # empty the stack frame, i.e., make ESP = EBP
        POP     EBP                     # EBP that was pushed (this is RP)
        MOV     _rf_rp@GOTOFF[EAX],EBP  # EBP to RP
        MOV     EBP,ebpsave@GOTOFF[EAX] # restore EBP
        MOV     _rf_sp@GOTOFF[EAX],ESP  # ESP to SP
        MOV     ESP,espsave@GOTOFF[EAX] # restore ESP
        PUSH    EBP                     # create new stack frame
        MOV     EBP,ESP
        SUB     ESP,ECX
        MOV     EDI,ESP                 # new stack frame start to EDI
        CLD                             # now copy data from old stack frame
        REP     MOVSB
        JMP     EDX                     # carry on in C

        .globl rf_code_cl
        .globl _rf_code_cl
rf_code_cl:
_rf_code_cl:
        MOV     EAX,4
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

        .globl rf_code_cs
        .globl _rf_code_cs
rf_code_cs:
_rf_code_cs:
        SHL     DWORD PTR [ESP],2
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

        .globl rf_code_ln
        .globl _rf_code_ln
rf_code_ln:
_rf_code_ln:
        POP     EAX
        DEC     EAX
        OR      EAX,3
        INC     EAX
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

        .globl rf_code_mon
        .globl _rf_code_mon
rf_code_mon:
_rf_code_mon:
        PUSH    EBP
        MOV     EBP, ESP
        MOV     EAX,0
        CALL    __x86.get_pc_thunk.bx
        ADD     EBX,OFFSET _GLOBAL_OFFSET_TABLE_
        MOV     _rf_fp@GOTOFF[EBX],EAX
        CALL    _rf_start
        POP     EBP
        RET

        .globl rf_code_cold
        .globl _rf_code_cold
rf_code_cold:
_rf_code_cold:
        CALL    __x86.get_pc_thunk.cx
        ADD     ECX,OFFSET _GLOBAL_OFFSET_TABLE_
        MOV     EDX,_rf_origin@GOTOFF[ECX]
        MOV     EAX,0x18[EDX]   # FORTH vocabulary init
        MOV     EBX,0x54[EDX]
        MOV     [EBX],EAX
        MOV     EDI,0x20[EDX]   # UP init
        MOV     UP@GOTOFF[ECX],EDI
        CLD                     # USER variables init
        MOV     ECX,11
        LEA     ESI,0x18[EDX]
        REP     MOVSD
        MOV     ESI,0x58[EDX]   # IP init to ABORT
        JMP     rf_code_rpsto   # jump to RP!

        .section __DATA.__data,""
        .data

        .p2align 2
ebpsave:.long	0

        .p2align 2
espsave:.long	0

        .p2align 2
        .global rf_fp
        .global _rf_fp
rf_fp:
_rf_fp: .long 0

        .p2align 2
        .global rf_ip
        .global _rf_ip
rf_ip:
_rf_ip: .long 0

        .p2align 2
        .global rf_rp
        .global _rf_rp
rf_rp:
_rf_rp: .long 0

        .p2align 2
        .global rf_sp
        .global _rf_sp
rf_sp:
_rf_sp: .long 0

        .p2align 2
        .global rf_up
        .global _rf_up
rf_up:
_rf_up: .long 0

        .p2align 2
        .global rf_w
        .global _rf_w
rf_w: 
_rf_w:  .long 0

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
DPUSH:  PUSH    EDX
APUSH:  PUSH    EAX
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
rf_next:
_rf_next:
NEXT:   LODSD           # AX<- (IP)
        MOV     EDX,EAX # (W) <- (IP)
#
# -----------------------------------------
#
NEXT1:  JMP     DWORD PTR [EDX] # TO 'CFA'

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
rf_code_lit:
_rf_code_lit:
        LODSD           # AX <- LITERAL
#       JMP     APUSH   # TO TOP OF STACK
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***************
# *   EXECUTE   *
# ***************
#
        .globl rf_code_exec
        .globl _rf_code_exec
rf_code_exec:
_rf_code_exec:
        POP     EDX     # GET CFA
#       JMP     NEXT1   # EXECUTE NEXT
        JMP     DWORD PTR [EDX]


# **************
# *   BRANCH   *
# **************
#
        .globl rf_code_bran
        .globl _rf_code_bran
rf_code_bran:
_rf_code_bran:
BRAN1:  ADD     ESI,[ESI] # (IP) <- (IP) + ((IP))
#       JMP     NEXT    # JUMP TO OFFSET
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***************
# *   0BRANCH   *
# ***************
#
        .globl rf_code_zbran
        .globl _rf_code_zbran
rf_code_zbran:
_rf_code_zbran:
        POP     EAX     # GET STACK VALUE
        OR      EAX,EAX # ZERO?
        JZ      BRAN1   # YES, BRANCH
        ADD     ESI,4   # NO, CONTINUE...
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **************
# *   (LOOP)   *
# **************
#
        .globl rf_code_xloop
        .globl _rf_code_xloop
rf_code_xloop:
_rf_code_xloop:
        MOV     EBX,1   # INCREMENT
XLOO1:  ADD     [EBP],EBX # INDEX=INDEX+INCR
        MOV     EAX,[EBP] # GET NEW INDEX
        SUB     EAX,4[EBP] # COMPARE WITH LIMIT
        XOR     EAX,EBX # TEST SIGN (BIT-16)
        JS      BRAN1   # KEEP LOOPING...

# END OF 'DO' LOOP.
        ADD     EBP,8   # ADJ. RETURN STK
        ADD     ESI,4   # BYPASS BRANCH OFFSET
#       JMP     NEXT    # CONTINUE...
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***************
# *   (+LOOP)   *
# ***************
#
        .globl rf_code_xploo
        .globl _rf_code_xploo
rf_code_xploo:
_rf_code_xploo:
        POP     EBX     # GET LOOP VALUE
        JMP     XLOO1


# ************
# *   (DO)   *
# ************
#
        .globl rf_code_xdo
        .globl _rf_code_xdo
rf_code_xdo:
_rf_code_xdo:
        POP     EDX     # INITIAL INDEX VALUE
        POP     EAX     # LIMIT VALUE
        XCHG    EBP,ESP # GET RETURN STACK
        PUSH    EAX
        PUSH    EDX
        XCHG    EBP,ESP # GET PARAMETER STACK
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *********
# *   I   *
# *********
#
        .globl rf_code_rr
        .globl _rf_code_rr
rf_code_rr:
_rf_code_rr:
        MOV     EAX,[EBP] # GET INDEX VALUE
#       JMP     APUSH   # TO PARAMETER STACK
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *************
# *   DIGIT   *
# *************
#
        .globl rf_code_digit
        .globl _rf_code_digit
rf_code_digit:
_rf_code_digit:
        POP     EDX     # NUMBER BASE
        POP     EAX     # ASCII DIGIT
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
        SUB     EDX,EDX # ZERO
        MOV     DL,AL   # NEW BINARY NUMBER
        MOV     AL,1    # TRUE FLAG
#       JMP     DPUSH   # ADD TO STACK
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

# NUMBER ERROR
#
DIGI2:  SUB     EAX,EAX # FALSE FLAG
#       JMP     APUSH   # BYE
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **************
# *   (FIND)   *
# **************
#
        .globl rf_code_pfind
        .globl _rf_code_pfind
rf_code_pfind:
_rf_code_pfind:
#       MOV     AX,DS
#       MOV     ES,AX   # ES = DS
        POP     EBX     # NFA
        POP     ECX     # STRING ADDR
#
# SEARCH LOOP
PFIN1:  MOV     EDI,ECX # GET ADDR
        MOV     AL,[EBX] # GET WORD LENGTH
        MOV     DL,AL   # SAVE LENGTH
        XOR     AL,[EDI]
        AND     AL,0x3F # CHECK LENGTHS
        JNZ     PFIN5   # LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
PFIN2:  INC     EBX
        INC     EDI     # NEXT CHAR OF NAME
        MOV     AL,[EBX]
        XOR     AL,[EDI] # COMPARE NAMES
        ADD     AL,AL   # THIS WILL TEST BIT-8
        JNZ     PFIN5   # NO MATCH
        JNB     PFIN2   # MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
        ADD     EBX,9   # BX = PFA
        PUSH    EBX     # (S3) <- PFA
        MOV     EAX,1   # TRUE VALUE
#       SUB     DH,DH   # CLEAR HIGH LENGTH
        AND     EDX,0xFF
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
PFIN5:  INC     EBX     # NEXT ADDR
        JB      PFIN6   # END OF NAME
        MOV     AL,[EBX] # GET NEXT CHAR
        ADD     AL,AL   # SET/RESET CARRY
        JMP     PFIN5   # LOOP UNTIL FOUND
#
PFIN6:  MOV     EBX,[EBX] # GET LINK FIELD ADDR
        OR      EBX,EBX # START OF DICT. (0)?
        JNZ     PFIN1   # NO, LOOK SOME MORE
        MOV     EAX,0   # FALSE FLAG
#       JMP     APUSH   # DONE (NO MATCH FOUND)
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***************
# *   ENCLOSE   *
# ***************
#
        .globl rf_code_encl
        .globl _rf_code_encl
rf_code_encl:
_rf_code_encl:
        POP     EAX     # S1 - TERMINATOR CHAR.
        POP     EBX     # S2 - TEXT ADDR
        PUSH    EBX     # ADDR BACK TO STACK
#       MOV     AH,0    # ZERO
        AND     EAX,0xFF
        MOV     EDX,-1  # CHAR OFFSET COUNTER
        DEC     EBX     # ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
ENCL1:  INC     EBX     # ADDR +1
        INC     EDX     # COUNT +1
        CMP     AL,[EBX]
        JZ      ENCL1   # WAIT FOR NON-TERMINATOR
        PUSH    EDX     # OFFSET TO 1ST TEXT CHR
        CMP     AH,[EBX] # NULL CHAR?
        JNZ     ENCL2   # NO

# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
        MOV     EAX,EDX # COPY COUNTER
        INC     EDX     # +1
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
ENCL2:  INC     EBX     # ADDR+1
        INC     EDX     # COUNT +1
        CMP     AL,[EBX] # TERMINATOR CHAR?
        JZ      ENCL4   # YES
        CMP     AH,[EBX] # NULL CHAR
        JNZ     ENCL2   # NO, LOOP AGAIN

# FOUND NULL AT END OF TEXT
#
ENCL3:  MOV     EAX,EDX # COUNTERS ARE EQUAL
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

# FOUND TERINATOR CHARACTER
ENCL4:  MOV     EAX,EDX
        INC     EAX     # COUNT +1
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *************
# *   CMOVE   *
# *************
#
        .globl rf_code_cmove
        .globl _rf_code_cmove
rf_code_cmove:
_rf_code_cmove:
        CLD             # INC DIRECTION
        MOV     EBX,ESI # SAVE IP
        POP     ECX     # COUNT
        POP     EDI     # DEST.
        POP     ESI     # SOURCE
#       MOV     AX,DS
#       MOV     ES,AX   # ES <- DS
        REP     MOVSB   # THATS THE MOVE
        MOV     ESI,EBX # GET BACK IP
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   U*   *
# **********
#
        .globl rf_code_ustar
        .globl _rf_code_ustar
rf_code_ustar:
_rf_code_ustar:
        POP     EAX
        POP     EBX
        MUL     EBX     # UNSIGNED
#       XCHG    EAX,EDX # AX NOW = MSW
#       JMP     DPUSH   # STORE DOUBLE WORD
        PUSH    EAX
        PUSH    EDX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   U/   *
# **********
#
        .globl rf_code_uslas
        .globl _rf_code_uslas
rf_code_uslas:
_rf_code_uslas:
        POP     EBX     # DIVISOR
        POP     EDX     # MSW OF DIVIDEND
        POP     EAX     # LSW OF DIVIDEND
        CMP     EDX,EBX # DIVIDE BY ZERO?
        JNB     DZERO   # ZERO DIVIDE, NO WAY
        DIV     EBX     # 16 BIT DIVIDE
#       JMP     DPUSH   # STORE QUOT/REM
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

# DIVIDE BY ZERO ERROR (SHOW MAX NUMBERS)
#
DZERO:  MOV     EAX,-1
        MOV     EDX,EAX
#       JMP     DPUSH   # STORE QUOT/REM
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***********
# *   AND   *
# ***********
#
        .globl rf_code_andd
        .globl _rf_code_andd
rf_code_andd:           # (S1) <- (S1) AND (S2)
_rf_code_andd:
        POP     EAX
        POP     EBX
        AND     EAX,EBX
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   OR   *
# **********
#
        .globl rf_code_orr
        .globl _rf_code_orr
rf_code_orr:            # (S1) <- (S1) OR (S2)
_rf_code_orr:
        POP     EAX
        POP     EBX
        OR      EAX,EBX
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***********
# *   XOR   *
# ***********
#
        .globl rf_code_xorr
        .globl _rf_code_xorr
rf_code_xorr:           # (S1) <- (S1) XOR (S2)
_rf_code_xorr:
        POP     EAX
        POP     EBX
        XOR     EAX,EBX
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***********
# *   SP@   *
# ***********
#
        .globl rf_code_spat
        .globl _rf_code_spat
rf_code_spat:           # (S1) <- (SP)
_rf_code_spat:
        MOV     EAX,ESP
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***********
# *   SP!   *
# ***********
#
        .globl rf_code_spsto
        .globl _rf_code_spsto
rf_code_spsto:
_rf_code_spsto:
        CALL    __x86.get_pc_thunk.ax
        ADD     EAX,OFFSET _GLOBAL_OFFSET_TABLE_
        MOV     EBX,UP@GOTOFF[EAX] # USER VAR BASE ADDR
        MOV     ESP,12[EBX] # RESET PARAM. STACK PT.
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***********
# *   RP!   *
# ***********
#
        .globl rf_code_rpsto
        .globl _rf_code_rpsto
rf_code_rpsto:
_rf_code_rpsto:
        CALL    __x86.get_pc_thunk.ax
        ADD     EAX,OFFSET _GLOBAL_OFFSET_TABLE_
        MOV     EBX,UP@GOTOFF[EAX] # (AX) <- USR VAR. BASE
        MOV     EBP,16[EBX] # RESET RETURN STACK PT.
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   ;S   *
# **********
#
        .globl rf_code_semis
        .globl _rf_code_semis
rf_code_semis:
_rf_code_semis:
        MOV     ESI,[EBP] # (IP) <- (R1)
        ADD     EBP,4   # ADJUST STACK
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *************
# *   LEAVE   *
# *************
#
        .globl rf_code_leave
        .globl _rf_code_leave
rf_code_leave:          # LIMIT <- INDEX
_rf_code_leave:
        MOV     EAX,[EBP] # GET INDEX
        MOV     4[EBP],EAX # STORE IT AT LIMIT
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   >R   *
# **********
#
        .globl rf_code_tor
        .globl _rf_code_tor
rf_code_tor:            # (R1) <- (S1)
_rf_code_tor:
        POP     EBX     # GET STACK PARAMETER
        SUB     EBP,4   # MOVE RETURN STACK DOWN
        MOV     [EBP],EBX # ADD TO RETURN STACK
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   R>   *
# **********
#
        .globl rf_code_fromr
        .globl _rf_code_fromr
rf_code_fromr:          # (S1) <- (R1)
_rf_code_fromr:
        MOV     EAX,[EBP] # GET RETURN STACK VALUE
        ADD     EBP,4   # DELETE FROM STACK
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   0=   *
# **********
#
        .globl rf_code_zequ
        .globl _rf_code_zequ
rf_code_zequ:
_rf_code_zequ:
        POP     EAX
        OR      EAX,EAX # DO TEST
        MOV     EAX,1   # TRUE
        JZ      ZEQU1   # ITS ZERO
        DEC     EAX     # FALSE
ZEQU1:  # JMP   APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   0<   *
# **********
#
        .globl rf_code_zless
        .globl _rf_code_zless
rf_code_zless:
_rf_code_zless:
        POP     EAX
        OR      EAX,EAX # SET FLAGS
        MOV     EAX,1   # TRUE
        JS      ZLESS1
        DEC     EAX     # FLASE
ZLESS1: # JMP   APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *********
# *   +   *
# *********
#
        .globl rf_code_plus
        .globl _rf_code_plus
rf_code_plus:           # (S1) <- (S1) + (S2)
_rf_code_plus:
        POP     EAX
        POP     EBX
        ADD     EAX,EBX
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   D+   *
# **********
#
# XLW XHW  YLW YHW --> SLW SHW
# S4  S3   S2  S1      S2  S1
#
        .globl rf_code_dplus
        .globl _rf_code_dplus
rf_code_dplus:
_rf_code_dplus:
        POP     EAX     # YHW
        POP     EDX     # YLW
        POP     EBX     # XHW
        POP     ECX     # XLW
        ADD     EDX,ECX # SLW
        ADC     EAX,EBX # SHW
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *************
# *   MINUS   *
# *************
#
        .globl rf_code_minus
        .globl _rf_code_minus
rf_code_minus:
_rf_code_minus:
        POP     EAX
        NEG     EAX
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **************
# *   DMINUS   *
# **************
#
        .globl rf_code_dminu
        .globl _rf_code_dminu
rf_code_dminu:
_rf_code_dminu:
        POP     EBX
        POP     ECX
        SUB     EAX,EAX # ZERO
        MOV     EDX,EAX
        SUB     EDX,ECX # MAKE 2'S COMPLEMENT
        SBB     EAX,EBX # HIGH WORD
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ************
# *   OVER   *
# ************
#
        .globl rf_code_over
        .globl _rf_code_over
rf_code_over:
_rf_code_over:
        POP     EDX
        POP     EAX
        PUSH    EAX
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ************
# *   DROP   *
# ************
#
        .globl rf_code_drop
        .globl _rf_code_drop
rf_code_drop:
_rf_code_drop:
        POP     EAX
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ************
# *   SWAP   *
# ************
#
        .globl rf_code_swap
        .globl _rf_code_swap
rf_code_swap:
_rf_code_swap:
        POP     EDX
        POP     EAX
#       JMP     DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ***********
# *   DUP   *
# ***********
#
        .globl rf_code_dup
        .globl _rf_code_dup
rf_code_dup:
_rf_code_dup:
        POP     EAX
        PUSH    EAX
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   +!   *
# **********
#
        .globl rf_code_pstor
        .globl _rf_code_pstor
rf_code_pstor:          # ((S1)) <- ((S1)) + (S2)
_rf_code_pstor:
        POP     EBX     # ADDRESS
        POP     EAX     # INCREMENT
        ADD     [EBX],EAX
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **************
# *   TOGGLE   *
# **************
#
        .globl rf_code_toggl
        .globl _rf_code_toggl
rf_code_toggl:
_rf_code_toggl:
        POP     EAX     # BIT PATTERN
        POP     EBX     # ADDR
        XOR     [EBX],AL
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *********
# *   @   *
# *********
#
        .globl rf_code_at
        .globl _rf_code_at
rf_code_at:             # (S1) <- ((S1))
_rf_code_at:
        POP     EBX
        MOV     EAX,[EBX]
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   C@   *
# **********
#
        .globl rf_code_cat
        .globl _rf_code_cat
rf_code_cat:
_rf_code_cat:
        POP     EBX
#       MOV     AL,[EBX]
#       AND     EAX,0xFF
        MOVZX   EAX, BYTE PTR [EBX]
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *********
# *   !   *
# *********
#
        .globl rf_code_store
        .globl _rf_code_store
rf_code_store:          # ((S1)) <- (S2)
_rf_code_store:
        POP     EBX     # ADDR
        POP     EAX     # DATA
        MOV     [EBX],EAX
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# **********
# *   C!   *
# **********
#
        .globl rf_code_cstor
        .globl _rf_code_cstor
rf_code_cstor:
_rf_code_cstor:
        POP     EBX     # ADDR
        POP     EAX     # DATA
        MOV     [EBX],AL
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *********
# *   :   *
# *********
#
        .globl rf_code_docol
        .globl _rf_code_docol
rf_code_docol:
_rf_code_docol:
DOCOL:  ADD     EDX,4   # W=W+1
        SUB     EBP,4   # (RP) <- (RP)-2
        MOV     [EBP],ESI # R1 <- (RP)
        MOV     ESI,EDX # (IP) <- (W)
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ****************
# *   CONSTANT   *
# ****************
#
        .globl rf_code_docon
        .globl _rf_code_docon
rf_code_docon:
_rf_code_docon:
DOCON:  # ADD   EDX,4   # PFA
#       MOV     EBX,EDX
#       MOV     EAX,[EBX] # GET DATA
        MOV     EAX,4[EDX]
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

# ****************
# *   VARIABLE   *
# ****************
#
        .globl rf_code_dovar
        .globl _rf_code_dovar
rf_code_dovar:
_rf_code_dovar:
DOVAR:  ADD     EDX,4   # (DE) <- PFA
        PUSH    EDX     # (S1) <- PFA
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]

# ************
# *   USER   *
# ************
#
        .globl rf_code_douse
        .globl _rf_code_douse
rf_code_douse:
_rf_code_douse:
DOUSE:  # ADD   EDX,4   # PFA
#       MOV     EBX,EDX
#       MOV     BL,[EBX]
#       AND     EBX,0xFF
        MOVZX   EBX, BYTE PTR 4[EDX]
        CALL    __x86.get_pc_thunk.ax
        ADD     EAX,OFFSET _GLOBAL_OFFSET_TABLE_
        MOV     EDI,UP@GOTOFF[EAX] # USER VARIABLE ADDR
        LEA     EAX,[EBX+EDI] # ADDR OF VARIABLE
#       JMP     APUSH
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# *************
# *   DOES>   *
# *************
#
        .globl rf_code_dodoe
        .globl _rf_code_dodoe
rf_code_dodoe:
_rf_code_dodoe:
DODOE:  XCHG    EBP,ESP # GET RETURN STACK
        PUSH    ESI     # (RP) <- (IP)
        XCHG    EBP,ESP
#       ADD     EDX,4   # PFA
#       MOV     EBX,EDX
#       MOV     ESI,[EBX] # NEW CFA
#       ADD     EDX,4
        MOV     ESI,4[EDX]
        ADD     EDX,8
        PUSH    EDX     # PFA
#       JMP     NEXT
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]


# ************
# *   S->D   *
# ************
#
        .globl rf_code_stod
        .globl _rf_code_stod
rf_code_stod:
_rf_code_stod:
        POP     EDX     # S1
        SUB     EAX,EAX # AX = 0
        OR      EDX,EDX # SET FLAGS
        JNS     STOD1   # POSITIVE NUMBER
        DEC     EAX     # NEGITIVE NUMBER
STOD1:  # JMP   DPUSH
        PUSH    EDX
        PUSH    EAX
        LODSD
        MOV     EDX,EAX
        JMP     DWORD PTR [EDX]
