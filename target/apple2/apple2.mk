APPLE2CC65OPTS := -O -t apple2

apple2 :

	mkdir $@

.PHONY : apple2-hw
apple2-hw :

	mame apple2 $(MAMEOPTS)

apple2/%.o : apple2/%.s

	ca65 -t apple2 -o $@ $<

apple2/hw : hw.c | apple2

	cl65 -O -t apple2 -o $@ $^

apple2/inst apple2/inst.map : apple2/inst.o apple2/main.o apple2/rf.o apple2/system.o

	cl65 -O -t apple2 -o $@ -m apple2/inst.map $^

apple2/inst.s : inst.c inst.h rf.h target/apple2/apple2.inc | apple2

	cc65 $(APPLE2CC65OPTS) -o $@ $<

apple2/main.s : main.c inst.h rf.h target/apple2/apple2.inc | apple2

	cc65 $(APPLE2CC65OPTS) -o $@ $<

apple2/rf.s : rf.c rf.h target/apple2/apple2.inc | apple2

	cc65 $(APPLE2CC65OPTS) -o $@ $<

apple2/system.s : target/apple2/system.c rf.h target/apple2/apple2.inc | apple2

	cc65 $(APPLE2CC65OPTS) -o $@ $<
