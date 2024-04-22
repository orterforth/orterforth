;.import initlib, donelib
.import _main
.importzp sp

.export __STARTUP__ : absolute = 1
		
EVNTV  =$0220
OSBYTE =$FFF4

.segment "STARTUP"

.export __Cstart

__Cstart:

       LDA #$00                 ; init C stack at $0600
       STA sp
       LDA #$06
       STA sp+1

       SEI                      ; set escape handler
       LDA EVNTV
       STA EVNTVS
       LDA EVNTV+1
       STA EVNTVS+1	
       LDA #<hand
       STA EVNTV
       LDA #>hand
       STA EVNTV+1
       CLI

       LDA #$0E                 ; enable escape event
       LDX #$06
       JSR OSBYTE
       STX enable_save

;      JSR initlib              ; run constructors

       TSX                      ; save S
       STX s_save

       JSR _main                ; call C

dox:   TAX                      ; return exit code in user flag
       LDY #$00
       LDA #$01
       JSR OSBYTE

;      JSR donelib              ; run destructors

       LDA enable_save          ; reset escape event state
       BNE dox1
       LDA #$0D
       LDX #$06
       JSR OSBYTE

dox1:  SEI                      ; restore event handler
       LDA EVNTVS
       STA EVNTV
       LDA EVNTVS+1
       STA EVNTV+1
       CLI

       RTS                      ; done

.export _exit

_exit: LDX s_save               ; restore S
       TXS
       JMP dox                  ; as above

hand:  PHP
       CMP #$06                 ; if escape detected, no op
       BNE hand1
       PLP
       RTS
hand1: PLP                      ; else forward to saved handler
       JMP (EVNTVS)

.bss

EVNTVS: .res 2
enable_save: .res 1
s_save: .res 1
