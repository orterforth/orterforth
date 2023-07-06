# === RC2014 ===

RC2014DEPS := \
	rc2014/inst.lib \
	rc2014/mux.lib \
	rc2014/rf.lib \
	rc2014/system.lib
RC2014HEXLOAD := rc2014/hexload-ack.bas
RC2014INSTOFFSET := 0x5000
RC2014LIBS := \
	-lrc2014/mux \
	-lrc2014/inst \
	-lrc2014/rf \
	-lrc2014/system
RC2014ORG := 0x9000

ifeq ($(OPER),cygwin)
RC2014SERIALPORT := /dev/ttyS2
endif
ifeq ($(OPER),darwin)
RC2014SERIALPORT := /dev/cu.usbserial-A50285BI
endif
ifeq ($(OPER),linux)
RC2014SERIALPORT := /dev/ttyUSB0
endif

# ensure RC2014 is reset before starting
RC2014RESET := \
	printf '* \033[1;35mOn the RC2014: connect serial and press reset\033[0;0m\n' && \
	read -p "Then press enter to start: " LINE && \
	printf '* \033[1;33mResetting\033[0;0m\n' && \
	sh target/rc2014/reset.sh | $(ORTER) serial -o onlcrx -a $(RC2014SERIALPORT) 115200

# load modified hexload.bas
RC2014LOADLOADER := \
	printf '* \033[1;33mLoading $(RC2014HEXLOAD)\033[0;0m\n' ; \
	$(ORTER) serial -o onlcrx -e 5 $(RC2014SERIALPORT) 115200 < $(RC2014HEXLOAD)

# load an IHEX file
RC2014LOADIHEX := \
	printf '* \033[1;33mLoading IHEX\033[0;0m\n' ; \
	$(ORTER) serial -o onlcrx -a $(RC2014SERIALPORT) 115200 <

RC2014LOAD := $(RC2014RESET) ; $(RC2014LOADLOADER) ; $(RC2014LOADIHEX)

RC2014CONNECT := printf '* \033[1;33mStarting disc with console mux\033[0;0m\n' ; \
	$(DISC) mux $(RC2014SERIALPORT) 115200 $(DR0) $(DR1)

# build option
RC2014OPTION := assembly
#RC2014OPTION := default

ifeq ($(RC2014OPTION),assembly)
RC2014DEPS += rc2014/rf_z80.lib
RC2014LIBS += -lrc2014/rf_z80
RC2014ORIGIN := 0xA000
endif
ifeq ($(RC2014OPTION),default)
RC2014ORIGIN := 0xAB00
endif

RC2014ZCCOPTS := \
	+rc2014 -subtype=basic -clib=new -m \
	-DRF_INST_OFFSET=$(RC2014INSTOFFSET) \
	-DRF_ORIGIN=$(RC2014ORIGIN) \
	-DRF_ORG=$(RC2014ORG) \
	-DRF_TARGET_INC='\"target/rc2014/default.inc\"' \
	-Ca-DCRT_ITERM_TERMINAL_FLAGS=0x0000 \
	-Ca-DRF_INST_OFFSET=$(RC2014INSTOFFSET) \
	-Ca-DRF_ORIGIN=$(RC2014ORIGIN) \
	-Ca-DRF_ORG=$(RC2014ORG)

ifeq ($(RC2014OPTION),assembly)
RC2014ZCCOPTS += -DRF_ASSEMBLY
endif

rc2014 :

	mkdir $@

.PHONY : rc2014-build
rc2014-build : rc2014/orterforth.ihx

