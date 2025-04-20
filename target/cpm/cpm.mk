CPMZCCOPTS := +cpm -lm

cpm :

	mkdir $@

.PHONY : cpm-build
cpm-build : cpm/inst.dsk

cpm/%.lib : %.c rf.h target/cpm/cpm.inc | cpm

	zcc $(CPMZCCOPTS) -x -o $@ $<

cpm/hw.bin cpm/hw.com cpm/hw.dsk : hw.c | cpm

	zcc $(CPMZCCOPTS) -o cpm/hw.bin $< -create-app -subtype=z80pack

cpm/inst.bin cpm/inst.com cpm/inst.dsk : cpm/inst.lib cpm/io.lib cpm/rf.lib cpm/system.lib main.c

	zcc $(CPMZCCOPTS) -lcpm/inst -lcpm/io -lcpm/rf -lcpm/system -m -o cpm/inst.bin main.c -create-app -subtype=z80pack

cpm/system.lib : target/cpm/system.c rf.h target/cpm/cpm.inc | cpm

	zcc $(CPMZCCOPTS) -x -o $@ $<
