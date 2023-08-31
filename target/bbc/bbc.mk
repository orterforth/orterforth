# === BBC Micro ===

# loading method
BBCLOADINGMETHOD := disk
# BBCLOADINGMETHOD := serial
# BBCLOADINGMETHOD := tape

# emulator (or real machine)
BBCMACHINE := mame
#BBCMACHINE := real

# build config option
# BBCOPTION := assembly
BBCOPTION := default
# BBCOPTION := tape
ifeq ($(TARGET),bbc)
ifneq ($(OPTION),)
BBCOPTION := $(OPTION)
endif
endif

# cc65
BBCCC65OPTS := -O -t none -D__BBC__

# object dependencies
BBCDEPS := bbc/inst.o bbc/main.o

# load via serial
BBCLOADSERIAL := printf '* \033[1;35mConnect serial and type: *FX2,1 <enter>\033[0;0m\n' ; \
	read -p "  then on this machine press enter" LINE ; \
	printf '* \033[1;33mLoading via serial\033[0;0m\n' ; \
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) <

# MAME command line
BBCMAME := bbcb $(MAMEOPTS) -rs423 null_modem -bitb socket.127.0.0.1:5705

# MAME command line for fast inst, no video and timeout
BBCMAMEFAST := bbcb -rompath roms -video none -sound none \
	-skip_gameinfo -nomax -window \
	-speed 50 -frameskip 10 -nothrottle -seconds_to_run 2000 \
	-rs423 null_modem -bitb socket.127.0.0.1:5705

# default C ORG and Forth ORIGIN
BBCORG := 1720
BBCORIGIN := 2F00

# emulator ROM files
BBCROMS := \
	roms/bbcb/basic2.rom \
	roms/bbcb/dnfs120.rom \
	roms/bbcb/os12.rom \
	roms/bbcb/phroma.bin \
	roms/bbcb/saa5050

# assembly code
ifeq ($(BBCOPTION),assembly)
	BBCCC65OPTS += -DRF_ASSEMBLY
	BBCDEPS += bbc/rf_6502.o bbc/system_asm.o
	BBCORIGIN := 2100
endif

# default C code
ifeq ($(BBCOPTION),default)
	BBCDEPS += bbc/mos.o bbc/rf.o bbc/system_c.o
endif

# assembly code, tape only
ifeq ($(BBCOPTION),tape)
	BBCCC65OPTS += -DRF_ASSEMBLY
	BBCDEPS += bbc/rf_6502.o bbc/system_asm.o
	BBCLOADINGMETHOD := tape
# starts FIRST at 0x0E00, ORG at 0x1220
	BBCORG := 1220
	BBCORIGIN := 1C00
# starts FIRST at 0x0B00, ORG at 0x0F20
# if 0x0B00 onwards not used then MODE 0, 1, 2 are available
	# BBCORG := 0F20
	# BBCORIGIN := 1900
endif

# cc65 pass org and origin
BBCCC65OPTS += -DRF_ORG='0x$(BBCORG)' -DRF_ORIGIN='0x$(BBCORIGIN)'

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
	BBCMEDIA = bbc/orterforth.ssd
	BBCMAMEINSTMEDIA := -flop1 $(BBCINSTMEDIA)
	BBCMAMEMEDIA := -flop1 $(BBCMEDIA)
	BBCMAMECMD := '*DISK\r*EXEC !BOOT\r'
endif
ifeq ($(BBCLOADINGMETHOD),serial)
	BBCINSTMEDIA = bbc/inst.ser
	BBCMEDIA = bbc/orterforth.ser
	BBCMAMEINSTMEDIA :=
	BBCMAMEMEDIA :=
	BBCMAMECMD := '*FX2,1\r'
endif
ifeq ($(BBCLOADINGMETHOD),tape)
	BBCINSTMEDIA = bbc/inst.uef
	BBCMEDIA = bbc/orterforth.uef
	BBCMAMEINSTMEDIA := -cassette $(BBCINSTMEDIA)
	BBCMAMEMEDIA := -cassette $(BBCMEDIA)
	BBCMAMECMD := '*TAPE\r*RUN\r'
endif
BBCMAMEINST := -autoboot_delay 2 -autoboot_command $(BBCMAMECMD) $(BBCMAMEINSTMEDIA)
BBCMAMERUN := -autoboot_delay 2 -autoboot_command $(BBCMAMECMD) $(BBCMAMEMEDIA)

