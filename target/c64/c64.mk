# === Commodore 64 ===

C64CC65OPTS := -O -t c64

C64DEPS := c64/main.o c64/rf.o c64/inst.o c64/system.o c64/c64-up2400.o
# C64OPTION := assembly
C64OPTION := default
ifeq ($(TARGET),c64)
ifneq ($(OPTION),)
C64OPTION := $(OPTION)
endif
endif
C64ORIGIN := 0x2300

C64VICEOPTS := \
	-kernal roms/c64p/901227-02.u4 \
	-basic roms/c64p/901226-01.u3 \
	-chargen roms/c64p/901225-01.u5 \
	+saveres +confirmonexit

ifeq ($(C64OPTION),assembly)
C64CC65OPTS += -DRF_ASSEMBLY
C64DEPS += c64/rf_6502.o
C64ORIGIN := 0x1700
endif

C64CC65OPTS += -DRF_ORIGIN='$(C64ORIGIN)'

c64 :

	mkdir $@

.PHONY : c64-build
c64-build : c64/inst

.PHONY : vice
vice :

	x64 $(C64VICEOPTS) +warp

.PHONY : c64-hw
c64-hw : c64/hw.prg

	x64 $(C64VICEOPTS) +warp -autostartprgmode 1 -autostart $<

.PHONY : c64-run
c64-run : c64/orterforth.prg $(DR0) $(DR1)

	@$(START) disc.pid $(DISC) tcp 25232 $(DR0) $(DR1)

	@x64 $(C64VICEOPTS) +warp \
		-userportdevice 2 -rsuserdev 2 -rsuserbaud 2400 -rsdev3baud 2400 \
		-autostartprgmode 1 -autostart $<

# general assemble rule
c64/%.o : c64/%.s

	ca65 -t c64 -o $@ $<

# serial driver
c64/c64-up2400.s : tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.ser

	co65 --code-label _c64_serial -o $@ $<
  
# Hello World
c64/hw.prg : hw.c | c64

	cl65 -O -t c64 -o $@ $^

# inst binary
c64/inst.prg : $(C64DEPS) | c64

	cl65 -O -t c64 -C target/c64/c64.cfg -o $@ -m c64/inst.map $^

c64/inst.s : inst.c inst.h rf.h target/c64/c64.inc | c64

	cc65 $(C64CC65OPTS) \
		--bss-name INST \
		--code-name INST \
		--data-name INST \
		--rodata-name INST \
		-o $@ $<

c64/main.s : main.c inst.h rf.h target/c64/c64.inc | c64

	cc65 $(C64CC65OPTS) -o $@ $<

c64/orterforth : c64/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@.io
	mv $@.io $@

c64/orterforth.hex : c64/inst.prg model.img | $(DISC)

	@$(CHECKMEMORY) 0x801 $(C64ORIGIN) $$(( 0x$$(echo "$$(grep '^BSS' c64/inst.map)" | cut -c '33-36') - 0x801 ))

	@$(EMPTYDR1FILE) $@.io

	@$(INFO) 'Starting disc'
	@$(START) disc.pid $(DISC) tcp 25232 model.img $@.io

	@$(INFO) 'Starting Vice'
	@$(START) vice.pid x64 $(C64VICEOPTS) -warp \
		-userportdevice 2 -rsuserdev 2 -rsuserbaud 2400 -rsdev3baud 2400 \
		-autostartprgmode 1 -autostart $<

	@$(WAITUNTILSAVED) $@.io

	@$(INFO) 'Stopping Vice'
	@sh scripts/stop.sh vice.pid

	@$(STOPDISC)

	@$(COMPLETEDR1FILE)

c64/orterforth.prg : c64/orterforth

	printf '\001\010' > $@.io
	cat $< >> $@.io
	mv $@.io $@

c64/rf.s : rf.c rf.h target/c64/c64.inc | c64

	cc65 $(C64CC65OPTS) -o $@ $<

c64/rf_6502.o : rf_6502.s | c64

	ca65 -DORIG='$(C64ORIGIN)' -DTOS=\$$60 -o $@ $<

c64/system.s : target/c64/system.c rf.h target/c64/c64.inc | c64

	cc65 $(C64CC65OPTS) -o $@ $<

# c64/system.o : target/c64/system.s

# 	ca65 -t c64 -o $@ $<

# Johan's serial driver
tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.s :

	git submodule update --init tools/github.com/nanoflite/c64-up2400-cc65

tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.ser : tools/github.com/nanoflite/c64-up2400-cc65/driver/c64-up2400.s

	cd tools/github.com/nanoflite/c64-up2400-cc65 && make
