Z88MAMEOPTS := z88 $(MAMEOPTS)

Z88ORG := 0x0000
Z88ORIGIN := 0x0000

Z88ZCCOPTS := +z88 \
	-DRF_ORG=$(Z88ORG) \
	-DRF_ORIGIN=$(Z88ORIGIN) \
	-DRF_TARGET_INC='\"target/z88/system.inc\"'

z88 :

	mkdir $@

.PHONY : z88-hw
z88-hw : z88/hw.imp

	$(ORTER) serial -o ixon -o ixoff -e 15 $(SERIALPORT) 9600 < $<

.PHONY : z88-inst
z88-inst : z88/inst.imp

	$(ORTER) serial -o ixon -o ixoff -e 15 $(SERIALPORT) 9600 < $<

.PHONY : z88-run
z88-run :

	mame $(Z88MAMEOPTS)

z88/hw.bin : hw.c | z88

	zcc $(Z88ZCCOPTS) -o $@ $<

z88/hw.imp : z88/hw.bin

	$(ORTER) z88 imp-export write HW < $< > $@.io
	mv $@.io $@

z88/inst.bin z88/inst.map : z88/rf.lib z88/system.lib z88/inst.lib main.c

	zcc $(Z88ZCCOPTS) -lm -lz88/rf -lz88/system -lz88/inst \
		-m -o z88/inst.bin main.c

z88/inst.imp : z88/inst.bin

	$(ORTER) z88 imp-export write INST < $< > $@.io
	mv $@.io $@

z88/inst.lib : inst.c rf.h | z88

	zcc $(ZX81ZCCOPTS) -x -o $@ $<

z88/rf.lib : rf.c rf.h target/z88/system.inc | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<

z88/system.lib : target/z88/system.c rf.h | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<
