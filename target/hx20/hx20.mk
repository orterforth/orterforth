# === Epson HX-20 ===

HX20FCC := PATH=/opt/fcc/bin:$$PATH fcc -m6800 -DHX20

hx20 :

	mkdir $@

hx20/hw : hx20/hx20.o hx20/hw.o

	$(HX20FCC) -T0x0A40 -o $@ $^

hx20/hw.bin : hx20/hw | $(ORTER)

	$(ORTER) hx20 bin write 0x0A40 0x0A40 < $< > $@

hx20/hw.o : hw.c | hx20

	$(HX20FCC) -c -o $@ $<

hx20/hw.wav : hx20/hw.bin | $(ORTER)

	$(ORTER) hx20 wav write HW < $< > $@

hx20/hx20.o : target/hx20/hx20.s

	$(HX20FCC) -c -o $@ $<

hx20/inst : hx20/hx20.o hx20/inst.o hx20/io.o hx20/main.o hx20/rf.o hx20/system.o

	$(HX20FCC) -T0x0A40 -o $@ $^

hx20/inst.o : inst.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

hx20/io.o : io.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

hx20/main.o : main.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

hx20/rf.o : rf.c rf.h target/hx20/hx20.inc | hx20

	$(HX20FCC) -c -o $@ $<

# NB to load - use monitor commands
# A (T) 0A40 (L) 3FFF (O) 0000 (E) 0A40 /
# R C,*.*
# D 0A40
# G 0A40

hx20/rts :

	printf "\071" > $@

hx20/rts.bin : hx20/rts | $(ORTER)

	$(ORTER) hx20 bin write 0x0A40 0x0A40 < $< > $@

hx20/rts.wav : hx20/rts.bin | $(ORTER)

	$(ORTER) hx20 wav write RTS < $< > $@

hx20/system.o : target/hx20/system.c | hx20

	$(HX20FCC) -c -o $@ $<

tools/github.com/EtchedPixels/Fuzix-Bintools :

	git submodule update --init $@
	cd $@ && make clean install

tools/github.com/EtchedPixels/Fuzix-Compiler-Kit :

	git submodule update --init $@
	cd $@ && make clean bootstuff && PATH=/opt/fcc/bin:$$PATH make install
