# === Commodore 64 ===

C64VICEOPTS := \
	-kernal roms/c64p/901227-02.u4 -basic roms/c64p/901226-01.u3 -chargen roms/c64p/901225-01.u5 \
	+saveres +confirmonexit -userportdevice 2 -rsuserdev 2 -rsuserbaud 2400 -rsdev3baud 2400
C64DEPS := c64/inst.o c64/io.o c64/main.o c64/system.o c64/c64-up2400.o
C64ORG = 0x0801
C64CC65OPTS := -O -t c64
C64MEDIAEXT := prg
# C64MEDIAEXT := tap
C64UP2400 := tools/github.com/nanoflite/c64-up2400-cc65
# C64OPTION := assembly
C64OPTION := default
ifeq ($(TARGET),c64)
ifneq ($(OPTION),)
C64OPTION := $(OPTION)
endif
endif
ifeq ($(C64OPTION),assembly)
C64CC65OPTS += -DRF_ASSEMBLY
C64DEPS += c64/rf_6502.o
C64ORIGIN := 0x16C0
endif
ifeq ($(C64OPTION),default)
C64DEPS += c64/rf.o
C64ORIGIN := 0x2340
endif
C64CC65OPTS += -DRF_ORIGIN='$(C64ORIGIN)'

c64 :

	mkdir $@

.PHONY : c64-build
c64-build : c64/orterforth.prg

.PHONY : c64-hw
c64-hw : c64/hw.$(C64MEDIAEXT)

	@x64 $(C64VICEOPTS) +warp -autostartprgmode 1 -autostart $<

.PHONY : c64-run
c64-run : c64/orterforth.$(C64MEDIAEXT) $(DR0) $(DR1)

	@$(START) disc.pid $(DISC) tcp server 25232 $(DR0) $(DR1)
	@x64 $(C64VICEOPTS) +warp -autostartprgmode 1 -autostart $<

c64/%.o : c64/%.s

	ca65 -t c64 -o $@ $<

c64/%.s : %.c rf.h target/c64/c64.inc | c64 cc65

	cc65 $(C64CC65OPTS) -o $@ $<

c64/%.tap : c64/%.prg | tools/github.com/reidrac/mkc64tap/mkc64tap.py

	python2 tools/github.com/reidrac/mkc64tap/mkc64tap.py --output $@ $<

c64/c64-up2400.s : $(C64UP2400)/driver/c64-up2400.ser | c64

	co65 --code-label _c64_serial -o $@ $<
  
c64/hw.prg : hw.c | c64

	cl65 -O -t c64 -o $@ $^

c64/inst.prg : $(C64DEPS) | c64

	cl65 -O -t c64 -C target/c64/c64.cfg -o $@ -m c64/inst.map $^

c64/inst.s : inst.c rf.h target/c64/c64.inc | c64 cc65

	cc65 $(C64CC65OPTS) \
		--bss-name INST \
		--code-name INST \
		--data-name INST \
		--rodata-name INST \
		-o $@ $<

c64/orterforth : c64/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@.io
	mv $@.io $@

c64/orterforth.hex : c64/inst.$(C64MEDIAEXT) model.img | $(DISC)

	@$(CHECKMEMORY) 0x801 $(C64ORIGIN) $$(( 0x$$(echo "$$(grep '^BSS' c64/inst.map)" | cut -c '33-36') - 0x801 ))
	@$(EMPTYDR1FILE) $@.io
	@$(INFO) 'Starting disc'
	@$(START) disc.pid $(DISC) tcp server 25232 model.img $@.io
	@$(STARTMACHINE) x64 $(C64VICEOPTS) -warp -autostartprgmode 1 -autostart $<
	@$(WAITUNTILSAVED) $@.io
	@$(STOPMACHINE)
	@$(STOPDISC)
	@$(COMPLETEDR1FILE)

c64/orterforth.prg : c64/orterforth

	printf '\001\010' > $@.io
	cat $< >> $@.io
	mv $@.io $@

c64/rf_6502.o : rf_6502.s | c64

	ca65 -DORIG='$(C64ORIGIN)' -DTOS=\$$60 -o $@ $<

c64/system.o : target/c64/system.s | c64

	ca65 -o $@ $<

c64/system.s : target/c64/system.c rf.h target/c64/c64.inc | c64 cc65

	cc65 $(C64CC65OPTS) -o $@ $<

# Johan's serial driver
$(C64UP2400)/driver/c64-up2400.s :

	git submodule update --init $(C64UP2400)

$(C64UP2400)/driver/c64-up2400.ser : $(C64UP2400)/driver/c64-up2400.s

	cd $(C64UP2400) && make

tools/github.com/reidrac/mkc64tap/mkc64tap.py :

	git submodule update --init tools/github.com/reidrac/mkc64tap
