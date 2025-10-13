# === EACA EG2000 Colour Genie ===

# EG2000MACHINE=mame
EG2000MACHINE=real
EG2000OPTION := assembly
# EG2000OPTION := default
ifeq ($(TARGET),EG2000)
ifneq ($(OPTION),)
EG2000OPTION := $(OPTION)
endif
endif

ifeq ($(EG2000OPTION),assembly)
	EG2000OBJ := rf_z80
	EG2000ORIGIN := 0x6A00
endif
ifeq ($(EG2000OPTION),default)
	EG2000OBJ := rf
	EG2000ORIGIN := 0x7600
endif

EG2000ZCCOPTS=+trs80 -subtype=eg2000disk -lndos -lm	-pragma-define:CRT_ENABLE_STDIO=0 -DRF_ORIGIN=$(EG2000ORIGIN) -Ca-DRF_ORIGIN=$(EG2000ORIGIN)

eg2000-hw : eg2000/hw.wav

ifeq ($(EG2000MACHINE),mame)
	@$(START) eg2000/machine.pid mame cgenie $(MAMEOPTS) -cassette $<
	@$(WARN) "At MEM SIZE? type <enter> then SYSTEM <enter> hw <enter>"
	@$(WARN) "To enable UI controls press $(MAMEUIMODEKEY)"
	@$(WARN) "Then press F2 to start tape"
	@$(WARN) "When prompted type / <enter>"
endif
ifeq ($(EG2000MACHINE),real)
	@$(WARN) "Connect audio to Colour Genie cassette port with amplification if necessary"
	@$(PROMPT) "At MEM SIZE? type <RETURN> then SYSTEM <RETURN> hw <RETURN>"
	@$(INFO) "Loading hw"
	@$(PLAY) $<
	@$(WARN) "Now type / <RETURN>"
endif

eg2000-run : eg2000/orterforth.wav | $(DISC) $(DR0) $(DR1)

	@$(WARN) "Connect audio to Colour Genie cassette port with amplification if necessary"
	@$(PROMPT) "At MEM SIZE? type <RETURN> then SYSTEM <RETURN> orterf <RETURN>"
	@$(INFO) "Loading orterf"
	@$(PLAY) $<
	@$(DISC) serial -n crtscts -w 0.10 $(SERIALPORT) 600 $(DR0) $(DR1)
	@$(WARN) "Now type / <RETURN>"

eg2000/orterforth : eg2000/orterforth.img | $(ORTER)

	$(ORTER) hex read < $< > $@.tmp
	mv $@.tmp $@

eg2000/orterforth.cmd : eg2000/orterforth | $(ORTER)

	$(ORTER) eg2000 bin to cmd 0x57E4 0x57E4 < $< > $@.tmp
	mv $@.tmp $@

eg2000/orterforth.img : eg2000/inst.wav model.img | $(DISC)

	@$(CHECKMEMORY) 0x57E4 $(EG2000ORIGIN) $$($(STAT) eg2000/inst)
	@$(WARN) "Connect audio to Colour Genie cassette port with amplification if necessary"
	@$(PROMPT) "At MEM SIZE? type <RETURN> then SYSTEM <RETURN> inst <RETURN>"
	@$(INFO) "Loading inst"
	@$(PLAY) $<
	@$(WARN) "Now type / <RETURN>"
	@$(INSTALLDISC) serial -n crtscts -w 0.10 $(SERIALPORT) 600 &
	@$(WAITFORFILE)

eg2000/%.lib : %.c rf.h target/eg2000/eg2000.inc

	[ -d eg2000 ] || mkdir -p eg2000
	zcc $(EG2000ZCCOPTS) -x -o $@ $<

eg2000/%.cas : eg2000/%.cmd | $(ORTER)

	$(ORTER) eg2000 cmd to cas $(*F) < $< > $@.tmp
	mv $@.tmp $@

eg2000/%.wav : eg2000/%.cas | $(ORTER)

	$(ORTER) eg2000 cas to wav < $< > $@.tmp
	mv $@.tmp $@

eg2000/hw eg2000/hw.cmd : hw.c

	[ -d eg2000 ] || mkdir -p eg2000
	zcc +trs80 -subtype=eg2000disk -lndos -lm -o eg2000/hw -create-app hw.c

eg2000/inst eg2000/inst.cmd eg2000/inst.map : eg2000/inst.lib eg2000/io.lib eg2000/$(EG2000OBJ).lib eg2000/system.lib main.c

	zcc $(EG2000ZCCOPTS) -leg2000/inst -leg2000/io -leg2000/$(EG2000OBJ) -leg2000/system -m -o eg2000/inst -create-app main.c

eg2000/rf_z80.lib : rf_z80.asm

	[ -d eg2000 ] || mkdir -p eg2000
	zcc $(EG2000ZCCOPTS) -x -o $@ $<

eg2000/system.lib : target/eg2000/system.asm

	[ -d eg2000 ] || mkdir -p eg2000
	zcc $(EG2000ZCCOPTS) -x -o $@ $<
