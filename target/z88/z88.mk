# === Cambridge Z88 ===

# Z88OPTION := default
Z88OPTION := assembly
ifeq ($(TARGET),z88)
ifneq ($(OPTION),)
Z88OPTION := $(OPTION)
endif
endif

Z88DEPS := z88/inst.lib z88/system.lib main.c
Z88IMPEXPORT := \
	$(PROMPT) "On the Z88 go to: Imp-Export and R)eceive file" && \
	$(INFO) "Importing file" && \
	$(ORTER) serial -e 15 $(SERIALPORT) $(SERIALBAUD) <
Z88LIBS := -lm -lz88/inst -lz88/system
# PAGE
Z88ORG := 0x2300
Z88ORIGIN := 0x3E00

ifeq ($(Z88OPTION),assembly)
	Z88DEPS += z88/rf_z80.lib
	Z88LIBS += -lz88/rf_z80
	Z88ORIGIN := 0x3300
endif
ifeq ($(Z88OPTION),default)
	Z88DEPS += z88/rf.lib
	Z88LIBS += -lz88/rf
endif

Z88ZCCOPTS := +z88 \
	-DRF_ORG=$(Z88ORG) \
	-DRF_ORIGIN=$(Z88ORIGIN) \
	-Ca-DRF_ORIGIN=$(Z88ORIGIN) \
	-DRF_TARGET_INC='\"target/z88/system.inc\"'

ifeq ($(Z88OPTION),assembly)
	Z88ZCCOPTS += -DRF_ASSEMBLY
endif

z88 :

	mkdir $@

.PHONY : z88-hw
z88-hw : z88/hw.imp

	@$(Z88IMPEXPORT) $<
	@$(WARN) 'Now go to BBC Basic and RUN "hw"'

.PHONY : z88-install
z88-install : z88/orterforth.imp

	@$(Z88IMPEXPORT) $<
	@$(WARN) 'Now go to BBC Basic and RUN "orterforth"'

z88/%.imp : z88/%.bin

	$(ORTER) z88 imp-export write $(*F) < $< > $@.io
	mv $@.io $@

z88/hw.bin : hw.c | z88

	zcc $(Z88ZCCOPTS) -o $@ $<

z88/inst.bin z88/inst.map : $(Z88DEPS)

	zcc $(Z88ZCCOPTS) $(Z88LIBS) -m -o z88/inst.bin main.c

z88/inst.lib : inst.c rf.h | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<

z88/orterforth.bin : z88/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

z88/orterforth.hex : z88/inst.imp z88/inst.bin model.img

	@$(CHECKMEMORY) $(Z88ORG) $(Z88ORIGIN) $$($(STAT) z88/inst.bin)
	@$(Z88IMPEXPORT) $<
	@$(WARN) 'Now go to BBC Basic and RUN "inst"'
	@$(EMPTYDR1FILE) $@.io
	@$(STARTDISC) serial $(SERIALPORT) $(SERIALBAUD) model.img $@.io
	@$(WAITUNTILSAVED) $@.io
	@$(STOPDISC)
	@$(COMPLETEDR1FILE)

z88/rf.lib : rf.c rf.h target/z88/system.inc | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<

z88/rf_z80.lib : rf_z80.asm | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<

z88/system.lib : target/z88/system.c rf.h | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<