# notes: real disc runs after serial load
# MAME needs disc tcp running before it starts
# ideal is that disc starts after load in all cases
# requires a disc tcp client to connect to MAME tcp server
ifeq ($(BBCMACHINE),mame)
BBCSTARTDISC := $(STARTDISCTCP)
BBCSTARTMACHINE := sleep 1 ; $(STARTMAME) $(BBCMAMEFAST) $(BBCMAMEINST)
BBCRUNMACHINE := sleep 1 ; printf '* \033[1;33mRunning MAME\033[0;0m\n' ; mame $(BBCMAME) $(BBCMAMERUN)
BBCLOAD := :
BBCLOADINST := :
BBCSTOPMACHINE := $(STOPMAME)
endif
ifeq ($(BBCMACHINE),real)
BBCSTARTDISC := :
BBCSTARTMACHINE := :
BBCRUNMACHINE := :
BBCLOAD := $(BBCLOADSERIAL) bbc/orterforth.ser ; printf '* \033[1;33mRunning disc\033[0;0m\n' ; $(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) $(DR1)
BBCLOADINST := $(BBCLOADSERIAL) $(BBCINSTMEDIA) ; $(STARTDISC) serial $(SERIALPORT) $(SERIALBAUD) model.img $@.io
BBCSTOPMACHINE := :
endif

bbc :

	mkdir $@

.PHONY : bbc-build
bbc-build : $(BBCMEDIA)

.PHONY : bbc-clean
bbc-clean : 

	rm -f bbc/*

.PHONY : bbc-run
bbc-run : $(BBCMEDIA) | $(BBCROMS) $(DISC) $(DR0) $(DR1)

	@$(BBCSTARTDISC) $(DR0) $(DR1)

	@$(BBCRUNMACHINE)

	@$(BBCLOAD)

	@$(STOPDISC)

# disc inf
bbc/%.inf : | bbc

	echo "$$.orterfo  $(BBCORG)   $(BBCORG)  CRC=0" > $@

# general assemble rule
bbc/%.o : bbc/%.s

	ca65 -o $@ $<

# serial load file
bbc/%.ser : bbc/%

	printf "10FOR I%%=&$(BBCORG) TO &$(BBCORG)+$(shell $(STAT) $<)-1:?I%%=GET:NEXT I%%:P.\"done\"\r" > $@.io
	printf "20*FX3,7\r30VDU 6\r40CALL &$(BBCORG)\rRUN\r" >> $@.io
	cat -u $< >> $@.io
	mv $@.io $@

# disc image
bbc/%.ssd : bbc/% bbc/%.inf bbc/boot bbc/boot.inf

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ $<

# tape image
bbc/%.uef : bbc/% | $(ORTER)

	$(ORTER) bbc uef write orterforth 0x$(BBCORG) 0x$(BBCORG) < $< > $@.io
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
bbc/crt0.o : target/bbc/crt0.s | bbc

	ca65 -o $@ $<

# inst binary
bbc/inst bbc/inst.map : $(BBCDEPS)

	cl65 -O -t none -C target/bbc/bbc.cfg --start-addr 0x$(BBCORG) -o $@ -m bbc/inst.map $^

# inst lib
bbc/inst.s : inst.c rf.h target/bbc/bbc.inc | bbc

	cc65 $(BBCCC65OPTS) \
		--bss-name INST \
		--code-name INST \
		--data-name INST \
		--rodata-name INST \
		-o $@ $<

# main
bbc/main.s : main.c inst.h rf.h target/bbc/bbc.inc | bbc

	cc65 $(BBCCC65OPTS) -o $@ $<

# MOS bindings
bbc/mos.o : target/bbc/mos.s | bbc

	ca65 -o $@ $<

# binary from hex
bbc/orterforth : bbc/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# binary hex
bbc/orterforth.hex : $(BBCINSTMEDIA) model.img | $(BBCROMS) $(DISC)

	@$(CHECKMEMORY) 0x$(BBCORG) 0x$(BBCORIGIN) $$(( 0x$$(echo "$$(grep '^BSS' bbc/inst.map)" | cut -c '33-36') - 0x$(BBCORG) ))

	@$(EMPTYDR1FILE) $@.io

	@$(BBCSTARTDISC) model.img $@.io

	@$(BBCSTARTMACHINE)

	@$(BBCLOADINST)

	@$(WAITUNTILSAVED) $@.io

	@$(BBCSTOPMACHINE)

	@$(STOPDISC)

	@$(COMPLETEDR1FILE)

bbc/rf.s : rf.c rf.h target/bbc/bbc.inc | bbc

	cc65 $(BBCCC65OPTS) -o $@ $<

bbc/rf_6502.o : rf_6502.s | bbc

	ca65 -DORIG='0x$(BBCORIGIN)' -DTOS=\$$70 -o $@ $<

bbc/system_asm.o : target/bbc/system.s | bbc

	ca65 -o $@ $<

bbc/system_c.s : target/bbc/system.c | bbc

	cc65 $(BBCCC65OPTS) -o $@ $<

roms/bbcb : | roms

	mkdir $@

roms/bbcb/% : | roms/bbcb

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

tools/github.com/haerfest/uef/uef2wave.py :

	git submodule update --init tools/github.com/haerfest/uef
