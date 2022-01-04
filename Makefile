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
ifeq ($(UNAME_M),x86_64)
endif
ifneq ($(filter %86,$(UNAME_M)),)
endif
ifneq ($(filter arm%,$(UNAME_M)),)
endif
# do not use ARCH
# https://stackoverflow.com/questions/12763296/os-x-arch-command-incorrect
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

# === LOCAL SYSTEM ===

# orter - retrocomputing multitool
$(ORTER) : \
	$(SYSTEM)/orter_fuse.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_spectrum.o \
	orter.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

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

	@cp -p orterforth.disc 0.disc
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

# other libs
$(SYSTEM)/%.o : %.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# emulator to build fast
$(SYSTEM)/spectrum : \
	$(SYSTEM)/spectrum.o \
	$(SYSTEM)/z80.o \
	$(SYSTEM)/rf_persci.o

	$(CC) -o $@ $^

# spectrum emulator
$(SYSTEM)/spectrum.o : spectrum.c rf_persci.h z80.h | $(SYSTEM)

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

# disc images from %.f files including orterforth.f
%.disc : %.f | $(DISC)

	$(DISC) create <$< >$@

# build
.PHONY : build
build : $(TARGET)-build

# build all
.PHONY : build-all
build-all : $(SYSTEM)-build spectrum-build

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
.PHONY : spectrum-load-serial
spectrum-load-serial : spectrum/orterforth.ser spectrum-load-serial.bas

	@echo "On the Spectrum type: FORMAT \"b\";$(SERIALBAUD)"
	@echo "                      LOAD *\"b\""
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial write -w 2 $(SERIALPORT) $(SERIALBAUD) < spectrum-load-serial.bas

	@echo "* Loading orterforth..."
	@$(ORTER) serial write -w 15 $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth.ser

	@echo "* Starting disc..."
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) 0.disc 1.disc

# config option
SPECTRUMCONFIG := a

# minimal ROM-based
ifeq ($(SPECTRUMCONFIG),a)
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
SPECTRUMSYSTEM := target/spectrum.asm
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# superzazu emulator is minimal and launches no GUI
SPECTRUMIMPL := superzazu
endif

# z88dk library based
ifeq ($(SPECTRUMCONFIG),b)
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
SPECTRUMSYSTEM := target/spectrum.c
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# no CPU hook for z88dk RS232 code so use Fuse
SPECTRUMIMPL := fuse
endif

# z88dk / pure C based
ifeq ($(SPECTRUMCONFIG),c)
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
# ORIGIN higher, 0x9500, C code is larger as uses z88dk libs
SPECTRUMORIGIN := 40700
# C impl of system dependent code uses z88dk libs
SPECTRUMSYSTEM := target/spectrum.c
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

	@echo '1. Press Enter to skip the warning'
	@echo '2. Start the tape via F2 or the Tape Control menu'
	@mame spectrum \
		-exp intf1 \
		-window -nomaximize -skip_gameinfo \
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
	rf_memory.asm \
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
		rf_memory.asm orterforth.c

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
spectrum/orterforth.bin : spectrum/orterforth.bin.hex $(ORTER)

	$(ORTER) hex read < $< > $@

# run inst which writes hex file to disc 01
ifeq ($(SPECTRUMIMPL),fuse)
SPECTRUMINSTDEPS := spectrum/orterforth-inst-2.tap $(DISC) $(ORTER) $(FUSE) roms/spectrum/if1-2.rom spectrum/fuse-rs232-rx spectrum/fuse-rs232-tx
endif
ifeq ($(SPECTRUMIMPL),superzazu)
SPECTRUMINSTDEPS := spectrum/orterforth-inst-2.tap $(SYSTEM)/spectrum roms/spectrum/if1-2.rom roms/spectrum/spectrum.rom
endif
ifeq ($(SPECTRUMIMPL),real)
SPECTRUMINSTDEPS := spectrum/orterforth-inst-2.ser $(DISC) $(ORTER)
endif

spectrum/orterforth.bin.hex : orterforth.disc $(SPECTRUMINSTDEPS)

	# inst disc in drive 0
	cp -p orterforth.disc 0.disc

	# empty disc in drive 1 for hex installed file
	rm -f 1.disc
	touch 1.disc

ifeq ($(SPECTRUMIMPL),fuse)
	# start disc
	$(ORTER) fuse serial read \
		< spectrum/fuse-rs232-tx \
		| $(DISC) standard 0.disc 1.disc \
		| $(ORTER) fuse serial write \
		> spectrum/fuse-rs232-rx &

	# run Fuse, install, wait, kill Fuse when believed finished
	$(FUSE) \
		--speed=5000 \
		--machine 48 \
		--interface1 \
		--rom-interface-1 roms/spectrum/if1-2.rom \
		--rs232-rx spectrum/fuse-rs232-rx \
		--rs232-tx spectrum/fuse-rs232-tx \
		spectrum/orterforth-inst-2.tap & pid=$$! ; \
		./waitforhex ; \
		kill -9 $$pid
endif

ifeq ($(SPECTRUMIMPL),superzazu)
	# run emulator with hooks to handle I/O and to terminate when finished
	./$(SYSTEM)/spectrum
endif

ifeq ($(SPECTRUMIMPL),real)
	@echo "On the Spectrum type: FORMAT \"b\";$(SERIALBAUD)"
	@echo "                      LOAD *\"b\""
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial write -w 2 $(SERIALPORT) $(SERIALBAUD) < spectrum-load-serial.bas

	@echo "* Loading inst..."
	@$(ORTER) serial write -w 22 $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth-inst-2.ser

	@echo "* Starting disc and waiting for completion..."
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) 0.disc 1.disc & pid=$$! ; \
		./waitforhex ; \
		kill -9 $$pid
endif

	# read hex from disc 1 blocks and write to file
	cp 1.disc $@

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
