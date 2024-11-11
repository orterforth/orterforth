HX20CC6303 := /opt/cc68/bin/cc68 -m6803 -c -DCC6303

.PHONY : hx20-hw
hx20-hw : hx20/hw

hx20 :

	mkdir $@

hx20/hw : hx20/hw.o

	/opt/cc68/bin/ld68 -b -C 0x0100 -o $@ /opt/cc68/lib/crt0.o $< /opt/cc68/lib/lib6803.a

hx20/hw.o : hw.c | hx20

	$(HX20CC6303) $<
	mv hw.o hx20/hw.o

hx20/inst : hx20/inst.o hx20/io.o hx20/main.o hx20/rf.o hx20/system.o

	/opt/cc68/bin/ld68 -b -C 0x0100 -o $@ /opt/cc68/lib/crt0.o $^ /opt/cc68/lib/lib6803.a

hx20/inst.o : inst.c rf.h target/hx20/hx20.inc | hx20

	$(HX20CC6303) $<
	mv inst.o hx20/inst.o

hx20/io.o : io.c rf.h target/hx20/hx20.inc | hx20

	$(HX20CC6303) $<
	mv io.o hx20/io.o

hx20/main.o : main.c rf.h target/hx20/hx20.inc | hx20

	$(HX20CC6303) $<
	mv main.o hx20/main.o

hx20/rf.o : rf.c rf.h target/hx20/hx20.inc | hx20

	$(HX20CC6303) $<
	mv rf.o hx20/rf.o

hx20/system.o : target/hx20/system.c | hx20

	$(HX20CC6303) $<
	mv target/hx20/system.o hx20/system.o
