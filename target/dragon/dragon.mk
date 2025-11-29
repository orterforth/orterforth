# === Dragon 32/64 ===

# real or emulator
# DRAGONMACHINE := mame
DRAGONMACHINE := real
# DRAGONMACHINE := xroar
# 32 or 64
DRAGONMODEL=dragon32
# DRAGONMODEL=dragon64
# C or 6809 assembly option
DRAGONOPTION := assembly
# DRAGONOPTION := default
ifeq ($(TARGET),dragon)
ifneq ($(OPTION),)
DRAGONOPTION := $(OPTION)
endif
endif

DRAGONCMOCOPTS := --dragon -Werror -i
DRAGONDEPS := dragon/inst.o dragon/origin.o
DRAGONINSTMEDIA := dragon/inst.cas
DRAGONLINKDEPS := dragon/link.o dragon/origin.o
DRAGONMEDIA := dragon/orterforth.cas
DRAGONORG := 0x0600

ifeq ($(DRAGONMODEL),dragon32)
DRAGONACIA=0xFF68 # use CoCo Deluxe RS-232 Program Pak
DRAGONROMS := roms/dragon32/d32.rom
DRAGONXROAROPTS := -machine-arch dragon32 -rompath roms/dragon32
endif
ifeq ($(DRAGONMODEL),dragon64)
DRAGONACIA=0xFF04 # use Dragon 64 RS-232
DRAGONROMS := roms/dragon64/d64_1.rom roms/dragon64/d64_2.rom
DRAGONXROAROPTS := -machine-arch dragon64 -rompath roms/dragon64
endif

ifeq ($(DRAGONOPTION),assembly)
DRAGONDEPS += dragon/rf_6809.o dragon/system_asm.o
DRAGONLINKDEPS += dragon/rf_6809.o dragon/system_asm.o
else
DRAGONDEPS += dragon/io.o dragon/rf.o dragon/system.o
DRAGONLINKDEPS += dragon/io.o dragon/rf.o dragon/system.o
endif

DRAGONCMOCOPTS += -DRF_ORG=$(DRAGONORG)
DRAGONOFFSET := 0000
# For graphics pages 1-4
# DRAGONOFFSET := 1800

ifeq ($(DRAGONMACHINE),mame)
	DRAGONMAMEWARNINGS := \
		$(WARN) 'NB ORG must be 0x0C00 to allow for DragonDOS' ; \
		$(WARN) 'NB MAME Dragon serial not working'
	DRAGONSTARTDISC := $(STARTDISCTCP)
	DRAGONSTARTMACHINE := \
		$(INFO) 'Starting MAME' ; \
		$(DRAGONMAMEWARNINGS) ; \
		mame $(DRAGONMODEL) $(MAMEOPTS) \
			-rs232 null_modem -bitb socket.localhost:5705 \
			-autoboot_delay 4 -autoboot_command "CLOADM:EXEC\r" \
			-cassette
	DRAGONSTOPMACHINE = $(STOPMACHINE)
endif
ifeq ($(DRAGONMACHINE),real)
	DRAGONMEDIA := dragon/orterforth.wav
	DRAGONINSTMEDIA := dragon/inst.wav
	DRAGONSTARTDISC := $(STARTDISC) serial $(SERIALPORT) 1200
	DRAGONSTARTMACHINE := \
		$(PROMPT) "On the Dragon type: CLOADM:EXEC" && \
		$(PLAY)
	DRAGONSTOPMACHINE := :
endif
ifeq ($(DRAGONMACHINE),xroar)
	DRAGONSTARTDISC := $(INFO) 'Starting disc' ; sh scripts/start.sh dragon/tx dragon/rx disc.pid $(DISC)
	DRAGONSTARTMACHINE := \
		$(INFO) 'Starting XRoar' ; \
		$(WARN) 'NB XRoar must be modified to implement serial' ; \
		$(START) dragon/machine.pid xroar $(DRAGONXROAROPTS) -type "CLOADM:EXEC\r" -load-tape
	DRAGONSTOPMACHINE := \
		$(INFO) 'Stopping XRoar' ; \
		sh scripts/stop.sh dragon/machine.pid
endif

.PHONY : cmoc
cmoc :

	@$(REQUIRETOOL)

dragon :

	mkdir $@

.PHONY : dragon-build
dragon-build : dragon/inst.bin

.PHONY : dragon-hw
dragon-hw : dragon/hw.cas | $(DRAGONROMS)

ifeq ($(DRAGONMACHINE),mame)
	mame dragon64 $(MAMEOPTS) -cassette $< \
		-autoboot_delay 4 -autoboot_command "CLOADM:EXEC\r"
endif
ifeq ($(DRAGONMACHINE),xroar)
	xroar $(DRAGONXROAROPTS) -load-tape $< -type "CLOADM:EXEC\r"
endif

.PHONY : dragon-inst
dragon-inst : $(DRAGONMEDIA)

.PHONY : dragon-run
dragon-run : $(DRAGONMEDIA) | $(DISC) $(DR0) $(DR1) dragon/rx dragon/tx $(DRAGONROMS)

ifeq ($(DRAGONMACHINE),mame)
	@$(DRAGONSTARTDISC) $(DR0) $(DR1)
	@$(INFO) 'Running MAME'
	@$(DRAGONMAMEWARNINGS)
	@mame dragon64 $(MAMEOPTS) \
		-rs232 null_modem -bitb socket.localhost:5705 \
		-cassette $< \
		-autoboot_delay 4 -autoboot_command "CLOADM:EXEC\r"
endif
ifeq ($(DRAGONMACHINE),real)
	@$(DRAGONSTARTMACHINE) $<
	@$(DRAGONSTARTDISC) $(DR0) $(DR1)
	@$(PROMPT) "To stop disc press a key"
