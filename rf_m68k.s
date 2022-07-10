	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
	.sect	.data

	.sect	.text
	.align	2
	.extern _rf_trampoline
_rf_trampoline:
	link   a6, #0
trampoline1:
  move.l _rf_fp, d0
	tst.l  d0
	beq    trampoline2
	move.l _rf_rp, a1
	move.l _rf_sp, a3
	move.l _rf_ip, a4
	move.l _rf_w, a5
  addq.l #4, a5
	move.l d0, a0
	jsr    (a0)
	bra    trampoline1
trampoline2:
	unlk   a6
	rts

	.align	2
	.extern _rf_start
_rf_start:
	move.l a1, _rf_rp
	move.l a3, _rf_sp
	move.l a4, _rf_ip
  subq.l #4, a5
	move.l a5, _rf_w
	rts

	.align	2
	.extern _rf_code_lit
_rf_code_lit:
  move.l (a4)+, -(a3)

	.align	2
	.extern _rf_next
_rf_next:
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_exec
_rf_code_exec:
  move.l (a3)+, a5
  move.l (a5)+, a0
	jmp    (a0)

	.align	2
	.extern _rf_code_bran
_rf_code_bran:
  move.l (a4), d0
	add.l  d0, a4
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_zbran
_rf_code_zbran:
  tst.l  (a3)+
	beq    _rf_code_bran
	addq.l #4, a4
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_xloop
_rf_code_xloop:
  addq.l #1, (a1)
xloo2:
  move.l 4(a1), d0
	cmp.l  (a1), d0
	bhi    xloo3
	add.l  #4, a4
	add.l  #8, a1
	bra    xloo4
xloo3:
  move.l (a4), d0
  add.l  d0, a4
xloo4:
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_xploo
_rf_code_xploo:
  move.l (a3)+, d0
	add.l  d0, (a1)
  bra    xloo2

	.align	2
	.extern _rf_code_xdo
_rf_code_xdo:
  move.l (a3)+, d0
  move.l (a3)+, -(a1)
  move.l d0, -(a1)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_andd
_rf_code_andd:
	move.l (a3)+, d0
	and.l  d0, (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_orr
_rf_code_orr:
	move.l (a3)+, d0
	or.l   d0, (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_xorr
_rf_code_xorr:
	move.l (a3)+, d0
	eor.l  d0, (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_spat
_rf_code_spat:
  move.l a3, d0
  move.l d0, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_spsto
_rf_code_spsto:
  move.l _rf_up, a0
	move.l 12(a0), a3
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_rpsto
_rf_code_rpsto:
  move.l _rf_up, a0
	move.l 16(a0), a1
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_cmove
_rf_code_cmove:
	move.l (a3)+, d0
	move.l (a3)+, a2
	move.l (a3)+, a0
	bra movfw1
movfwd:
  move.b (a0)+, (a2)+
movfw1:
	dbf    d0, movfwd
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_ustarz
_rf_code_ustarz:
	move.l (a3)+, d0
	move.l (a3)+, d1

  move.w  d0,d3
  mulu.w  d1,d3 ;d3.l is Al*Bl now

  swap    d0
  swap    d1
  move.w  d0,d2
  mulu.w  d1,d2 ;d2.l is Ah*Bh now

  swap    d0
  move.w  d0,d4
  mulu.w  d1,d4 ;d4 is Al*Bh

  swap    d4
  moveq   #0,d5
  move.w  d4,d5
  clr.w   d4      ; d5:d4 is 0x0000:Nh:Nl:0x0000, where N is Al*Bh

  add.l   d4,d3
  addx.l  d5,d2   ;add Al*Bh*0x10000 to the partial result in d2:d3

  swap    d0
  swap    d1

  move.w  d0,d4
  mulu.w  d1,d4 ;d4 is Ah*Bl

  swap    d4
  moveq   #0,d5
  move.w  d4,d5
  clr.w   d4      ; d5:d4 is 0x0000:Nh:Nl:0x0000, where N is Ah*Bl

  add.l   d4,d3
  addx.l  d5,d2   ;add Ah*Bl*0x10000 to the partial result

  ;d2:d3 is now the result
  move.l d3, -(a3)
  move.l d2, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_semis
_rf_code_semis:
  move.l (a1)+, a4
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_leave
_rf_code_leave:
	move.l (a1), 4(a1)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_tor
_rf_code_tor:
	move.l (a3)+, -(a1)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_fromr
_rf_code_fromr:
	move.l (a1)+, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_rr
_rf_code_rr:
	move.l (a1), -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_zequ
_rf_code_zequ:
  tst.l  (a3)
	seq    3(a3)
	and.l  #1, (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_zless
_rf_code_zless:
  tst.l  (a3)
	smi    3(a3)
	and.l  #1, (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_plus
_rf_code_plus:
  move.l (a3)+, d0
	add.l  d0, (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_minus
_rf_code_minus:
	neg.l  (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_dplus
_rf_code_dplus:
  move.l (a3)+, d0
  move.l (a3)+, d1
  move.l (a3)+, d2
  move.l (a3)+, d3
  add.l  d3, d1
  addx.l d2, d0
  move.l d1, -(a3)
  move.l d0, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_dminu
_rf_code_dminu:
  neg.l  4(a3)
  negx.l (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_over
_rf_code_over:
  move.l 4(a3), d0
	move.l d0, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_drop
_rf_code_drop:
	addq.l #4, a3
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_swap
_rf_code_swap:
	move.l (a3)+, d0
	move.l (a3), d1
	move.l d0, (a3)
	move.l d1, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_dup
_rf_code_dup:
	move.l (a3), d0
	move.l d0, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_pstor
_rf_code_pstor:
  move.l (a3)+, a0
	move.l (a3)+, d0
	add.l  d0, (a0)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_toggl
_rf_code_toggl:
  move.l (a3)+, d0
	move.l (a3)+, a0
	eor.b  d0, (a0)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_at
_rf_code_at:
  move.l (a3), a0
	move.l (a0), (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_cat
_rf_code_cat:
  move.l (a3), a0
  move.l #0, (a3)
	move.b (a0), 3(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_store
_rf_code_store:
  move.l	(a3)+, a0
  move.l	(a3)+, (a0)
!;	move.b  (a3)+, (a0)+
!;	move.b  (a3)+, (a0)+
!;	move.b  (a3)+, (a0)+
!;	move.b  (a3)+, (a0)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_cstor
_rf_code_cstor:
  move.l (a3)+, a0
  addq.l #3, a3
	move.b (a3)+, (a0)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_docol
_rf_code_docol:
  move.l a4, -(a1)
  move.l a5, a4
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_docon
_rf_code_docon:
  move.l (a5), -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_dovar
_rf_code_dovar:
  move.l a5, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_douse
_rf_code_douse:
	move.l (a5), d0
!;	ADD.W	A6,D0
  add.l  _rf_up, d0
	move.l d0, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_dodoe
_rf_code_dodoe:
  move.l a4, -(a1)
	move.l (a5)+, a4
	move.l a5, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_stod
_rf_code_stod:
	tst.l  (a3)
	bmi    stod1
	move.l #0, -(a3)
	bra    stod2
stod1:
  move.l #$FFFFFFFF, -(a3)
stod2:
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_rcll
_rf_code_rcll:
  moveq.l #4, d0
  move.l  d0, -(a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)

	.align	2
	.extern _rf_code_rcls
_rf_code_rcls:
  move.l (a3), d0
  lsl.l  #2, d0
  move.l d0, (a3)
  !;bra    _rf_next
  move.l (a4)+, a5
  move.l (a5)+, a0
  jmp    (a0)