.PHONY : rc2014-clean
rc2014-clean :

	rm -rf rc2014/*

.PHONY : rc2014-connect
rc2014-connect : | $(DISC)

	@$(RC2014CONNECT)

.PHONY : rc2014-hw
rc2014-hw : rc2014/hw.ihx | $(RC2014HEXLOAD) $(ORTER)

	@$(RC2014LOAD) $<
	@$(ORTER) serial -o onlcrx $(RC2014SERIALPORT) 115200

.PHONY : rc2014-run
rc2014-run : rc2014/orterforth.ihx | $(RC2014HEXLOAD) $(ORTER) $(DISC)

	@$(RC2014LOAD) $<
	@$(RC2014CONNECT)

# modify hexload.bas to send ACK once when run and once when hex load complete
$(RC2014HEXLOAD) : tools/github.com/RC2014Z80/RC2014/BASIC-Programs/hexload/hexload.bas | rc2014

	sed 's/print usr/print chr$$(6):print usr/' < $< > $@

rc2014/hw.ihx : hw.c | rc2014

	zcc +rc2014 -subtype=basic -m hw.c -o rc2014/hw -create-app

# start with an empty bin file to build the multi segment bin
rc2014/inst-0.bin : | rc2014

	z88dk-appmake +rom --romsize 0x7000 --filler 0 --output $@

# add main code at start
rc2014/inst-1.bin : rc2014/inst-0.bin rc2014/inst_CODE.bin

	z88dk-appmake +inject --binfile $< --inject rc2014/inst_CODE.bin --offset 0 --output $@

# add inst code at offset, safely beyond dictionary
rc2014/inst-2.bin : rc2014/inst-1.bin rc2014/inst_INST.bin

	z88dk-appmake +inject --binfile $< --inject rc2014/inst_INST.bin --offset $(RC2014INSTOFFSET) --output $@

rc2014/inst.ihx : rc2014/inst-2.bin

	z88dk-appmake +hex \
		--binfile $< \
		--org $(RC2014ORG) \
		--output $@

rc2014/inst.lib : inst.c inst.h rf.h $(RC2014INC) | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $< \
		--codeseg=INST \
		--dataseg=INST \
		--bssseg=INST \
		--constseg=INST

rc2014/inst_CODE.bin rc2014/inst_INST.bin : \
	$(RC2014DEPS) \
	z80_memory.asm \
	main.c | rc2014

	zcc $(RC2014ZCCOPTS) $(RC2014LIBS) -o rc2014/inst z80_memory.asm main.c

rc2014/mux.lib : mux.c mux.h rf.h $(RC2014INC) | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $<

rc2014/orterforth : rc2014/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@.io
	mv $@.io $@

rc2014/orterforth.hex : rc2014/inst.ihx model.img | $(RC2014HEXLOAD) tx $(DISC) $(ORTER)

	@# NB this does not allow for BSS
	@$(CHECKMEMORY) $(RC2014ORG) $(RC2014ORIGIN) $(shell $(STAT) rc2014/inst_CODE.bin)

	@$(RC2014LOAD) rc2014/inst.ihx

	@printf '* \033[1;33mClearing DR1\033[0;0m\n'
	@rm -f $@.io
	@touch $@.io

# Linux (though not Darwin) reads EOF from stdin if run in background
# so pipe no bytes into stdin to keep disc from detecting EOF and terminating
	@sh scripts/start.sh /dev/null tx tail.pid tail -f
	@sh scripts/start.sh tx /dev/stdout disc.pid $(DISC) mux $(RC2014SERIALPORT) 115200 model.img $@.io
	@#$(STARTDISC) mux $(RC2014SERIALPORT) 115200 model.img $@.io

	@$(WAITUNTILSAVED) $@.io

	@$(STOPDISC)
	@sh scripts/stop.sh tail.pid

	@printf '* \033[1;33mDone\033[0;0m\n'
	@mv $@.io $@

rc2014/orterforth.ihx : rc2014/orterforth

	z88dk-appmake +hex --org $(RC2014ORG) --binfile $< --output $@

rc2014/rf.lib : rf.c rf.h $(RC2014INC) | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $<

rc2014/rf_z80.lib : rf_z80.asm | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $<

rc2014/system.lib : target/rc2014/system.c mux.h rf.h $(RC2014INC) | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $<

tools/github.com/RC2014Z80/RC2014/BASIC-Programs/hexload/hexload.bas :

	git submodule update --init tools/github.com/RC2014Z80/RC2014
