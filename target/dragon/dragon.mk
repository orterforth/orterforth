# === Dragon 32/64 ===

# relink code compiled without inst at final location
# DRAGONLINK := false
DRAGONLINK := true

# real or emulator
# DRAGONMACHINE := mame
# DRAGONMACHINE := real
DRAGONMACHINE := xroar

# C or 6809 assembly option
DRAGONOPTION := assembly
# DRAGONOPTION := default
ifeq ($(TARGET),dragon)
ifneq ($(OPTION),)
DRAGONOPTION := $(OPTION)
endif
endif

DRAGONCMOCOPTS := --dragon -Werror
DRAGONDEPS := dragon/inst.o
DRAGONINSTMEDIA := dragon/inst.cas
DRAGONLINKDEPS := dragon/link.o
DRAGONMEDIA := dragon/orterforth.cas
DRAGONORG := 0x0600
ifeq ($(DRAGONLINK),true)
DRAGONORIGIN := 0x1D00
DRAGONPARTS := dragon/link dragon/spacer dragon/installed
else
DRAGONORIGIN := 0x3180
DRAGONPARTS := dragon/installed
endif
DRAGONROMS := roms/dragon64/d64_1.rom roms/dragon64/d64_2.rom
DRAGONXROAROPTS := -machine-arch dragon64 -rompath roms/dragon64

ifeq ($(DRAGONOPTION),assembly)
DRAGONCMOCOPTS += -DRF_ASSEMBLY
DRAGONDEPS += dragon/rf_6809.o dragon/system_asm.o
DRAGONLINKDEPS += dragon/rf_6809.o dragon/system_asm.o
ifeq ($(DRAGONLINK),true)
DRAGONORIGIN := 0x0F00
else
DRAGONORIGIN := 0x1A00
endif
else
DRAGONDEPS += dragon/io.o dragon/rf.o dragon/system.o
DRAGONLINKDEPS += dragon/io.o dragon/rf.o dragon/system.o
endif

DRAGONCMOCOPTS += -DRF_ORG=$(DRAGONORG) -DRF_ORIGIN=$(DRAGONORIGIN)
ifeq ($(DRAGONLINK),true)
	DRAGONCMOCOPTS += -DRF_INST_LINK
endif

ifeq ($(DRAGONMACHINE),mame)
	DRAGONMAMEWARNINGS := \
		$(WARN) 'NB ORG must be 0x0C00 to allow for DragonDOS' ; \
		$(WARN) 'NB MAME Dragon serial not working'
	DRAGONSTARTDISC := $(STARTDISCTCP)
	DRAGONSTARTMACHINE := \
		$(INFO) 'Starting MAME' ; \
		$(DRAGONMAMEWARNINGS) ; \
		mame dragon64 $(MAMEOPTS) \
			-rs232 null_modem -bitb socket.localhost:5705 \
			-autoboot_delay 4 -autoboot_command "CLOADM:EXEC\r" \
			-cassette
	DRAGONSTOPMACHINE := $(STOPMAME)
endif
ifeq ($(DRAGONMACHINE),real)
	DRAGONMEDIA := dragon/orterforth.wav
	DRAGONINSTMEDIA := dragon/inst.wav
	DRAGONSTARTDISC := $(STARTDISC) serial $(SERIALPORT) $(SERIALBAUD)
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
		$(START) xroar.pid xroar $(DRAGONXROAROPTS) -type "CLOADM:EXEC\r" -load-tape
	DRAGONSTOPMACHINE := \
		$(INFO) 'Stopping XRoar' ; \
		sh scripts/stop.sh xroar.pid
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

	@$(DRAGONSTARTDISC) $(DR0) $(DR1)

ifeq ($(DRAGONMACHINE),mame)
	@$(INFO) 'Running MAME'
	@$(DRAGONMAMEWARNINGS)
	@mame dragon64 $(MAMEOPTS) \
		-rs232 null_modem -bitb socket.localhost:5705 \
		-cassette $< \
		-autoboot_delay 4 -autoboot_command "CLOADM:EXEC\r"
