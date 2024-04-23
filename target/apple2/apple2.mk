apple2 :

	mkdir $@

apple2/%.o : apple2/%.s

	ca65 -t apple2 -o $@ $<

apple2/%.s : %.c rf.h target/apple2/apple2.inc | apple2

	cc65 -O -t apple2 -o $@ $<

apple2/hw apple2/hw.map : apple2/hw.o

	cl65 -O -t apple2 -o $@ -m apple2/hw.map $^

apple2/inst apple2/inst.map : apple2/inst.o apple2/io.o apple2/main.o apple2/rf.o apple2/system.o

	cl65 -O -t apple2 -o $@ -m apple2/inst.map $^

apple2/system.s : target/apple2/system.c rf.h target/apple2/apple2.inc | apple2

	cc65 -O -t apple2 -o $@ $<
