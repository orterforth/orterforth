# === BBC Micro ===

# common dependencies
BBCDEPS := bbc/inst.o bbc/main.o bbc/rf.o

# default loading method
BBCLOADINGMETHOD := disk

# default is to run MAME
BBCMACHINE := mame
#BBCMACHINE := real

# build config option
# BBCOPTION := assembly
BBCOPTION := default
# BBCOPTION := tape

# default ORG and ORIGIN
BBCORG := 1720
BBCORIGIN := 3000

# emulator ROM files
BBCROMS := \
	roms/bbcb/basic2.rom \
	roms/bbcb/dnfs120.rom \
	roms/bbcb/os12.rom \
	roms/bbcb/phroma.bin \
	roms/bbcb/saa5050

# include file maps to option
BBCINC := target/bbc/$(BBCOPTION).inc

# assembly code
ifeq ($(BBCOPTION),assembly)
	BBCDEPS += bbc/rf_6502.o bbc/system_asm.o
	BBCORIGIN := 2200
endif

# default C code
ifeq ($(BBCOPTION),default)
	BBCDEPS += bbc/mos.o bbc/system_c.o
endif

# assembly code, tape only config starting at 0x0E00
# BBCORG can be moved back to 0x0F20 if 0x0B00 onwards not used
# and BBCORIGIN by the same amount, then MODE 0, 1, 2 are available
ifeq ($(BBCOPTION),tape)
	BBCDEPS += bbc/rf_6502.o bbc/system_asm.o
	BBCLOADINGMETHOD := tape
	BBCORG := 1220
	BBCORIGIN := 1D00
endif

# apparently bbc.lib must be the last dep
BBCDEPS += bbc/bbc.lib

# physical machine loading method serial by default, ROM files not needed
ifeq ($(BBCMACHINE),real)
	BBCLOADINGMETHOD := serial
	BBCROMS :=
endif

# loading media
ifeq ($(BBCLOADINGMETHOD),disk)
	BBCINSTMEDIA = bbc/inst.ssd
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1 $(BBCINSTMEDIA)
	BBCMEDIA = bbc/orterforth.ssd
	BBCMAMERUN := -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1  $(BBCMEDIA)
endif
ifeq ($(BBCLOADINGMETHOD),serial)
	BBCINSTMEDIA = bbc/inst.ser
	BBCMEDIA = bbc/orterforth.ser
endif
ifeq ($(BBCLOADINGMETHOD),tape)
	BBCINSTMEDIA = bbc/inst.uef
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\r' -cassette $(BBCINSTMEDIA)
	BBCMEDIA = bbc/orterforth.uef
	BBCMAMERUN := -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\r' -cassette $(BBCMEDIA)
endif

bbc :

	mkdir $@

.PHONY : bbc-build
bbc-build : $(BBCMEDIA)

