# === TRS-80 Model 100 ===

# M100OPTION := default
M100OPTION := assembly
ifeq ($(TARGET),m100)
ifneq ($(OPTION),)
M100OPTION := $(OPTION)
endif
endif

M100DEPS := main.c m100/m100.lib m100/rf.lib m100/system.lib m100/inst.lib
M100LIBS := -lm100/m100 -lm100/rf -lm100/system -lm100/inst
M100ORG := 45000
M100ORIGIN := 0xC880
# POKE is to reset the RS232 interrupt handler; now load loader at 9600 baud, 8N1, XON/XOFF
M100PROMPT := $(PROMPT) 'On the target type POKE 62972,201 <enter> RUN "COM:88N1E" <enter>'
# -d 0.001 ensures any TX FIFO does not fill up faster than data transfer
# -o ixon is implemented in software and does not rely on termios flags / the UART
# This is to avoid overrunning the short buffer at the Model 100 end.
M100SEND := (cat && printf '\032')
M100SERIAL := $(ORTER) serial -d 0.001 -o ixon -o ixoff -o onlcrx -a $(SERIALPORT) $(SERIALBAUD)
M100LOADHEXLOADER := $(M100PROMPT) && $(INFO) 'Loading loader' ; $(M100SEND) < target/m100/hexloa.ba | $(M100SERIAL)
M100LOADLOADER := $(M100PROMPT) && $(INFO) 'Loading loader' ; $(M100SEND) < target/m100/loader.ba | $(M100SERIAL)
M100LOADFILE := $(M100LOADLOADER) && $(INFO) 'Loading file' && $(M100SERIAL) <

ifeq ($(M100OPTION),assembly)
	M100DEPS += m100/rf_8080.lib
	M100LIBS += -lm100/rf_8080
	M100ORIGIN := 0xBE80
endif

M100ZCCOPTS := \
	+m100 -subtype=default -m \
	-pragma-define:CLIB_EXIT_STACK_SIZE=0 \
	-pragma-define:CRT_ORG_CODE=$(M100ORG) \
	-DRF_ORG=$(M100ORG) \
	-DRF_ORIGIN=$(M100ORIGIN) \
	-Ca-DRF_ORIGIN=$(M100ORIGIN) \
	-Ca-DI8085

ifeq ($(M100OPTION),assembly)
	M100ZCCOPTS += -DRF_ASSEMBLY
endif

m100 :

	mkdir $@

.PHONY : m100-build
m100-build : m100/orterforth.ser

.PHONY : m100-hw
m100-hw : target/m100/loader.ba m100/hw.ser | $(ORTER)

	@$(M100LOADFILE) m100/hw.ser

.PHONY : m100-hw-hex
m100-hw-hex : target/m100/hexloa.ba m100/hw.ihx | $(ORTER)

	@$(M100LOADHEXLOADER)
	@$(INFO) 'Loading hex'
	@$(M100SEND) < m100/hw.ihx | $(M100SERIAL)

.PHONY : m100-load
m100-load : target/m100/loader.ba m100/orterforth.ser | $(ORTER)

	@$(M100LOADFILE) m100/orterforth.ser

.PHONY : m100-run
m100-run : m100-load disc

m100/%.ihx : m100/%.co

	z88dk-appmake +hex --binfile $< --org $$(( $(M100ORG) - 6 )) --output $@

m100/%.ser : m100/%.co | $(ORTER)

	$(ORTER) m100 serial write < $< > $@

m100/hw.co : hw.c | m100

	zcc $(M100ZCCOPTS) -create-app -m -o $@ $<

m100/inst.co : $(M100DEPS)

	zcc $(M100ZCCOPTS) $(M100LIBS) -create-app -m -o $@ $<

m100/inst.lib : inst.c inst.h rf.h target/m100/m100.inc | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<

m100/m100.lib : target/m100/m100.asm | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<

m100/orterforth.bin : m100/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

m100/orterforth.co : m100/orterforth.bin | $(ORTER)

	$(ORTER) m100 co header $(M100ORG) $$($(STAT) $<) $(M100ORG) > $@.io
	cat $< >> $@.io
	mv $@.io $@

m100/orterforth.hex : target/m100/loader.ba m100/inst.ser m100/inst.co model.img | $(ORTER) $(DISC)

	@# 6 byte header does not matter
	@$(CHECKMEMORY) $(M100ORG) $(M100ORIGIN) $$($(STAT) m100/inst.co)
	@$(M100LOADFILE) m100/inst.ser
	@$(EMPTYDR1FILE) $@.io
	@$(STARTDISC) serial $(SERIALPORT) $(SERIALBAUD) model.img $@.io
	@$(WAITUNTILSAVED) $@.io
	@$(STOPDISC)
	@$(COMPLETEDR1FILE)

m100/rf.lib : rf.c rf.h target/m100/m100.inc | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<

m100/rf_8080.lib : rf_8080.asm | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<

m100/system.lib : target/m100/system.c rf.h target/m100/m100.inc | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<
