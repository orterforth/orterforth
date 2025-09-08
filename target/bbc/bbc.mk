# === BBC Micro ===

# BBCLOADINGMETHOD := disk
# BBCLOADINGMETHOD := serial
BBCLOADINGMETHOD := tape

# BBCMACHINE := mame
BBCMACHINE := real

# BBCOPTION := assembly
BBCOPTION := default
# BBCOPTION := tape
ifeq ($(TARGET),bbc)
ifneq ($(OPTION),)
BBCOPTION := $(OPTION)
endif
endif

BBCCC65OPTS := -O -t none -D__BBC__
BBCDEPS := bbc/inst.o bbc/main.o
BBCLOADSERIAL := \
	$(PROMPT) "Connect serial and on BBC Micro type: *FX2,1 <RETURN>" && \
	$(INFO) 'Loading via serial' && \
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) <
BBCLOADTAPE := \
	$(PROMPT) "Connect tape audio and on BBC Micro type: *TAPE <RETURN> *RUN <RETURN>" && \
	$(INFO) 'Loading via tape' && \
	$(PLAY)
BBCMAME := bbcb $(MAMEOPTS) -rs423 null_modem -bitb socket.127.0.0.1:5705
BBCMAMEFAST := bbcb -rompath roms -video none -sound none \
	-skip_gameinfo -nomax -window \
	-speed 50 -frameskip 10 -nothrottle -seconds_to_run 2000 \
	-rs423 null_modem -bitb socket.127.0.0.1:5705
BBCORG := 1720
BBCORIGIN := 2E80
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
	BBCORIGIN := 2000
endif
# default C code
ifeq ($(BBCOPTION),default)
	BBCDEPS += bbc/io.o bbc/mos.o bbc/rf.o bbc/system_c.o
endif
# assembly code, tape only
ifeq ($(BBCOPTION),tape)
	BBCCC65OPTS += -DRF_ASSEMBLY
	BBCDEPS += bbc/rf_6502.o bbc/system_asm.o
	BBCLOADINGMETHOD := tape
# starts FIRST at 0x0E00, ORG at 0x1220
	# BBCORG := 1220
	# BBCORIGIN := 1B00
# starts FIRST at 0x0B00, ORG at 0x0F20
# if 0x0B00 onwards not used then MODE 0, 1, 2 are available
	BBCORG := 0F20
	BBCORIGIN := 1800
endif
# cc65 pass org and origin
BBCCC65OPTS += -DRF_ORG='0x$(BBCORG)' -DRF_ORIGIN='0x$(BBCORIGIN)'
BBCDEPS += bbc/crt0.o

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

# notes: real disc runs after serial load
# MAME needs disc tcp running before it starts
# ideal is that disc starts after load in all cases
# requires a disc tcp client to connect to MAME tcp server
ifeq ($(BBCMACHINE),mame)
BBCSERIALARGS := tcp server 5705
BBCSTARTDISC := $(STARTDISCTCP)
BBCLOAD := sleep 1 ; $(INFO) 'Running MAME' ; mame $(BBCMAME) -autoboot_delay 2 -autoboot_command $(BBCMAMECMD) $(BBCMAMEMEDIA)
BBCLOADINST = sleep 1 ; $(STARTMACHINE) mame $(BBCMAMEFAST) -autoboot_delay 2 -autoboot_command $(BBCMAMECMD) $(BBCMAMEINSTMEDIA)
BBCSTOPMACHINE = $(STOPMACHINE)
endif
ifeq ($(BBCMACHINE),real)
BBCSERIALARGS := serial $(SERIALPORT) $(SERIALBAUD)
BBCROMS :=
BBCSTOPMACHINE := :
ifeq ($(BBCLOADINGMETHOD),disk)
BBCLOAD := $(WARN) "disk load not implemented" ; exit 1
BBCLOADINST := $(WARN) "disk load not implemented" ; exit 1
BBCSTARTDISC := $(WARN) "disk load not implemented" ; exit 1
endif
ifeq ($(BBCLOADINGMETHOD),serial)
BBCLOAD := $(BBCLOADSERIAL) $(BBCMEDIA) && $(INFO) 'Running disc' && $(DISC) $(BBCSERIALARGS) $(DR0) $(DR1)
BBCLOADINST = $(BBCLOADSERIAL) $(BBCINSTMEDIA) && $(STARTDISC) $(BBCSERIALARGS) model.img $@.io
BBCSTARTDISC := :
endif
ifeq ($(BBCLOADINGMETHOD),tape)
BBCINSTMEDIA = bbc/inst.wav
BBCMEDIA = bbc/orterforth.wav
BBCLOAD := $(BBCLOADTAPE) $(BBCMEDIA) && $(PROMPT) 'Press <enter> to stop disc'
BBCLOADINST = $(BBCLOADTAPE) $(BBCINSTMEDIA)
BBCSTARTDISC := $(STARTDISC) $(BBCSERIALARGS)
endif
endif

bbc :

	mkdir $@

.PHONY : bbcim
bbcim :

	@$(REQUIRETOOL)

