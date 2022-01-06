.import incsp1
.importzp	sp

.export	_osbyte

_osbyte:
	tax
	ldy #0
	lda (sp),y
	jsr $FFF4
	jsr incsp1
	rts

.export	_osnewl

_osnewl:
	jmp $FFE7

.export _osrdch

_osrdch:
	ldx	#0
	jmp	$FFE0

.export _oswrch

_oswrch:
	jmp	$FFEE
