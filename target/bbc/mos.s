.import incsp1
.importzp sp

.export _osbyte

_osbyte:
       TAX
       LDY #0
       LDA (sp),Y
       JSR $FFF4
       TXA
       JMP incsp1

.export _osnewl: near

_osnewl = $FFE7
;_osnewl:
;      JMP $FFE7

.export _osrdch

_osrdch:
       LDX #0
       JMP $FFE0

.export _oswrch: near

_oswrch = $FFEE
;_oswrch:
;      JMP $FFEE
