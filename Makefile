# C compiler options
CFLAGS += -Wall -Werror -std=c89 -ansi -Wpedantic

# determine local system OS and architecture
UNAME_S := $(shell uname -s)
ifneq ($(filter CYGWIN%,$(UNAME_S)),)
	OPER := cygwin
endif
ifeq ($(UNAME_S),Darwin)
	OPER := darwin
endif
ifeq ($(UNAME_S),Linux)
	OPER := linux
endif
ifeq ($(UNAME_S),MINGW)
	OPER := mingw
endif
UNAME_M := $(shell uname -m)
PROC := $(UNAME_M)

SYSTEM := $(OPER)-$(PROC)

# platform to build by default
TARGET := $(SYSTEM)

# local system target executables
DISC := $(SYSTEM)/disc
ORTER := $(SYSTEM)/orter
ORTERFORTH := $(SYSTEM)/orterforth

# serial port
ifeq ($(OPER),darwin)
SERIALPORT := /dev/tty.usbserial-FT2XIBOF
endif
ifeq ($(OPER),linux)
SERIALPORT := /dev/ttyUSB0
endif
SERIALBAUD := 9600

# default target
.PHONY : default
default : build

# local disc server executable
$(DISC) : \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/rf_persci.o \
	disc.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

# orter - retrocomputing multitool
$(ORTER) : \
	$(SYSTEM)/orter_fuse.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_spectrum.o \
	$(SYSTEM)/orter_uef.o \
	orter.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^


# === LOCAL SYSTEM ===

# local orterforth executable
$(ORTERFORTH) : \
	$(SYSTEM)/rf.o \
	$(SYSTEM)/rf_inst.o \
	$(SYSTEM)/rf_persci.o \
	$(SYSTEM)/rf_system.o \
	orterforth.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

# local system build dir
$(SYSTEM) :

	mkdir $@

# local system lib default
$(SYSTEM)/%.o : %.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# all local system executables
.PHONY : $(SYSTEM)-build
$(SYSTEM)-build : \
	$(DISC) \
	$(ORTER) \
	$(ORTERFORTH)

