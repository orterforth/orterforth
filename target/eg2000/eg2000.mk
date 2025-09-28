# === EACA EG2000 Colour Genie ===

# EG2000MACHINE=mame
EG2000MACHINE=real

eg2000-hw : eg2000/hw.wav

ifeq ($(EG2000MACHINE),mame)
	@$(START) eg2000/machine.pid mame cgenie $(MAMEOPTS) -cassette $<
	@$(WARN) "At MEM SIZE? type <enter> then SYSTEM <enter> HW <enter>"
	@$(WARN) "To enable UI controls press Forward Delete or Fn-Delete (macOS) / Scroll Lock (other OSs)"
	@$(WARN) "Then press F2 to start tape"
	@$(WARN) "When prompted type / <enter>"
endif
ifeq ($(EG2000MACHINE),real)
	@$(WARN) "Connect audio to Colour Genie cassette port with amplification if necessary"
	@$(PROMPT) "At MEM SIZE? type <enter> then SYSTEM <enter> HW <enter>"
	@$(INFO) "Loading HW"
	@$(PLAY) $<
	@$(WARN) "Now type / <enter>"
endif

eg2000/%.cas : eg2000/%.cmd | $(ORTER)

	$(ORTER) eg2000 cmd to cas HW < $< > $@.tmp
	mv $@.tmp $@

eg2000/%.wav : eg2000/%.cas | $(ORTER)

	$(ORTER) eg2000 cas to wav < $< > $@.tmp
	mv $@.tmp $@

eg2000/hw eg2000/hw.cmd : hw.c

	[ -d eg2000 ] || mkdir -p eg2000
	zcc +trs80 -subtype=eg2000disk -lndos -lm -o eg2000/hw -create-app hw.c
