ATARIATARI800OPTS := -xl -pal -no-autosave-config -xlxe_rom roms/a800xlp/co61598b.rom -basic_rom roms/a800xlp/co60302a.rom 
ATARIDEPS := atari/inst.o atari/io.o atari/main.o atari/system.o
ATARIORG = 0x2000
ATARICC65OPTS = -O -t atari -DRF_ORG=$(ATARIORG) -DRF_ORIGIN=$(ATARIORIGIN) -DRF_TARGET_INC='"target/atari/atari.inc"'
# ATARIOPTION := assembly
ATARIOPTION := default
ifeq ($(TARGET),atari)
ifneq ($(OPTION),)
ATARIOPTION := $(OPTION)
endif
endif
ifeq ($(ATARIOPTION),assembly)
ATARICC65OPTS += -DRF_ASSEMBLY
ATARIDEPS += atari/rf_6502.o
ATARIORIGIN := 0x3E00
endif
ifeq ($(ATARIOPTION),default)
ATARIDEPS += atari/rf.o
ATARIORIGIN = 0x4A00
endif

atari :

	mkdir $@

.PHONY : atari-build
atari-build : atari/inst.xex

.PHONY : atari-hw
atari-hw : atari/hw.xex | atari800

	@atari800 $(ATARIATARI800OPTS) -run $<

.PHONY : atari-run
atari-run : atari/orterforth.xex | atari800 $(DR0) $(DR1)

	@rm -f atari/pty
	@$(STARTDISC) pty atari/pty $(DR0) $(DR1)
	@sleep 2
	@atari800 $(ATARIATARI800OPTS) -rdevice $$(readlink -n atari/pty && rm atari/pty) -run $<
	@$(STOPDISC)

.PHONY : atari800
atari800 :

	@$(REQUIRETOOL)

atari/%.o : atari/%.s

	ca65 -t atari -o $@ $<

atari/%.s : %.c rf.h target/atari/atari.inc | atari cc65

	cc65 $(ATARICC65OPTS) -o $@ $<

atari/hw.xex : hw.c | atari

	cl65 -O -t atari -C atari-xex.cfg -o $@ $^

atari/inst.xex atari/inst.map : $(ATARIDEPS) | atari

	cl65 -O -t atari -C atari-xex.cfg -o $@ -m atari/inst.map $^

atari/orterforth.bin : atari/orterforth.img | $(ORTER)

	$(ORTER) hex read < $< > $@

atari/orterforth.img : atari/inst.xex atari/inst.map model.img | atari800 $(DISC)

	@$(CHECKMEMORY) $(ATARIORG) $(ATARIORIGIN) $$(( 0x$$(echo "$$(grep '^BSS' atari/inst.map)" | cut -c '33-36') - $(ATARIORG) ))
	@$(EMPTYDR1FILE) $@.io
	@rm -f atari/pty
	@$(STARTDISC) pty atari/pty model.img $@.io
	@sleep 2
	@$(INFO) 'Starting Atari800'
	@$(START) atari/machine.pid atari800 $(ATARIATARI800OPTS) -turbo -rdevice $$(readlink -n atari/pty && rm atari/pty) -run $<
	@$(WAITUNTILSAVED) $@.io
	@$(INFO) 'Stopping Atari800'
	@sh scripts/stop.sh atari/machine.pid
	@$(STOPDISC)
	@$(COMPLETEDR1FILE)

atari/orterforth.xex : atari/orterforth.bin | $(ORTER)

	$(ORTER) atari xex write $(ATARIORG) $$(($(ATARIORG)+1)) < $< > $@

atari/rf_6502.o : rf_6502.s | c64

	ca65 -DORIG='$(ATARIORIGIN)' -DTOS=\$$E0 -o $@ $<

atari/system.s : target/atari/system.c | atari cc65

	cc65 $(ATARICC65OPTS) -o $@ $<