# clean local system build
.PHONY : $(SYSTEM)-clean
$(SYSTEM)-clean :

	rm -rf $(SYSTEM)/*

# run local build
.PHONY : $(SYSTEM)-run
$(SYSTEM)-run : $(ORTERFORTH) orterforth.disc

	@touch 0.disc
	@$(ORTERFORTH)

# main lib
$(SYSTEM)/rf.o : rf.c rf.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# inst lib
$(SYSTEM)/rf_inst.o : rf_inst.c rf.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# disc impl lib
$(SYSTEM)/rf_persci.o : rf_persci.c rf_persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# local system lib
$(SYSTEM)/rf_system.o : rf_system.c rf.h rf_persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# emulator to build fast
$(SYSTEM)/emulate_spectrum : \
	$(SYSTEM)/emulate_spectrum.o \
	$(SYSTEM)/z80.o \
	$(SYSTEM)/rf_persci.o

	$(CC) -o $@ $^

# spectrum emulator
$(SYSTEM)/emulate_spectrum.o : target/spectrum/emulate.c rf_persci.h z80.h | $(SYSTEM)

	mkdir -p $(@D)
	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

# local test executable
$(SYSTEM)/test : \
	$(SYSTEM)/rf.o \
	test.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

# https://github.com/superzazu/z80.git
$(SYSTEM)/z80.o : z80.c z80.h | $(SYSTEM)

	mkdir -p $(@D)
	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

# help
.PHONY : $(TARGET)-help
$(TARGET)-help :

	@if [ "$(TARGET)" == "$(SYSTEM)" ] ; then cat help/system.txt ; else more help/$(TARGET).txt ; fi

# disc images from %.f files including orterforth.f
%.disc : %.f | $(DISC)

	$(DISC) create <$< >$@


# === BBC Micro ===

# build config option
# BBCOPTION := assembly
BBCOPTION := default
# BBCOPTION := tape

# emulator ROM files
BBCROMS := \
	roms/bbcb/os12.rom \
	roms/bbcb/basic2.rom \
	roms/bbcb/phroma.bin \
	roms/bbcb/saa5050 \
	roms/bbcb/dnfs120.rom

# assembly code
ifeq ($(BBCOPTION),assembly)
	BBCDEPS := bbc/orterforth.o bbc/rf.o bbc/rf_6502.o bbc/rf_inst.o bbc/rf_system_asm.o bbc/bbc.lib
	BBCINC := target/bbc/assembly.inc
	BBCINSTMEDIA = bbc/orterforth-inst.ssd
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1 bbc/orterforth-inst.ssd
	BBCORG := 1720
	BBCORIGIN := 2400
	BBCRUN := bbc-run-disk
endif

# default C code
ifeq ($(BBCOPTION),default)
	BBCDEPS := bbc/mos.o bbc/orterforth.o bbc/rf.o bbc/rf_inst.o bbc/rf_system_c.o bbc/bbc.lib
	BBCINC := target/bbc/default.inc
	BBCINSTMEDIA = bbc/orterforth-inst.ssd
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1 bbc/orterforth-inst.ssd
	BBCORG := 1720
	BBCORIGIN := 2D00
	BBCRUN := bbc-run-disk
endif

# assembly code, tape only config starting at 0xE00
ifeq ($(BBCOPTION),tape)
	BBCDEPS := bbc/orterforth.o bbc/rf.o bbc/rf_6502.o bbc/rf_inst.o bbc/rf_system_asm.o bbc/bbc.lib
	BBCINC := target/bbc/tape.inc
	BBCINSTMEDIA = bbc/orterforth-inst.uef
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\r' -cassette bbc/orterforth-inst.uef
	BBCORG := 1220
	BBCORIGIN := 1F00
	BBCRUN := bbc-run-tape
endif

bbc :

	mkdir $@

.PHONY : bbc-clean
bbc-clean : 

	rm -f bbc/*

# MAME command line
BBCMAME := mame bbcb -video opengl \
	-skip_gameinfo -nomax -window \
	-rs423 null_modem -bitb socket.localhost:5705

BBCMAMEFAST := mame bbcb -video none -sound none \
	-skip_gameinfo -nomax -window \
	-speed 20 -frameskip 10 -nothrottle -seconds_to_run 640 \
	-rs423 null_modem -bitb socket.localhost:5705

# default is to load from disk
.PHONY : bbc-run
bbc-run : $(BBCRUN)

# load from disk and run
.PHONY : bbc-run-disk
bbc-run-disk : bbc/orterforth.ssd $(BBCROMS) | $(DISC) messages.disc

	cp messages.disc 0.disc
	bash scripts/tcp-redirect.sh 127.0.0.1 5705 $(DISC) standard 0.disc 1.disc &

	@$(BBCMAME) -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1 bbc/orterforth.ssd

# load from tape and run
.PHONY : bbc-run-tape
bbc-run-tape : bbc/orterforth.uef $(BBCROMS) | $(DISC) messages.disc

	cp messages.disc 0.disc
	bash scripts/tcp-redirect.sh 127.0.0.1 5705 $(DISC) standard 0.disc 1.disc &

	@$(BBCMAME) -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\r' -cassette bbc/orterforth.uef

# general assemble rule
bbc/%.o : bbc/%.s

	ca65 -DRF_ORIGIN='$$$(BBCORIGIN)' -o $@ $<

# general compile rule
bbc/%.s : %.c | bbc

	cc65 -O -t none -D__BBC__ -DRF_TARGET_INC='"$(BBCINC)"' -o $@ $<

# find cc65 install dir and copy lib file
bbc/apple2.lib : $(shell readlink $(shell which ld65))

	readlink $$(which ld65)
	cp -p $(<D)/../lib/apple2.lib $@

# custom target lib
bbc/bbc.lib : bbc/crt0.o bbc/apple2.lib

	cp bbc/apple2.lib $@.io
	ar65 a $@.io bbc/crt0.o
	mv $@.io $@

# boot script
bbc/boot : | bbc

	printf '*RUN "ORTERFO"\r' > $@

# boot disc inf
bbc/boot.inf : | bbc

	echo "$$.!BOOT     0000   0000  CRC=0" > $@

# custom target crt
bbc/crt0.o : target/bbc/crt0.s

	ca65 -o $@ $<

# MOS bindings
bbc/mos.o : target/bbc/mos.s | bbc

	ca65 -o $@ $<

# final binary from the hex
bbc/orterforth : bbc/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# final binary hex
bbc/orterforth.hex : $(BBCINSTMEDIA) orterforth.disc $(BBCROMS) | $(DISC)

	# empty disc
	rm -f $@.io
	touch $@.io

	# serve disc
	bash scripts/tcp-redirect.sh 127.0.0.1 5705 $(DISC) standard orterforth.disc $@.io &

	# run emulator, wait for result
	$(BBCMAMEFAST) $(BBCMAMEINST) & pid=$$! ; \
		scripts/waitforhex $@.io ; \
		kill -9 $$pid

	# copy result
	mv $@.io $@

# final disc inf
bbc/orterforth.inf : | bbc

	echo "$$.ORTERFO  $(BBCORG)   $(BBCORG)  CRC=0" > $@

# final disc image
bbc/orterforth.ssd : bbc/boot bbc/boot.inf bbc/orterforth bbc/orterforth.inf

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ bbc/orterforth

# final tape image
bbc/orterforth.uef : bbc/orterforth $(ORTER)

	$(ORTER) uef write orterforth 0x$(BBCORG) 0x$(BBCORG) <$< >$@.io
	mv $@.io $@

# inst binary
bbc/orterforth-inst : $(BBCDEPS)

	cl65 -O -t none -C target/bbc/bbc.cfg --start-addr 0x$(BBCORG) -o $@ -m bbc/orterforth-inst.map $^

# inst disc inf
bbc/orterforth-inst.inf : | bbc

	echo "$$.ORTERFO  $(BBCORG)   $(BBCORG)  CRC=0" > $@

# inst disc image
bbc/orterforth-inst.ssd : bbc/boot bbc/boot.inf bbc/orterforth-inst bbc/orterforth-inst.inf

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ bbc/orterforth-inst

# inst tape image
bbc/orterforth-inst.uef : bbc/orterforth-inst

	$(ORTER) uef write orterforth 0x$(BBCORG) 0x$(BBCORG) <$< >$@.io
	mv $@.io $@

# main lib
bbc/rf.s : rf.c rf.h $(BBCINC) | bbc

	cc65 -O -t none -D__BBC__ -DRF_ORIGIN='0x$(BBCORIGIN)' -DRF_TARGET_INC='"$(BBCINC)"' -o $@ $<

# asm bbc system lib
bbc/rf_6502.o : rf_6502.s | bbc

	ca65 -DRF_ORIGIN='0x$(BBCORIGIN)' -o $@ $<

# main lib
bbc/rf_inst.s : rf_inst.c rf.h $(BBCINC) | bbc

	# TODO determine why INST and INDA need to be distinct sections
	cc65 -O -t none -D__BBC__ -DRF_ORIGIN='0x$(BBCORIGIN)' -DRF_TARGET_INC='"$(BBCINC)"' --bss-name INST --code-name INST --data-name INDA --rodata-name INST -o $@ $<

# system lib, C
bbc/rf_system_c.s : target/bbc/system.c | bbc

	cc65 -O -t none -D__BBC__ -DRF_ORIGIN='0x$(BBCORIGIN)' -o $@ $<

# system lib, assembly
bbc/rf_system_asm.o : target/bbc/system.s | bbc

	ca65 -DRF_ORIGIN='0x$(BBCORIGIN)' -o $@ $<

# build
.PHONY : build
build : $(TARGET)-build

# build all
.PHONY : build-all
build-all : $(SYSTEM)-build spectrum-build


c64 :

	mkdir $@

# general assemble rule
c64/%.o : c64/%.s

	ca65 -t c64 -o $@ $<

# general compile rule
c64/%.s : %.c | c64

	cc65 -O -t c64 -DRF_TARGET_INC='"target/c64/default.inc"' -o $@ $<

# general compile rule
c64/hw : hw.c | c64

	cl65 -O -t c64 -o $@ $<

# # C system lib
c64/rf_system_c.s : target/c64/system.c | c64

	cc65 -O -t c64 -o $@ $<

# inst binary
c64/orterforth-inst : c64/orterforth.o c64/rf.o c64/rf_inst.o c64/rf_system_c.o | c64

	cl65 -O -t c64 -o $@ -m c64/orterforth-inst.map $^

# clean
.PHONY : clean
clean : $(TARGET)-clean

# clean all
.PHONY : clean-all
clean-all : $(SYSTEM)-clean spectrum-clean

# run disc on physical serial port
.PHONY : disc
disc : $(DISC)

	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) 0.disc 1.disc

# help
.PHONY : help
help : $(TARGET)-help

ql :

	mkdir $@

ql/hw : hw.c | ql

	qcc -o $@ $<

ql/orterforth : rf.c rf_inst.c orterforth.c | ql

	qcc -o $@ $^

# ROM file dir
roms : 

	mkdir $@

# BBC Micro ROM files dir
roms/bbcb : | roms

	mkdir $@

# BBC Micro ROM files
roms/bbcb/% : | roms/bbcb

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

# run local build
.PHONY : run
run : $(TARGET)-run


# === ZX Spectrum ===

spectrum :

	mkdir $@

.PHONY : spectrum-build
spectrum-build : spectrum/orterforth.ser spectrum/orterforth.tap

.PHONY : spectrum-clean
spectrum-clean :

	rm -rf spectrum/*

# connect disc to Fuse named pipes
.PHONY : spectrum-fuse-disc
spectrum-fuse-disc : | $(DISC) $(ORTER) spectrum/fuse-rs232-rx spectrum/fuse-rs232-tx

	$(ORTER) fuse serial read \
		< spectrum/fuse-rs232-tx \
		| $(DISC) standard 0.disc 1.disc \
		| $(ORTER) fuse serial write \
		> spectrum/fuse-rs232-rx &

# locate Fuse Emulator
ifeq ($(OPER),cygwin)
FUSE := "/cygdrive/c/Program Files/Fuse/fuse.exe"
else
FUSE := $(shell which fuse)
endif

# run Fuse emulator and load TAP
.PHONY : spectrum-fuse-tap
spectrum-fuse-tap : spectrum/orterforth.tap | roms/spectrum/if1-2.rom spectrum/fuse-rs232-rx spectrum/fuse-rs232-tx

	$(FUSE) \
		--speed=100 \
		--machine 48 \
		--graphics-filter 2x \
		--interface1 \
		--rom-interface-1 roms/spectrum/if1-2.rom \
		--rs232-rx spectrum/fuse-rs232-rx \
		--rs232-tx spectrum/fuse-rs232-tx \
		$< &

# load from serial
# TODO should not rebuild orterforth-inst-2.tap via dependency chain
.PHONY : spectrum-load-serial
spectrum-load-serial : spectrum/orterforth.ser target/spectrum/load-serial.bas

	@echo "On the Spectrum type: FORMAT \"b\";$(SERIALBAUD)"
	@echo "                      LOAD *\"b\""
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial write -w 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas

	@echo "* Loading orterforth..."
	@$(ORTER) serial write -w 15 $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth.ser

	@echo "* Starting disc..."
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) 0.disc 1.disc

# config option
SPECTRUMOPTION := a

# minimal ROM-based
ifeq ($(SPECTRUMOPTION),a)
# uses Interface 1 ROM for RS232
SPECTRUMLIBS := \
	-lmzx_tiny \
	-lndos \
	-lspectrum/rf \
	-lspectrum/rf_inst \
	-lspectrum/rf_system \
	-lspectrum/rf_z80 \
	-pragma-redirect:fputc_cons=fputc_cons_rom_rst
# ORG starts at high memory, for performance
SPECTRUMORG := 32768
# ORIGIN
SPECTRUMORIGIN := 35840
# assembly system dependent code uses ROM routines
SPECTRUMSYSTEM := target/spectrum/system.asm
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# superzazu emulator is minimal and launches no GUI
SPECTRUMIMPL := superzazu
endif

# z88dk library based
ifeq ($(SPECTRUMOPTION),b)
# requires z88dk RS232 library
SPECTRUMLIBS := \
	-lmzx_tiny \
	-lndos \
	-lrs232if1 \
	-lspectrum/rf \
	-lspectrum/rf_inst \
	-lspectrum/rf_system \
	-lspectrum/rf_z80
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 32768
# ORIGIN higher, 0x9500, C code is larger as uses z88dk libs
SPECTRUMORIGIN := 38144
# C impl of system dependent code uses z88dk libs
SPECTRUMSYSTEM := target/spectrum/system.c
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# no CPU hook for z88dk RS232 code so use Fuse
SPECTRUMIMPL := fuse
endif

# z88dk / pure C based
ifeq ($(SPECTRUMOPTION),c)
# requires z88dk RS232 library
SPECTRUMLIBS := \
	-lmzx_tiny \
	-lndos \
	-lrs232if1 \
	-lspectrum/rf \
	-lspectrum/rf_inst \
	-lspectrum/rf_system
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 32768
# ORIGIN higher, 0x9EFC, C code is larger as uses z88dk libs and pure C impl
SPECTRUMORIGIN := 40700
# C impl of system dependent code uses z88dk libs
SPECTRUMSYSTEM := target/spectrum/system.c
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# no CPU hook for z88dk RS232 code so use Fuse
SPECTRUMIMPL := fuse
endif

# run Spectrum build
.PHONY : spectrum-run
ifeq ($(SPECTRUMIMPL),fuse)
spectrum-run : spectrum-run-fuse
endif
ifeq ($(SPECTRUMIMPL),mame)
spectrum-run : spectrum-run-mame
endif
ifeq ($(SPECTRUMIMPL),superzazu)
# default is to use fast build but run in Fuse
spectrum-run : spectrum-run-fuse
endif

# run Fuse emulator, load TAP, connect disc
.PHONY : spectrum-run-fuse
spectrum-run-fuse : spectrum-fuse-tap | spectrum-fuse-disc

# run Mame emulator, load TAP
.PHONY: spectrum-run-mame
spectrum-run-mame : spectrum/orterforth.tap

	# serve disc
	bash scripts/tcp-redirect.sh 127.0.0.1 5705 $(DISC) standard 0.disc 1.disc &

	@echo '1. Press Enter to skip the warning'
	@echo '2. Start the tape via F2 or the Tape Control menu'
	@mame spectrum -video opengl \
		-exp intf1 \
		-exp:intf1:rs232 null_modem \
		-bitb socket.localhost:5705 \
		-window -skip_gameinfo \
		-autoboot_delay 5 \
		-autoboot_command 'j""\n' \
		-cassette $<

.PHONY : spectrum-test
spectrum-test : spectrum/test.tap | roms/spectrum/if1-2.rom

	$(FUSE) \
		--speed=100 \
		--machine 48 \
		--graphics-filter 2x \
		--interface1 \
		--rom-interface-1 roms/spectrum/if1-2.rom \
		$<

# other Spectrum libs
spectrum/%.lib : %.c | spectrum

	zcc +zx -x -o spectrum/$* $<

# Fuse serial named pipe
spectrum/fuse-rs232-rx : | spectrum

	mkfifo $@

# Fuse serial named pipe
spectrum/fuse-rs232-tx : | spectrum

	mkfifo $@

# inst executable
spectrum/orterforth-inst.bin : \
	spectrum/rf.lib \
	spectrum/rf_inst.lib \
	spectrum/rf_system.lib \
	spectrum/rf_z80.lib \
	rf_z80_memory.asm \
	orterforth.c

	zcc +zx \
		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-Ca-DRF_ORG=$(SPECTRUMORG) \
		-Ca-DRF_INST_OFFSET=$(SPECTRUMINSTOFFSET) \
		$(SPECTRUMLIBS) \
		-pragma-define:CRT_ENABLE_STDIO=0 \
		-pragma-define:CRT_INITIALIZE_BSS=0 \
		-m \
		-o $@ \
		rf_z80_memory.asm orterforth.c

# start with an empty bin file to build the multi segment bin
spectrum/orterforth-inst-0.bin : | spectrum

	z88dk-appmake +rom \
		-s $(SPECTRUMORG) \
		-f 0 \
		-o $@

# add main code at start
spectrum/orterforth-inst-1.bin : \
	spectrum/orterforth-inst-0.bin \
	spectrum/orterforth-inst.bin

	z88dk-appmake +inject \
		-b spectrum/orterforth-inst-0.bin \
		-i spectrum/orterforth-inst.bin \
		-s 0 \
		-o $@

# add inst code at offset, safely beyond dictionary
spectrum/orterforth-inst-2.bin : \
	spectrum/orterforth-inst-1.bin \
	spectrum/orterforth-inst_INST.bin

	z88dk-appmake +inject \
		-b spectrum/orterforth-inst-1.bin \
		-i spectrum/orterforth-inst_INST.bin \
		-s $(SPECTRUMINSTOFFSET) \
		-o $@

# make inst serial load file from inst bin
spectrum/orterforth-inst-2.ser : spectrum/orterforth-inst-2.bin | $(ORTER)

	$(ORTER) spectrum header $< 3 32768 0 > $@

# make inst tap from inst bin
spectrum/orterforth-inst-2.tap : spectrum/orterforth-inst-2.bin

	z88dk-appmake +zx \
		-b $< \
		--org $(SPECTRUMORG) \
		-o $@

# both main and INST bin files are built by same command
spectrum/orterforth-inst_INST.bin : spectrum/orterforth-inst.bin

# final bin from the hex output by inst
spectrum/orterforth.bin : spectrum/orterforth.bin.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# run inst which writes hex file to disc 01
ifeq ($(SPECTRUMIMPL),fuse)
SPECTRUMINSTDEPS := spectrum/orterforth-inst-2.tap $(DISC) $(ORTER) $(FUSE) roms/spectrum/if1-2.rom spectrum/fuse-rs232-rx spectrum/fuse-rs232-tx
endif
ifeq ($(SPECTRUMIMPL),superzazu)
SPECTRUMINSTDEPS := spectrum/orterforth-inst-2.tap $(SYSTEM)/emulate_spectrum roms/spectrum/if1-2.rom roms/spectrum/spectrum.rom
endif
ifeq ($(SPECTRUMIMPL),real)
SPECTRUMINSTDEPS := spectrum/orterforth-inst-2.ser $(DISC) $(ORTER)
endif

spectrum/orterforth.bin.hex : orterforth.disc $(SPECTRUMINSTDEPS)

	# empty disc in drive 1 for hex installed file
	rm -f $@.io
	touch $@.io

ifeq ($(SPECTRUMIMPL),fuse)
	# start disc
	$(ORTER) fuse serial read \
		< spectrum/fuse-rs232-tx \
		| $(DISC) standard orterforth.disc $@.io \
		| $(ORTER) fuse serial write \
		> spectrum/fuse-rs232-rx &

	# start Fuse, install, stop Fuse
	sh scripts/fuse-start.sh \
		--speed=5000 \
		--machine 48 \
		--interface1 \
		--rom-interface-1 roms/spectrum/if1-2.rom \
		--rs232-rx spectrum/fuse-rs232-rx \
		--rs232-tx spectrum/fuse-rs232-tx \
		spectrum/orterforth-inst-2.tap
	sh scripts/waitforhex $@.io
	sh scripts/fuse-stop.sh

endif

ifeq ($(SPECTRUMIMPL),superzazu)
	# run emulator with hooks to handle I/O and to terminate when finished
	./$(SYSTEM)/emulate_spectrum
endif

ifeq ($(SPECTRUMIMPL),real)
	@echo "On the Spectrum type: FORMAT \"b\";$(SERIALBAUD)"
	@echo "                      LOAD *\"b\""
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial write -w 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas

	@echo "* Loading inst..."
	@$(ORTER) serial write -w 22 $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth-inst-2.ser

	@echo "* Starting disc and waiting for completion..."
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) orterforth.disc $@.io & pid=$$! ; \
		scripts/waitforhex $@.io ; \
		kill -9 $$pid
endif

	# read hex from disc 1 blocks and write to file
	mv $@.io $@

# make serial load file from bin
spectrum/orterforth.ser : spectrum/orterforth.bin | $(ORTER)

	$(ORTER) spectrum header $< 3 32768 0 > $@

# final tap from bin
spectrum/orterforth.tap : spectrum/orterforth.bin

	z88dk-appmake +zx \
		-b spectrum/orterforth.bin \
		--org $(SPECTRUMORG) \
		-o spectrum/orterforth.tap

# base orterforth code
spectrum/rf.lib : rf.c rf.h | spectrum

	zcc +zx \
		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$<

# inst code, which is located to be overwritten when complete
spectrum/rf_inst.lib : rf_inst.c rf.h | spectrum

	zcc +zx \
		-DRF_ORG=$(SPECTRUMORG) \
		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$< \
		--codeseg=INST --dataseg=INST --bssseg=INST --constseg=INST

# system code, which may be C or assembler
spectrum/rf_system.lib : $(SPECTRUMSYSTEM) | spectrum

	zcc +zx \
		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$<

# Z80 assembly optimised code
spectrum/rf_z80.lib : rf_z80.asm | spectrum

	zcc +zx \
		-Ca-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$<

# test tap
spectrum/test.tap : \
	spectrum/rf.lib \
	test.c

	zcc +zx \
		-lndos \
		-lspectrum/rf \
		-create-app \
		-o spectrum/test.bin \
		test.c

.PHONY : test
test : $(SYSTEM)/test

	$(SYSTEM)/test