.PHONY : bbc-build
bbc-build : $(BBCMEDIA)

.PHONY : bbc-run
bbc-run : $(BBCMEDIA) | $(BBCROMS) $(DISC) $(DR0) $(DR1)

	@$(BBCSTARTDISC) $(DR0) $(DR1)
	@$(BBCLOAD)
	@$(STOPDISC)

bbc/%.inf : | bbc

	printf "$$.orterfo  %04X   %04X  CRC=0\n" 0x$(BBCORG) 0x$(BBCORG) > $@

bbc/%.o : bbc/%.s

	ca65 -o $@ $<

bbc/%.s : %.c rf.h target/bbc/bbc.inc | bbc cc65

	cc65 $(BBCCC65OPTS) -o $@ $<

bbc/%.ser : bbc/%

	printf "10FOR I%%=&%X TO &%X:?I%%=GET:NEXT I%%:P.\"done\"\r" 0x$(BBCORG) $$((0x$(BBCORG)+$$($(STAT) $<)-1)) > $@.io
	printf "20*FX3,7\r30VDU 6\r40FOR J%%=1 TO 10000:NEXT J%%:CALL &%X\rRUN\r" 0x$(BBCORG) >> $@.io
	cat -u $< >> $@.io
	mv $@.io $@

bbc/%.ssd : bbc/% bbc/%.inf bbc/boot bbc/boot.inf | bbcim

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ $<

bbc/%.uef : bbc/% | $(ORTER)

	$(ORTER) bbc bin to uef orterforth 0x$(BBCORG) 0x$(BBCORG) < $< > $@.io
	mv $@.io $@

bbc/%.wav : bbc/%.uef | tools/github.com/haerfest/uef/uef2wave.py

	python3 tools/github.com/haerfest/uef/uef2wave.py < $< > $@.io
	mv $@.io $@

bbc/boot : | bbc

	printf '*RUN "orterfo"\r' > $@

bbc/boot.inf : | bbc

	echo '$$.!BOOT     0000   0000  CRC=0' > $@

bbc/crt0.o : target/bbc/crt0.s | bbc

	ca65 -o $@ $<

bbc/inst bbc/inst.map : $(BBCDEPS)

	cl65 -O -t none -C target/bbc/bbc.cfg --start-addr 0x$(BBCORG) -o $@ -m bbc/inst.map $^

bbc/inst.s : inst.c rf.h target/bbc/bbc.inc | bbc cc65

	cc65 $(BBCCC65OPTS) \
		--bss-name INST \
		--code-name INST \
		--data-name INST \
		--rodata-name INST \
		-o $@ $<

bbc/mos.o : target/bbc/mos.s | bbc

	ca65 -o $@ $<

bbc/orterforth : bbc/orterforth.img | $(ORTER)

	$(ORTER) hex read < $< > $@

# TODO when BBCLOADINGMETHOD is different between build and run time
# make attempts to rebuild because bbc/inst.* is newer.
bbc/orterforth.img : $(BBCINSTMEDIA) model.img | $(BBCROMS) $(DISC)

	@$(CHECKMEMORY) 0x$(BBCORG) 0x$(BBCORIGIN) $$(( 0x$$(echo "$$(grep '^BSS' bbc/inst.map)" | cut -c '33-36') - 0x$(BBCORG) ))
# TODO real serial load must precede disc start, currently part of BBCLOADINST
	@$(INSTALLDISC) $(BBCSERIALARGS) &
	@$(BBCLOADINST)
	@$(WAITFORFILE)
	@$(BBCSTOPMACHINE)

bbc/rf_6502.o : rf_6502.s | bbc

	ca65 -DORIG='0x$(BBCORIGIN)' -DTOS=\$$70 -o $@ $<

bbc/system_asm.o : target/bbc/system.s | bbc

	ca65 -o $@ $<

bbc/system_c.s : target/bbc/system.c rf.h target/bbc/bbc.inc | bbc

	cc65 $(BBCCC65OPTS) -o $@ $<

tools/github.com/haerfest/uef/uef2wave.py :

	git submodule update --init tools/github.com/haerfest/uef

tools/wouter.bbcmicro.net/bbc/bestanden :

	mkdir -p $@

tools/wouter.bbcmicro.net/bbc/bestanden/bbcim-1.0.1.zip : | tools/wouter.bbcmicro.net/bbc/bestanden

	curl -o $@ http://wouter.bbcmicro.net/bbc/bestanden/bbcim-1.0.1.zip

tools/wouter.bbcmicro.net/bbc/bestanden/bbcim-1.0.1/src/bbcim.c : | tools/wouter.bbcmicro.net/bbc/bestanden/bbcim-1.0.1.zip

	unzip -d tools/wouter.bbcmicro.net/bbc/bestanden $<

tools/wouter.bbcmicro.net/bbc/bestanden/bbcim-1.0.1/bbcim : tools/wouter.bbcmicro.net/bbc/bestanden/bbcim-1.0.1/src/bbcim.c

	cd tools/wouter.bbcmicro.net/bbc/bestanden/bbcim-1.0.1 && make