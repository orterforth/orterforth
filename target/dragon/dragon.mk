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
DRAGONMACHINE := xroar
DRAGONORG := 0x0600
DRAGONORIGIN := 0x3280
DRAGONROMS := roms/dragon64/d64_1.rom roms/dragon64/d64_2.rom
DRAGONXROAROPTS := -machine-arch dragon64 -rompath roms/dragon64

ifeq ($(DRAGONOPTION),assembly)
DRAGONCMOCOPTS += -DRF_ASSEMBLY
DRAGONDEPS += dragon/rf_6809.o
DRAGONORIGIN := 0x2780
endif

DRAGONCMOCOPTS += -DRF_ORG=$(DRAGONORG) -DRF_ORIGIN=$(DRAGONORIGIN)

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

ifeq ($(DRAGONMACHINE),mame)
	@$(STARTDISCTCP) $(DR0) $(DR1)
endif
ifeq ($(DRAGONMACHINE),xroar)
	@printf '* \033[1;33mStarting disc\033[0;0m\n'
	@sh scripts/start.sh dragon/tx dragon/rx disc.pid $(DISC) standard $(DR0) $(DR1)
endif

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

	cmoc $(DRAGONCMOCOPTS) --org=$(DRAGONORG) --limit=$(DRAGONORIGIN) --stack-space=256 -nodefaultlibs -o $@ $^

dragon/inst.cas : dragon/inst.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/inst.o : inst.c rf.h target/dragon/system.inc | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/inst.wav : dragon/inst.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/orterforth : dragon/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

dragon/orterforth.bin : dragon/orterforth

	sh target/dragon/bin-header.sh $(shell $(STAT) $<) > $@.io
	cat $< >> $@.io
	mv $@.io $@

dragon/orterforth.cas : dragon/orterforth.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/orterforth.hex : dragon/inst.cas model.disc | $(DISC) dragon/rx dragon/tx $(DRAGONROMS)

	@$(CHECKMEMORY) $(DRAGONORG) $(DRAGONORIGIN) $(shell $(STAT) dragon/inst.bin)

	@printf '* \033[1;33mClearing DR1\033[0;0m\n'
	@rm -f $@.io
	@touch $@.io

ifeq ($(DRAGONMACHINE),mame)
	@$(STARTDISCTCP) model.disc $@.io
endif
ifeq ($(DRAGONMACHINE),xroar)
	@printf '* \033[1;33mStarting disc\033[0;0m\n'
	@sh scripts/start.sh dragon/tx dragon/rx disc.pid $(DISC) standard model.disc $@.io
endif

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

dragon/orterforth.wav : dragon/orterforth.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D $<

dragon/rf.o : rf.c rf.h target/dragon/system.inc | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

dragon/rf_6809.o : rf_6809.s | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

# Dragon serial named pipe
dragon/rx : | dragon

	mkfifo $@

dragon/system.o : target/dragon/system.c rf.h target/dragon/system.inc | dragon

	cmoc $(DRAGONCMOCOPTS) -c -o $@ $<

# Dragon serial named pipe
dragon/tx : | dragon

	mkfifo $@
