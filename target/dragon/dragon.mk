# === Dragon 32/64 ===

dragon :

	mkdir $@

.PHONY : dragon-build
dragon-build : dragon/inst.bin

.PHONY : dragon-clean
dragon-clean :

	rm -f dragon/*

DRAGONOPTION := assembly
# DRAGONOPTION := default

DRAGONCMOCOPTS := --dragon
DRAGONDEPS := dragon/rf.o dragon/inst.o dragon/system.o
DRAGONLINK := true
DRAGONLINKDEPS := dragon/link.o dragon/rf.o dragon/system.o
DRAGONMACHINE := xroar
DRAGONORG := 0x0600
ifeq ($(DRAGONLINK),true)
DRAGONORIGIN := 0x1D00
else
DRAGONORIGIN := 0x3180
endif
DRAGONROMS := roms/dragon64/d64_1.rom roms/dragon64/d64_2.rom
DRAGONXROAROPTS := -machine-arch dragon64 -rompath roms/dragon64

ifeq ($(DRAGONOPTION),assembly)
DRAGONCMOCOPTS += -DRF_ASSEMBLY
DRAGONDEPS += dragon/rf_6809.o
DRAGONLINKDEPS += dragon/rf_6809.o
ifeq ($(DRAGONLINK),true)
DRAGONORIGIN := 0x11C0
else
DRAGONORIGIN := 0x2640
endif
endif

DRAGONCMOCOPTS += -DRF_ORG=$(DRAGONORG) -DRF_ORIGIN=$(DRAGONORIGIN)

ifeq ($(DRAGONLINK),true)
	DRAGONCMOCOPTS += -DRF_INST_LINK
endif

ifeq ($(DRAGONMACHINE),mame)
	DRAGONSTARTDISC := $(STARTDISCTCP)
endif
ifeq ($(DRAGONMACHINE),xroar)
	DRAGONSTARTDISC := printf '* \033[1;33mStarting disc\033[0;0m\n' ; sh scripts/start.sh dragon/tx dragon/rx disc.pid $(DISC) standard
endif

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
dragon-inst : dragon/orterforth.cas

.PHONY : dragon-run
dragon-run : dragon/orterforth.cas | $(DISC) dragon/rx dragon/tx $(DRAGONROMS)

	@$(DRAGONSTARTDISC) $(DR0) $(DR1)

ifeq ($(DRAGONMACHINE),mame)
	@printf '* \033[1;33mRunning MAME\033[0;0m\n'
	@printf '* \033[1;35mNB not currently 64 mode compatible\033[0;0m\n'
	@printf '* \033[1;35mNB MAME Dragon serial not working\033[0;0m\n'
	@mame dragon64 $(MAMEOPTS) \
		-rs232 null_modem -bitb socket.localhost:5705 \
		-cassette $< \
		-autoboot_delay 4 -autoboot_command "CLOADM:EXEC\r"
endif
ifeq ($(DRAGONMACHINE),xroar)
	@printf '* \033[1;33mRunning XRoar\033[0;0m\n'
	@printf '* \033[1;35mNB XRoar must be modified to implement serial\033[0;0m\n'
	@xroar $(DRAGONXROAROPTS) -load-tape $< -type "CLOADM:EXEC\r"
endif

	@$(STOPDISC)

dragon/hw.bin : hw.c

	cmoc --dragon -o $@ $^

dragon/hw.cas : dragon/hw.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/hw.wav : dragon/hw.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/inst.bin : $(DRAGONDEPS) main.c

ifeq ($(DRAGONLINK),true)
	cmoc $(DRAGONCMOCOPTS) --org=0x4c00 --limit=0x7800 --stack-space=64 -nodefaultlibs -o $@ $^
else
	cmoc $(DRAGONCMOCOPTS) --org=$(DRAGONORG) --limit=$(DRAGONORIGIN) --stack-space=64 -nodefaultlibs -o $@ $^
endif

dragon/inst.cas : dragon/inst.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/inst.o : inst.c rf.h target/dragon/system.inc | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/inst.wav : dragon/inst.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/installed : dragon/installed.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

dragon/installed.hex : dragon/inst.cas model.img | $(DISC) dragon/rx dragon/tx $(DRAGONROMS)

# TODO if link true, check memory for dragon/link instead (earlier)
# TODO should this operate on a headerless dragon/inst
ifneq ($(DRAGONLINK),true)
	@$(CHECKMEMORY) $(DRAGONORG) $(DRAGONORIGIN) $(shell $(STAT) dragon/inst.bin)
endif

	@printf '* \033[1;33mClearing DR1\033[0;0m\n'
	@rm -f $@.io
	@touch $@.io

	@$(DRAGONSTARTDISC) model.img $@.io

ifeq ($(DRAGONMACHINE),mame)
	@printf '* \033[1;33mStarting MAME\033[0;0m\n'
	@printf '* \033[1;35mNB not currently 64 mode compatible\033[0;0m\n'
	@printf '* \033[1;35mNB MAME Dragon serial not working\033[0;0m\n'
	@mame dragon64 $(MAMEOPTS) \
		-rs232 null_modem -bitb socket.localhost:5705 \
		-cassette $< \
		-autoboot_delay 4 -autoboot_command "CLOADM:EXEC\r"
endif
ifeq ($(DRAGONMACHINE),xroar)
	@printf '* \033[1;33mStarting XRoar\033[0;0m\n'
	@printf '* \033[1;35mNB XRoar must be modified to implement serial\033[0;0m\n'
	@sh scripts/start.sh \
		/dev/stdin \
		/dev/stdout \
		xroar.pid \
		xroar \
		$(DRAGONXROAROPTS) \
		-load-tape $< \
		-type "CLOADM:EXEC\r"
endif

	@$(WAITUNTILSAVED) $@.io

	@printf '* \033[1;33mStopping XRoar\033[0;0m\n'
	@sh scripts/stop.sh xroar.pid

	@$(STOPDISC)

	@printf '* \033[1;33mDone\033[0;0m\n'
	@mv $@.io $@

dragon/link : dragon/link.bin

	# link bin, minus its own header
	dd bs=1 skip=9 if=dragon/link.bin > dragon/link

dragon/link.bin : $(DRAGONLINKDEPS) main.c

	cmoc $(DRAGONCMOCOPTS) --org=$(DRAGONORG) --limit=$(DRAGONORIGIN) --stack-space=64 -nodefaultlibs -o $@ $^

dragon/link.o : link.c rf.h target/dragon/system.inc | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

ifeq ($(DRAGONLINK),true)
dragon/orterforth : dragon/link dragon/spacer dragon/installed

	cat dragon/link > $@.io
	cat dragon/spacer >> $@.io
else
dragon/orterforth : dragon/installed

endif
	cat dragon/installed >> $@.io
	mv $@.io $@

dragon/orterforth.bin : dragon/orterforth

	sh target/dragon/bin-header.sh $(shell $(STAT) $<) > $@
	cat $< >> $@

dragon/orterforth.cas : dragon/orterforth.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/orterforth.wav : dragon/orterforth.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/rf.o : rf.c rf.h target/dragon/system.inc | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/rf_6809.o : rf_6809.s | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/rx : | dragon

	mkfifo $@

dragon/spacer : dragon/link

	dd if=/dev/zero bs=1 count=$$(( $(DRAGONORIGIN) - $(DRAGONORG) - $(shell $(STAT) dragon/link) )) > $@

dragon/system.o : target/dragon/system.c rf.h target/dragon/system.inc | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/tx : | dragon

	mkfifo $@

roms/dragon64 : | roms

	mkdir $@

roms/dragon64/% :

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

tools/bin2cas.pl : | tools

	curl --output $@ https://www.6809.org.uk/dragon/bin2cas.pl
