.PHONY : hx20-hw
hx20-hw : hx20/hw

hx20 :

	mkdir $@

hx20/hw : hx20/hw.o

	/opt/cc68/bin/ld68 -b -C 0x0100 -o $@ /opt/cc68/lib/crt0.o $< /opt/cc68/lib/lib6803.a

hx20/hw.o : hw.c | hx20

	/opt/cc68/bin/cc68 -m6803 -c -DCC6303 $<
	mv hw.o hx20/hw.o