endif
ifeq ($(DRAGONMACHINE),real)
	@$(DRAGONSTARTMACHINE) $<
	@$(PROMPT) "To stop disc press a key"
endif
ifeq ($(DRAGONMACHINE),xroar)
	@$(INFO) 'Running XRoar'
	@$(WARN) 'NB XRoar must be modified to implement serial'
	@xroar $(DRAGONXROAROPTS) -load-tape $< -type "CLOADM:EXEC\r"
endif

	@$(STOPDISC)

dragon/%.cas : dragon/%.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/%.o : %.c rf.h target/dragon/dragon.inc | cmoc dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/%.wav : dragon/%.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/hw.bin : hw.c | cmoc

	cmoc --dragon -o $@ $^

dragon/inst.bin : $(DRAGONDEPS) main.c | cmoc

ifeq ($(DRAGONLINK),true)
	cmoc $(DRAGONCMOCOPTS) --org=0x4c00 --limit=0x7800 --stack-space=64 -nodefaultlibs -o $@ $^
else
	cmoc $(DRAGONCMOCOPTS) --org=$(DRAGONORG) --limit=$(DRAGONORIGIN) --stack-space=64 -nodefaultlibs -o $@ $^
endif

dragon/installed : dragon/installed.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

dragon/installed.hex : $(DRAGONINSTMEDIA) model.img | $(DISC) dragon/rx dragon/tx $(DRAGONROMS)

ifneq ($(DRAGONLINK),true)
	@# 9 byte header included here although not necessary
	@$(CHECKMEMORY) $(DRAGONORG) $(DRAGONORIGIN) $$($(STAT) dragon/inst.bin)
endif
	@$(EMPTYDR1FILE) $@.io
	@$(DRAGONSTARTDISC) model.img $@.io
	@$(DRAGONSTARTMACHINE) $<
	@$(WAITUNTILSAVED) $@.io
	@$(DRAGONSTOPMACHINE)
	@$(STOPDISC)
	@$(COMPLETEDR1FILE)

dragon/link : dragon/link.bin

	# link bin, minus its own header
	dd bs=1 skip=9 if=dragon/link.bin > dragon/link

dragon/link.bin : $(DRAGONLINKDEPS) main.c | cmoc

	cmoc $(DRAGONCMOCOPTS) --org=$(DRAGONORG) --limit=$(DRAGONORIGIN) --stack-space=64 -nodefaultlibs -o $@ $^

dragon/orterforth : $(DRAGONPARTS)

	cat $^ > $@

dragon/orterforth.bin : dragon/orterforth

	$(ORTER) dragon bin header 2 $(DRAGONORG) $$($(STAT) $<) $(DRAGONORG) > $@
	cat $< >> $@

dragon/rf_6809.o : rf_6809.s | dragon lwasm

	lwasm --6809 --obj -DRF_ORIGIN=$(DRAGONORIGIN) -o $@ $<

dragon/rx : | dragon

	mkfifo $@

dragon/spacer : dragon/link

	$(CHECKMEMORY) $(DRAGONORG) $(DRAGONORIGIN) $$($(STAT) dragon/link)
	dd if=/dev/zero bs=1 count=$$(( $(DRAGONORIGIN) - $(DRAGONORG) - $$($(STAT) dragon/link) )) > $@

dragon/system.o : target/dragon/system.c rf.h target/dragon/dragon.inc | cmoc dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/system_asm.o : target/dragon/system.s | cmoc dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/tx : | dragon

	mkfifo $@

.PHONY : lwasm
lwasm :

	@$(REQUIRETOOL)

tools/bin2cas.pl : | tools

	curl --output $@ https://www.6809.org.uk/dragon/bin2cas.pl
	chmod +x $@
