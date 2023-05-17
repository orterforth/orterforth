# === RC2014 ===

rc2014 :

	mkdir $@

.PHONY : rc2014-build
rc2014-build : rc2014/orterforth.ihx

.PHONY : rc2014-clean
rc2014-clean :

	rm -rf rc2014/*

# RC2014 serial port name
ifeq ($(OPER),cygwin)
RC2014SERIALPORT := /dev/ttyS2
endif
ifeq ($(OPER),darwin)
RC2014SERIALPORT := /dev/cu.usbserial-A50285BI
endif
ifeq ($(OPER),linux)
RC2014SERIALPORT := /dev/ttyUSB0
endif

# build option
RC2014OPTION := assembly
#RC2014OPTION := default

RC2014DEPS := rc2014/rf.lib rc2014/inst.lib rc2014/system.lib
RC2014INC := target/rc2014/default.inc
RC2014INSTOFFSET := 0x5000
RC2014LIBS := -lrc2014/rf -lrc2014/inst -lrc2014/system
RC2014ORG := 0x9000

ifeq ($(RC2014OPTION),assembly)
RC2014DEPS += rc2014/z80.lib
RC2014LIBS += -lrc2014/z80
RC2014ORIGIN := 0x9F80
endif
ifeq ($(RC2014OPTION),default)
RC2014ORIGIN := 0xAB00
endif

RC2014RESET := \
	printf '* \033[1;35mOn the RC2014: connect serial and press reset\033[0;0m\n' && \
	read -p "Then press enter to start: " LINE && \
	printf '* \033[1;33mResetting\033[0;0m\n' && \
	sh target/rc2014/reset.sh | $(ORTER) serial -o onlcrx -a $(RC2014SERIALPORT) 115200

RC2014ZCCOPTS := \
	+rc2014 -subtype=basic -clib=new -m \
	-DRF_INST_OFFSET=$(RC2014INSTOFFSET) \
	-DRF_ORIGIN=$(RC2014ORIGIN) \
	-DRF_ORG=$(RC2014ORG) \
	-DRF_TARGET_INC='\"$(RC2014INC)\"' \
	-Ca-DCRT_ITERM_TERMINAL_FLAGS=0x0000 \
	-Ca-DRF_INST_OFFSET=$(RC2014INSTOFFSET) \
	-Ca-DRF_ORIGIN=$(RC2014ORIGIN) \
	-Ca-DRF_ORG=$(RC2014ORG)

ifeq ($(RC2014OPTION),assembly)
RC2014ZCCOPTS += -DRF_ASSEMBLY
endif

.PHONY : rc2014-run
rc2014-run : rc2014/orterforth.ser | $(ORTER) $(DISC)

	@$(RC2014RESET)

	@printf '* \033[1;33mLoading via serial\033[0;0m\n'
	@$(ORTER) serial -o onlcrx -e 3 $(RC2014SERIALPORT) 115200 < rc2014/orterforth.ser

	@printf '* \033[1;33mStarting disc with console mux\033[0;0m\n'
	@$(DISC) mux $(RC2014SERIALPORT) 115200 $(DR0) $(DR1)

# hexload
# TODO remove this intermediate copy
rc2014/hexload.bas : tools/github.com/RC2014Z80/RC2014/BASIC-Programs/hexload/hexload.bas | rc2014

	cp $< $@

# inst executable
rc2014/inst_CODE.bin : \
	$(RC2014DEPS) \
	z80_memory.asm \
	main.c

	zcc \
		$(RC2014ZCCOPTS) \
		$(RC2014LIBS) \
		-o rc2014/inst \
		z80_memory.asm main.c

# start with an empty bin file to build the multi segment bin
rc2014/inst-0.bin : | rc2014

	z88dk-appmake +rom \
		--romsize 0x7000 \
		--filler 0 \
		--output $@

# add main code at start
rc2014/inst-1.bin : \
	rc2014/inst-0.bin \
	rc2014/inst_CODE.bin

	z88dk-appmake +inject \
		--binfile $< \
		--inject rc2014/inst_CODE.bin \
		--offset 0 \
		--output $@

# add inst code at offset, safely beyond dictionary
rc2014/inst-2.bin : \
	rc2014/inst-1.bin \
	rc2014/inst_INST.bin

	z88dk-appmake +inject \
		--binfile $< \
		--inject rc2014/inst_INST.bin \
		--offset $(RC2014INSTOFFSET) \
		--output $@

# make inst tap from inst bin
rc2014/inst.ihx : rc2014/inst-2.bin

	z88dk-appmake +hex \
		--binfile $< \
		--org $(RC2014ORG) \
		--output $@

# both CODE and INST bin files are built by same command
rc2014/inst_INST.bin : rc2014/inst_CODE.bin

# inst code
rc2014/inst.lib : inst.c rf.h $(RC2014INC) inst.h | rc2014

	zcc \
		$(RC2014ZCCOPTS) \
		-x -o $@ $< \
		--codeseg=INST \
		--dataseg=INST \
		--bssseg=INST \
		--constseg=INST

# inst serial load file - seems an unreliable approach
rc2014/inst.ser : rc2014/hexload.bas rc2014/inst.ihx

	cp rc2014/hexload.bas $@.io
	cat rc2014/inst.ihx >> $@.io
	mv $@.io $@

# final binary from hex
rc2014/orterforth : rc2014/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@.io
	mv $@.io $@

# saved hex result
rc2014/orterforth.hex : rc2014/hexload.bas rc2014/inst.ihx model.img | $(DISC) $(ORTER)

	@# NB this does not allow for BSS
	@$(CHECKMEMORY) $(RC2014ORG) $(RC2014ORIGIN) $(shell $(STAT) rc2014/inst_CODE.bin)

	@$(RC2014RESET)

	@printf '* \033[1;33mLoading hexload\033[0;0m\n'
	@$(ORTER) serial -o onlcrx -e 3 $(RC2014SERIALPORT) 115200 < rc2014/hexload.bas
	@printf '* \033[1;33mLoading inst\033[0;0m\n'
	@$(ORTER) serial -o onlcrx -e 3 $(RC2014SERIALPORT) 115200 < rc2014/inst.ihx

	@printf '* \033[1;33mClearing DR1\033[0;0m\n'
	@rm -f $@.io
	@touch $@.io

	@$(STARTDISC) mux $(RC2014SERIALPORT) 115200 model.img $@.io

	@$(WAITUNTILSAVED) $@.io

	@$(STOPDISC)

	@printf '* \033[1;33mDone\033[0;0m\n'
	@mv $@.io $@

# final binary as IHEX
rc2014/orterforth.ihx : rc2014/orterforth

	z88dk-appmake +hex --org $(RC2014ORG) --binfile $< --output $@

# serial load file
rc2014/orterforth.ser : rc2014/hexload.bas rc2014/orterforth.ihx

	cp rc2014/hexload.bas $@.io
	cat rc2014/orterforth.ihx >> $@.io
	mv $@.io $@

# base orterforth code
rc2014/rf.lib : rf.c rf.h $(RC2014INC) | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $<

# system code
rc2014/system.lib : target/rc2014/system.c rf.h $(RC2014INC) | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $<

# Z80 assembly optimised code
rc2014/z80.lib : rf_z80.asm | rc2014

	zcc $(RC2014ZCCOPTS) -x -o $@ $<

tools/github.com/RC2014Z80/RC2014/BASIC-Programs/hexload/hexload.bas :

	git submodule init tools/github.com/RC2014Z80/RC2014
	git submodule update --init tools/github.com/RC2014Z80/RC2014