endif
ifeq ($(DRAGONMACHINE),xroar)
	@$(DRAGONSTARTDISC) $(DR0) $(DR1)
	@$(INFO) 'Running XRoar'
	@$(WARN) 'NB XRoar must be modified to implement serial'
	@xroar $(DRAGONXROAROPTS) -load-tape $< -type "CLOADM \"\",&H$(DRAGONOFFSET):EXEC\r"
endif

	@$(STOPDISC)

dragon/%.cas : dragon/%.bin | tools/www.6809.org.uk/dragon/bin2cas.pl

	tools/www.6809.org.uk/dragon/bin2cas.pl --output $@ -D $<

dragon/%.o : %.c rf.h target/dragon/dragon.inc | cmoc dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/%.wav : dragon/%.bin | tools/www.6809.org.uk/dragon/bin2cas.pl

	tools/www.6809.org.uk/dragon/bin2cas.pl --output $@ -D $<

dragon/hw.bin : hw.c | cmoc

	cmoc --dragon -i -o $@ $^

dragon/inst.bin : $(DRAGONDEPS) main.c | cmoc

	cmoc $(DRAGONCMOCOPTS) --org=$(DRAGONORG) --limit=0x7800 --stack-space=64 -nodefaultlibs -o $@ $^

dragon/installed.bin : dragon/installed.img | $(ORTER)

	$(ORTER) hex read < $< > $@

dragon/installed.img : $(DRAGONINSTMEDIA) model.img | $(DISC) dragon/rx dragon/tx $(DRAGONROMS)

	@$(EMPTYDR1FILE) $@.io
	@$(DRAGONSTARTDISC) model.img $@.io
	@$(DRAGONSTARTMACHINE) $<
	@$(WAITUNTILSAVED) $@.io
	@$(DRAGONSTOPMACHINE)
	@$(STOPDISC)
	@$(COMPLETEDR1FILE)

dragon/link.bin : $(DRAGONLINKDEPS) main.c | cmoc

	cmoc $(DRAGONCMOCOPTS) --org=$(DRAGONORG) --limit=0x7800 --stack-space=64 -nodefaultlibs -o $@ $^

dragon/origin.o : target/dragon/origin.s | cmoc dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/orterforth : dragon/link.bin dragon/link.map dragon/installed.bin

	dd bs=1 skip=9 if=dragon/link.bin > $@
	dd if=/dev/zero bs=1 count=$$(( 0x$$(grep '^Symbol: program_end ' dragon/link.map | cut -c '32-35') - 0x$$(grep '^Symbol: program_start ' dragon/link.map | cut -c '34-37') - $$($(STAT) dragon/link.bin) + 9)) >> $@
	cat dragon/installed.bin >> $@

dragon/orterforth.bin : dragon/orterforth

	$(ORTER) dragon bin header 2 $(DRAGONORG) $$($(STAT) $<) $(DRAGONORG) > $@
	cat $< >> $@

dragon/rf_6809.o : rf_6809.s | dragon lwasm

	lwasm --6809 --obj -o $@ $<

dragon/rx : | dragon

	mkfifo $@

dragon/system.o : target/dragon/system.c rf.h target/dragon/dragon.inc | cmoc dragon

	cmoc $(DRAGONCMOCOPTS) -DACIA=$(DRAGONACIA) -c -o $@ $<

dragon/system_asm.o : target/dragon/system.s | dragon lwasm

	lwasm --6809 --obj -DACIA=$(DRAGONACIA) -o $@ $<

dragon/tx : | dragon

	mkfifo $@

.PHONY : lwasm
lwasm :

	@$(REQUIRETOOL)

tools/sarrazip.com/dev/cmoc-0.1.90/configure : tools/sarrazip.com/dev/cmoc-0.1.90.tar.gz

	cd $(<D) && tar -xvf $(<F)

tools/sarrazip.com/dev/cmoc-0.1.90/Makefile : tools/sarrazip.com/dev/cmoc-0.1.90/configure

	cd $(<D) && ./configure

tools/sarrazip.com/dev/cmoc-0.1.90/src/cmoc : tools/sarrazip.com/dev/cmoc-0.1.90/Makefile

	cd $(<D) && make

tools/sarrazip.com/dev/cmoc-0.1.90-1.deb : | tools

	mkdir -p $(@D)
	curl -L --output $@ http://sarrazip.com/dev/cmoc-0.1.90-1.deb

tools/sarrazip.com/dev/cmoc-0.1.90.tar.gz : | tools

	mkdir -p $(@D)
	curl -L --output $@ http://sarrazip.com/dev/cmoc-0.1.90.tar.gz

tools/www.6809.org.uk/dragon/bin2cas.pl : | tools

	mkdir -p $(@D)
	curl --output $@ https://www.6809.org.uk/dragon/bin2cas.pl
	chmod +x $@

tools/www.lwtools.ca/releases/lwtools/lwtools-4.24.tar.gz : | tools

	mkdir -p $(@D)
	curl --output $@ http://www.lwtools.ca/releases/lwtools/lwtools-4.24.tar.gz

tools/www.lwtools.ca/releases/lwtools/lwtools-4.24/Makefile : tools/www.lwtools.ca/releases/lwtools/lwtools-4.24.tar.gz

	cd $(<D) && tar -xvf $(<F)

tools/www.lwtools.ca/releases/lwtools/lwtools-4.24/lwasm/lwasm : tools/www.lwtools.ca/releases/lwtools/lwtools-4.24/Makefile

	cd $(<D) && make

/usr/local/bin/lwasm /usr/local/bin/lwlink : tools/www.lwtools.ca/releases/lwtools/lwtools-4.24/lwasm/lwasm

	cd tools/www.lwtools.ca/releases/lwtools/lwtools-4.24 && make install

