; .import initlib, donelib
.import callmain	
.importzp sp

.export __STARTUP__ : absolute = 1
		
.include "zeropage.inc"

evntv := $0220
osbyte := $FFF4

.segment	"STARTUP"

.export __Cstart

__Cstart:

	lda	#$00                      ; init stack at $0600
	sta	sp
	lda	#$06
	sta	sp+1

	sei                           ; set escape handler
	lda	evntv
	sta	evntv_save
	lda	evntv+1
	sta	evntv_save+1	
	lda	#<handle
	sta	evntv
	lda	#>handle
	sta	evntv+1
	cli

	lda	#$0E                      ; enable escape event
	ldx	#$06
	jsr	osbyte
	stx	enable_save

;	jsr	initlib                   ; run constructors

	tsx                           ; save S
	stx	s_save

	jsr	callmain                  ; call C

doexit:
	tax                           ; return exit code in user flag
	ldy	#$00
	lda	#$01
	jsr	osbyte

;	jsr donelib

	lda	enable_save               ; reset escape event state
	bne	doexit1
	lda	#$0D
	ldx	#$06
	jsr	osbyte

doexit1:
	sei                           ; restore event handler
	lda	evntv_save
	sta	evntv
	lda	evntv_save+1
	sta	evntv+1
	cli

	rts                           ; done

.export _exit

_exit:

	ldx	s_save                    ; restore S
	txs
	jmp	doexit                    ; as above

handle:

	php
	cmp	#$06                      ; is esc?
	bne	handle1
	plp                           ; no op
	rts
handle1:
	plp                           ; else forward to saved handler
	jmp	(evntv_save)

.export initmainargs

initmainargs:
	rts                           ; dummy initmainargs

.bss

evntv_save: .res 2
enable_save: .res 1
s_save: .res 1
