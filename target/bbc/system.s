.importzp N
.importzp UP
.importzp XSAVE
.import POP
.import SETUP
.import NEXT
.import PUSH0A

osrdch := $FFE0
oswrch := $FFEE
osnewl := $FFE7
osbyte := $FFF4

.export _rf_init

_rf_init:
       LDA #7                   ; *FX 7,7 (9600 baud receive)
       TAX
       JSR osbyte
       LDA #8                   ; *FX 8,7 (9600 baud transmit)
       LDX #7
       JSR osbyte
       LDA #2                   ; *FX 2,2 (enable RS423, input from keyboard)
       TAX
       JSR osbyte
       LDA #3                   ; *FX 3,4 (output to screen only)
       LDX #4
       JSR osbyte
       RTS

.export _rf_code_emit

_rf_code_emit:
       TYA
       SEC
       LDY #$1A
       ADC (UP),Y
       STA (UP),Y
       INY
       LDA #0
       ADC (UP),Y
       STA (UP),Y
       LDA 0,X
       AND #$7F
       STX XSAVE
       JSR oswrch
       LDX XSAVE
       JMP POP

.export _rf_code_key

_rf_code_key:
       STX XSAVE
       JSR osrdch
       LDX XSAVE
       JMP PUSH0A

.export _rf_code_cr

_rf_code_cr:
       STX XSAVE
       JSR osnewl
       LDX XSAVE
       JMP NEXT

.export _rf_code_qterm

_rf_code_qterm:
       STX XSAVE
       LDA #121                 ; *FX 121,240 (scan for escape key)
       LDX #240
       JSR osbyte
       LDA #0                   ; return 1 if pressed
       CPX #0
       BPL qterm1
       LDA #1
qterm1:LDX XSAVE
       JMP PUSH0A

.export _rf_fin

_rf_fin:
       LDA #2                   ; *FX 2,0 (use keyboard, disable RS423)
       LDX #0
       JSR osbyte
       LDA #3                   ; *FX 3,4 (output to screen only)
       LDX #4
       JMP osbyte

.export _rf_code_dchar

_rf_code_dchar:
       STX XSAVE
       LDA #2                   ; *FX 2,1 (read from RS423)
       LDX #1
       JSR osbyte
       JSR osrdch               ; read 1 byte and push
       PHA
       LDA #2                   ; *FX 2,2 (read from keyboard)
       TAX
       JSR osbyte
       LDX XSAVE
       LDY #0
       DEX
       DEX
       STY 1,X                  ; zero high byte
       PLA                      ; pull 1 byte
       STA 0,X
       CMP 2,X                  ; return true if equal
       BNE dchar1
       INY
dchar1:STY 2,X
       JMP NEXT

.export _rf_code_bread

_rf_code_bread:
       LDA #1                   ; fetch addr into N
       JSR SETUP
       STX XSAVE
       LDA #2                   ; *FX 2,1 (read from RS423)
       LDX #1
       JSR osbyte
       LDY #0                   ; read 128 bytes
bread1:JSR osrdch
       STA (N),Y
       INY
       BPL bread1
bread2:LDA #2                   ; *FX 2,2 (read from keyboard)
       TAX
       JSR osbyte
       LDX XSAVE
       JMP NEXT

.export _rf_code_bwrit

_rf_code_bwrit:
       LDA #2
       JSR SETUP
       STX XSAVE
       LDA #3                   ; *FX 3,7 (write to RS423)
       LDX #7
       JSR osbyte
       LDY #0
bwrit1:CPY N
       BNE bwrit2
       LDA #4                   ; EOT
       JSR oswrch
       TAX                      ; *FX 3,4 (write to screen)
       LDA #3
       JSR osbyte
       LDX XSAVE
       JMP NEXT
bwrit2:LDA (N+2),Y              ; write 1 byte
       JSR oswrch
       INY                      ; loop
       BNE bwrit1
