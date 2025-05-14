HX20FCC := PATH=/opt/fcc/bin:$$PATH fcc -m6800 -DHX20

hx20 :

	mkdir $@

hx20/hw : hx20/hx20.o hx20/hw.o

	$(HX20FCC) -o $@ $^

hx20/hw.o : hw.c | hx20

	$(HX20FCC) -c -o $@ $<

hx20/hx20.o : target/hx20/hx20.s

	$(HX20FCC) -c -o $@ $<

hx20/inst : hx20/hx20.o hx20/inst.o hx20/io.o hx20/main.o hx20/rf.o hx20/system.o

	$(HX20FCC) -o $@ $^

hx20/inst.o : inst.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

hx20/io.o : io.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

hx20/main.o : main.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

hx20/rf.o : rf.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

hx20/system.o : target/hx20/system.c | hx20

	$(HX20FCC) -c -o $@ $<

tools/github.com/EtchedPixels/Fuzix-Bintools :

	git submodule update --init $@
	cd $@ && make clean install

tools/github.com/EtchedPixels/Fuzix-Compiler-Kit :

	git submodule update --init $@
	cd $@ && make clean bootstuff && PATH=/opt/fcc/bin:$$PATH make install
