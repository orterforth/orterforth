# === Commodore 64 ===

C64ORIGIN := 0x3300

c64 :

	mkdir $@

.PHONY : c64-build
c64-build : c64/inst

.PHONY : c64-clean
c64-clean :

	rm -rf c64/*

.PHONY : vice
vice :

	x64 \
		-kernal roms/c64p/901227-02.u4 \
		-basic roms/c64p/901226-01.u3 \
		-chargen roms/c64p/901225-01.u5 \
		+warp +saveres +confirmonexit

.PHONY : c64-hw
c64-hw : c64/hw.prg

	x64 \
		-kernal roms/c64p/901227-02.u4 \
		-basic roms/c64p/901226-01.u3 \
		-chargen roms/c64p/901225-01.u5 \
		+warp +saveres +confirmonexit -autostartprgmode 1 -autostart $<

# TODO cfg file with sections for inst
.PHONY : c64-run
c64-run : c64/orterforth.prg

	# x64 \
	# 	-kernal roms/c64p/901227-02.u4 \
	# 	-basic roms/c64p/901226-01.u3 \
	# 	-chargen roms/c64p/901225-01.u5 \
	# 	+warp +saveres +confirmonexit \
	# 	-userportdevice 2 -rsuserdev 2 -rsuserbaud 2400 -rsdev3baud 2400 \
	# 	-autostartprgmode 1 -autostart $<

# general assemble rule
c64/%.o : c64/%.s

	ca65 -t c64 -o $@ $<

# serial driver
# TODO diagnose issue with driver built from source
#c64/c64-up2400.s : tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.ser
c64/c64-up2400.s : target/c64/c64-up2400.ser

	co65 --code-label _c64_serial -o $@ $<
  
# Hello World
c64/hw.prg : hw.c | c64

	cl65 -O -t c64 -o $@ $^

# inst binary
c64/inst.prg : c64/main.o c64/rf.o c64/inst.o c64/system.o c64/c64-up2400.o | c64

	cl65 -O -t c64 -o $@ -m c64/inst.map $^

c64/inst.s : inst.c inst.h rf.h target/c64/c64.inc | c64

	cc65 -O -t c64 -DRF_ORIGIN=$(C64ORIGIN) -o $@ $<

c64/main.s : main.c inst.h rf.h target/c64/c64.inc | c64

	cc65 -O -t c64 -DRF_ORIGIN=$(C64ORIGIN) -o $@ $<

c64/orterforth : c64/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@.io
	mv $@.io $@

c64/orterforth.hex : c64/inst.prg model.img | $(DISC)

	@$(CHECKMEMORY) 0x801 $(C64ORIGIN) $(shell $(STAT) c64/inst.prg)

	rm -f $@.io
	touch $@.io

	$(START) disc.pid $(DISC) tcp 25232 model.img $@.io

	$(START) vice.pid x64 \
		-kernal roms/c64p/901227-02.u4 \
		-basic roms/c64p/901226-01.u3 \
		-chargen roms/c64p/901225-01.u5 \
		-warp +saveres +confirmonexit \
		-userportdevice 2 -rsuserdev 2 -rsuserbaud 2400 -rsdev3baud 2400 \
		-autostartprgmode 1 -autostart $<

	@$(WAITUNTILSAVED) $@.io

#	@printf '* \033[1;33mStopping Vice\033[0;0m\n'
#	@sh scripts/stop.sh vice.pid

#	$(STOPDISC)

#	mv $@.io $@

c64/orterforth.prg : c64/orterforth

	printf '\001\010' > $@.io
	cat $< >> $@.io
	mv $@.io $@

c64/rf.s : rf.c rf.h target/c64/c64.inc | c64

	cc65 -O -t c64 -DRF_ORIGIN=$(C64ORIGIN) -o $@ $<

c64/system.s : target/c64/system.c rf.h target/c64/c64.inc | c64

	cc65 -O -t c64 -o $@ $<

# Johan's serial driver
tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.s :

	git submodule update --init tools/github.com/nanoflite/c64-up2400-cc65

tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.ser : tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.s

	cd tools/github.com/nanoflite/c64-up2400-cc65 && make
