CPMZCCOPTS := +cpm -lm

cpm :

	mkdir $@

.PHONY : cpm-build
cpm-build : cpm/inst.com

cpm/%.lib : %.c rf.h target/cpm/cpm.inc | cpm

	zcc $(CPMZCCOPTS) -x -o $@ $<

cpm/hw.com : hw.c | cpm

	zcc $(CPMZCCOPTS) -o $@ $<

cpm/inst.com cpm/inst.map : cpm/inst.lib cpm/io.lib cpm/rf.lib cpm/system.lib main.c

	zcc $(CPMZCCOPTS) -lcpm/inst -lcpm/io -lcpm/rf -lcpm/system -m -o $@ main.c

cpm/system.lib : target/cpm/system.c rf.h target/cpm/cpm.inc | cpm

	zcc $(CPMZCCOPTS) -x -o $@ $<
