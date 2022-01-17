.import incsp1
.importzp	sp

.export	_osbyte

_osbyte:
	tax
	ldy #0
	lda (sp),y
	jsr $FFF4
	jmp incsp1

.export	_osnewl

_osnewl:
	jmp $FFE7

.export _osrdch

_osrdch:
	ldx	#0
	jmp	$FFE0

.export _oswrch: near

_oswrch = $FFEE
; _oswrch:
; 	jmp	$FFEE