.PHONY : bbc-clean
bbc-clean : 

	rm -f bbc/*

# MAME command line
BBCMAME := bbcb $(MAMEOPTS) -rs423 null_modem -bitb socket.127.0.0.1:5705

# MAME command line for fast inst, no video and timeout
BBCMAMEFAST := bbcb -rompath roms -video none -sound none \
	-skip_gameinfo -nomax -window \
	-speed 50 -frameskip 10 -nothrottle -seconds_to_run 2000 \
	-rs423 null_modem -bitb socket.127.0.0.1:5705

# Prompt to load via serial
BBCLOADSERIAL := printf '* \033[1;35mConnect serial and type: *FX2,1 <enter>\033[0;0m\n' ; \
	read -p "  then on this machine press enter" LINE ; \
	printf '* \033[1;33mLoading via serial\033[0;0m\n' ; \
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) <

# load and run example disc
.PHONY : bbc-example
bbc-example : $(BBCMEDIA) $(BBCROMS) | $(DISC) example/$(EXAMPLE).disc $(DR1)

ifeq ($(BBCMACHINE),mame)
	@touch $(DR1)
	@$(STARTDISCTCP) example/$(EXAMPLE).disc $(DR1)

	# run mame
ifeq ($(BBCLOADINGMETHOD),disk)
	mame $(BBCMAME) -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\rEMPTY-BUFFERS 1 LOAD\r' -flop1 bbc/orterforth.ssd
endif
ifeq ($(BBCLOADINGMETHOD),serial)
	echo "serial load currently fails on MAME" && exit 1
endif
ifeq ($(BBCLOADINGMETHOD),tape)
	mame $(BBCMAME) -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\rEMPTY-BUFFERS 1 LOAD\r' -cassette bbc/orterforth.uef
endif

	@$(STOPDISC)
endif
ifeq ($(BBCMACHINE),real)
	@$(BBCLOADSERIAL) bbc/orterforth.ser

	@# prompt user
	@echo "* now type EMPTY-BUFFERS 1 LOAD"

	# run disc
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) example/$(EXAMPLE).disc $(DR1)
endif

# Hello World - NB this doesn't work because bbc.lib is incomplete
bbc-hw : bbc/hw.uef $(BBCROMS)

	mame $(BBCMAME) -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\r' -cassette bbc/hw.uef

# load and run
bbc-run : $(BBCMEDIA) $(BBCROMS) | $(DISC) $(DR0) $(DR1)

ifeq ($(BBCMACHINE),mame)
	@$(STARTDISCTCP) $(DR0) $(DR1)

	# run mame
	mame $(BBCMAME) $(BBCMAMERUN)

	@$(STOPDISC)
endif
ifeq ($(BBCMACHINE),real)
	@$(BBCLOADSERIAL) bbc/orterforth.ser

	# run disc
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) $(DR1)
endif

BBCCC65OPTS := -O -t none \
	-D__BBC__ \
	-DRF_ORG='0x$(BBCORG)' \
	-DRF_ORIGIN='0x$(BBCORIGIN)' \
	-DRF_TARGET_INC='"$(BBCINC)"'

# general assemble rule
bbc/%.o : bbc/%.s

	ca65 -DRF_ORIGIN='$$$(BBCORIGIN)' -o $@ $<

# general compile rule
bbc/%.s : %.c | bbc

	cc65 $(BBCCC65OPTS) -o $@ $<

# serial load file
bbc/%.ser : bbc/%

	printf "10FOR I%%=&$(BBCORG) TO &$(BBCORG)+$(shell $(STAT) $<)-1:?I%%=GET:NEXT I%%:P.\"done\"\r" > $@.io
	printf "20*FX3,7\r30VDU 6\r40CALL &$(BBCORG)\rRUN\r" >> $@.io
	cat -u $< >> $@.io
	mv $@.io $@

# tape WAV file
bbc/%.wav : bbc/%.uef | tools/github.com/haerfest/uef/uef2wave.py

	python3 tools/github.com/haerfest/uef/uef2wave.py < $< > $@.io
	mv $@.io $@

# custom target lib
bbc/bbc.lib : bbc/crt0.o

	cp $$(sh target/bbc/find-apple2.lib.sh) $@.io
	ar65 a $@.io bbc/crt0.o
	mv $@.io $@

# boot script
bbc/boot : | bbc

	printf '*RUN "orterfo"\r' > $@

# boot disc inf
bbc/boot.inf : | bbc

	echo "$$.!BOOT     0000   0000  CRC=0" > $@

# custom target crt
bbc/crt0.o : target/bbc/crt0.s

	ca65 -o $@ $<

# Hello World
bbc/hw : hw.o bbc/bbc.lib

	cl65 -O -t none -C target/bbc/bbc.cfg --start-addr 0x$(BBCORG) -o $@ $^

# Hello World
bbc/hw.uef : bbc/hw | $(ORTER)

	$(ORTER) bbc uef write hw 0x$(BBCORG) 0x$(BBCORG) < $< > $@.io
	mv $@.io $@

# inst binary
bbc/inst : $(BBCDEPS)

	cl65 -O -t none -C target/bbc/bbc.cfg --start-addr 0x$(BBCORG) -o $@ -m bbc/inst.map $^

# inst disc inf
bbc/inst.inf : | bbc

	echo "$$.orterfo  $(BBCORG)   $(BBCORG)  CRC=0" > $@

# inst lib
bbc/inst.s : inst.c rf.h $(BBCINC) | bbc

	cc65 $(BBCCC65OPTS) \
		--bss-name INST \
		--code-name INST \
		--data-name INST \
		--rodata-name INST \
		-o $@ $<

# inst disc image
bbc/inst.ssd : bbc/boot bbc/boot.inf bbc/inst bbc/inst.inf

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ bbc/inst

# inst tape image
bbc/inst.uef : bbc/inst $(ORTER)

	$(ORTER) bbc uef write orterforth 0x$(BBCORG) 0x$(BBCORG) <$< >$@.io
	mv $@.io $@

# MOS bindings
bbc/mos.o : target/bbc/mos.s | bbc

	ca65 -o $@ $<

# binary from hex
bbc/orterforth : bbc/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# binary hex
bbc/orterforth.hex : $(BBCINSTMEDIA) model.disc $(BBCROMS) | $(DISC)

	@printf '* \033[1;33mClearing DR1\033[0;0m\n'
	@rm -f $@.io
	@touch $@.io

ifeq ($(BBCMACHINE),mame)
	@$(STARTDISCTCP) model.disc $@.io

	@$(STARTMAME) $(BBCMAMEFAST) $(BBCMAMEINST)
endif
ifeq ($(BBCMACHINE),real)
	@$(BBCLOADSERIAL) $(BBCINSTMEDIA)

	@$(STARTDISC) serial $(SERIALPORT) $(SERIALBAUD) model.disc $@.io
endif

	@$(WAITUNTILSAVED) $@.io

ifeq ($(BBCMACHINE),mame)
	@$(STOPMAME)
endif

	@$(STOPDISC)

	@printf '* \033[1;33mDone\033[0;0m\n'
	@mv $@.io $@

# disc inf
bbc/orterforth.inf : | bbc

	echo "$$.orterfo  $(BBCORG)   $(BBCORG)  CRC=0" > $@

# disc image
bbc/orterforth.ssd : bbc/boot bbc/boot.inf bbc/orterforth bbc/orterforth.inf

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ bbc/orterforth

# tape image
bbc/orterforth.uef : bbc/orterforth $(ORTER)

	$(ORTER) bbc uef write orterforth 0x$(BBCORG) 0x$(BBCORG) <$< >$@.io
	mv $@.io $@

# main lib
bbc/rf.s : rf.c rf.h $(BBCINC) | bbc

	cc65 $(BBCCC65OPTS) -o $@ $<

# main lib, assembly
bbc/rf_6502.o : rf_6502.s | bbc

	ca65 -DRF_ORIGIN='0x$(BBCORIGIN)' -o $@ $<

# system lib, assembly
bbc/system_asm.o : target/bbc/system.s | bbc

	ca65 -o $@ $<

# system lib, C
bbc/system_c.s : target/bbc/system.c | bbc

	cc65 $(BBCCC65OPTS) -o $@ $<

# ROM files dir
roms/bbcb : | roms

	mkdir $@

# ROM files
roms/bbcb/% : | roms/bbcb

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

tools/github.com/haerfest/uef/uef2wave.py :

	git submodule init tools/github.com/haerfest/uef && git submodule update --init tools/github.com/haerfest/uef
