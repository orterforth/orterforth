# === ZX Spectrum ===

FUSEOPTS := \
	--auto-load \
	--graphics-filter 2x \
	--interface1 \
	--machine 48 \
	--no-confirm-actions \
	--phantom-typist-mode keyword \
	--rs232-rx spectrum/fuse-rs232-rx \
	--rs232-tx spectrum/fuse-rs232-tx
# include file
SPECTRUMINC := target/spectrum/spectrum.inc
# default inst time emulator
SPECTRUMINSTMACHINE := fuse
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# command line linked libraries
SPECTRUMLIBS := \
	-lmzx_tiny \
	-lndos \
	-lspectrum/inst \
	-lspectrum/rf \
	-lspectrum/system
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 0x8000
# ROM files for emulator
SPECTRUMROMS := \
	roms/spectrum/if1-2.rom \
	roms/spectrum/spectrum.rom
# C impl of system dependent code uses z88dk libs
SPECTRUMSYSTEM := target/spectrum/system.c

# emulator to build fast
$(SYSTEM)/emulate_spectrum : \
	$(SYSTEM)/emulate_spectrum.o \
	$(SYSTEM)/persci.o \
	$(SYSTEM)/z80.o

	$(CC) -o $@ $^

# spectrum emulator
$(SYSTEM)/emulate_spectrum.o : \
	target/spectrum/emulate.c \
	persci.h \
	tools/github.com/superzazu/z80/z80.h | \
	$(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

# https://github.com/superzazu/z80.git
$(SYSTEM)/z80.o : \
	tools/github.com/superzazu/z80/z80.c \
	tools/github.com/superzazu/z80/z80.h | \
	$(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

# ROM files dir
roms/spectrum : | roms

	mkdir $@

# ROM files
roms/spectrum/% : | roms/spectrum

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

spectrum :

	mkdir $@

.PHONY : spectrum-build
spectrum-build : spectrum/orterforth.ser spectrum/orterforth.tap

.PHONY : spectrum-clean
spectrum-clean :

	rm -rf spectrum/*

# locate Fuse Emulator
ifeq ($(OPER),cygwin)
FUSE := "/cygdrive/c/Program Files/Fuse/fuse.exe"
else
FUSE := $(shell which fuse)
endif

# config option
ifeq ($(TARGET),spectrum)
SPECTRUMOPTION := $(OPTION)
else
SPECTRUMOPTION := assembly
# SPECTRUMOPTION := assembly-z88dk
# SPECTRUMOPTION := default
endif

# minimal ROM-based
ifeq ($(SPECTRUMOPTION),assembly)
# uses Interface 1 ROM for RS232
# TODO pragma not in libs
SPECTRUMLIBS += -lspectrum/rf_z80 -pragma-redirect:fputc_cons=fputc_cons_rom_rst
# ORIGIN
SPECTRUMORIGIN := 0x87C0
# assembly system dependent code uses ROM routines
SPECTRUMSYSTEM := target/spectrum/system.asm
# superzazu emulator is minimal and launches no GUI
# it can only be used if RS232 ROM calls are used
SPECTRUMINSTMACHINE := superzazu
endif

# z88dk library based
ifeq ($(SPECTRUMOPTION),assembly-z88dk)
# requires z88dk RS232 library
SPECTRUMLIBS += -lspectrum/rf_z80 -lrs232if1
# ORIGIN higher, C code is larger as uses z88dk libs
SPECTRUMORIGIN := 0x9080
endif

# z88dk / pure C based
ifeq ($(SPECTRUMOPTION),default)
# requires z88dk RS232 library
SPECTRUMLIBS += -lrs232if1
# ORIGIN higher, C code is larger as uses z88dk libs and pure C impl
SPECTRUMORIGIN := 0x9B80
endif

# superzazu fast partial emulator can't be used for run time
SPECTRUMMACHINE := $(SPECTRUMINSTMACHINE)
ifeq ($(SPECTRUMMACHINE),superzazu)
SPECTRUMMACHINE := fuse
endif

ifeq ($(SPECTRUMMACHINE),fuse)
# assume ROMS are available to Fuse
SPECTRUMROMS :=
SPECTRUMRUNDEPS := \
	spectrum/orterforth.tap \
	$(DR0) \
	$(DR1) | \
	$(DISC) \
	spectrum/fuse-rs232-rx \
	spectrum/fuse-rs232-tx \
	rx \
	tx
endif
ifeq ($(SPECTRUMMACHINE),mame)
SPECTRUMRUNDEPS := \
	spectrum/orterforth.tap \
	$(DR0) \
	$(DR1) | \
	$(DISC) \
	$(SPECTRUMROMS)
endif
ifeq ($(SPECTRUMMACHINE),real)
SPECTRUMRUNDEPS := \
	spectrum/orterforth.ser \
	target/spectrum/load-serial.bas \
	$(DR0) \
	$(DR1) | \
	$(DISC) \
	$(ORTER)
endif

# start disc
ifeq ($(SPECTRUMMACHINE),fuse)
SPECTRUMSTARTDISC := \
	$(STARTDISCMSG) ; \
	sh scripts/start.sh tx rx disc.pid $(DISC)
endif
ifeq ($(SPECTRUMMACHINE),mame)
SPECTRUMSTARTDISC := $(STARTDISCTCP)
endif
ifeq ($(SPECTRUMMACHINE),real)
# run and wait rather than start
SPECTRUMSTARTDISC := \
	$(STARTDISCMSG) ; \
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD)
endif

.PHONY : spectrum-hw
spectrum-hw : spectrum/hw.tap

	$(FUSE) $(FUSEOPTS) --tape $<

.PHONY : spectrum-run
spectrum-run : $(SPECTRUMRUNDEPS) $(DR0) $(DR1)

ifeq ($(SPECTRUMMACHINE),real)
	@printf '* \035[1;35mOn the Spectrum type:\035[0;0m\n'
	@printf '  FORMAT "b";$(SERIALBAUD) <enter>\n'
	@printf '  LOAD *"b" <enter>\n'
	@read -p '  then press enter to start: ' LINE

	@printf '* \033[1;33mLoading loader\033[0;0m\n'
	$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas

	@printf '* \033[1;33mLoading orterforth\033[0;0m\n'
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth.ser
endif

	@$(SPECTRUMSTARTDISC) $(DR0) $(DR1)

ifeq ($(SPECTRUMMACHINE),fuse)
	@printf '* \033[1;33mRunning Fuse\033[0;0m\n'
	@$(ORTER) spectrum fuse serial read  > tx < spectrum/fuse-rs232-tx &
	@$(ORTER) spectrum fuse serial write < rx > spectrum/fuse-rs232-rx &
	@$(FUSE) $(FUSEOPTS) --speed=100 --tape $<
endif
ifeq ($(SPECTRUMMACHINE),mame)
	@printf '* \033[1;33mRunning MAME\033[0;0m\n'
	@printf '  \033[1;35m1. Press Enter to skip the warning\033[0;0m\n'
	@printf '  \033[1;35m2. Scroll Lock or Delete to enable UI controls\033[0;0m\n'
	@printf '  \033[1;35m3. Start the tape via F2 or the Tape Control menu\033[0;0m\n'
	@mame spectrum $(MAMEOPTS) \
		-exp intf1 \
		-exp:intf1:rs232 null_modem \
		-bitb socket.localhost:5705 \
		-autoboot_delay 5 \
		-autoboot_command 'j""\n' \
		-cassette $<
endif

ifneq ($(SPECTRUMMACHINE),real)
	@$(STOPDISC)
endif

# Fuse serial named pipe
spectrum/fuse-rs232-rx : | spectrum

	mkfifo $@

# Fuse serial named pipe
spectrum/fuse-rs232-tx : | spectrum

	mkfifo $@

SPECTRUMZCCOPTS := +zx \
		-Ca-DRF_INST_OFFSET=$(SPECTRUMINSTOFFSET) \
		-Ca-DRF_ORG=$(SPECTRUMORG) \
		-Ca-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-Ca-DSPECTRUM \
		-DRF_ORG=$(SPECTRUMORG) \
		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-DRF_TARGET_INC='\"$(SPECTRUMINC)\"'

ifeq ($(SPECTRUMOPTION),assembly)
SPECTRUMZCCOPTS += -DRF_ASSEMBLY
endif
ifeq ($(SPECTRUMOPTION),assembly-z88dk)
SPECTRUMZCCOPTS += -DRF_ASSEMBLY
endif

spectrum/hw.tap : hw.c

	zcc +zx -lndos -create-app -o spectrum/hw.bin $<

# inst executable
spectrum/inst.bin : \
	spectrum/inst.lib \
	spectrum/rf.lib \
	spectrum/rf_z80.lib \
	spectrum/system.lib \
	z80_memory.asm \
	main.c

	zcc $(SPECTRUMZCCOPTS) $(SPECTRUMLIBS) \
		-pragma-define:CRT_ENABLE_STDIO=0 \
		-pragma-define:CRT_INITIALIZE_BSS=0 \
		-m \
		-o $@ \
		z80_memory.asm main.c

# inst code, which is located to be overwritten when complete
spectrum/inst.lib : inst.c rf.h | spectrum

	zcc $(SPECTRUMZCCOPTS) -x -o $@ $< \
		--codeseg=INST --dataseg=INST --bssseg=INST --constseg=INST

# start with an empty bin file to build the multi segment bin
spectrum/inst-0.bin : | spectrum

	z88dk-appmake +rom \
		-s $(SPECTRUMORG) \
		-f 0 \
		-o $@

# add main code at start
spectrum/inst-1.bin : \
	spectrum/inst-0.bin \
	spectrum/inst.bin

	z88dk-appmake +inject \
		-b spectrum/inst-0.bin \
		-i spectrum/inst.bin \
		-s 0 \
		-o $@

# add inst code at offset, safely beyond dictionary
spectrum/inst-2.bin : \
	spectrum/inst-1.bin \
	spectrum/inst_INST.bin

	z88dk-appmake +inject \
		-b spectrum/inst-1.bin \
		-i spectrum/inst_INST.bin \
		-s $(SPECTRUMINSTOFFSET) \
		-o $@
	# cat $< > $@.io
	# head -c 32768 /dev/null >> $@.io
	# head -c $(SPECTRUMINSTOFFSET) $@.io > $@
	# cat spectrum/inst_INST.bin >> $@

# make inst serial load file from inst bin
spectrum/inst-2.ser : spectrum/inst-2.bin | $(ORTER)

	$(ORTER) spectrum header $< 3 32768 0 > $@

# make inst tap from inst bin
spectrum/inst-2.tap : spectrum/inst-2.bin

	z88dk-appmake +zx \
		-b $< \
		--org $(SPECTRUMORG) \
		-o $@

# both main and INST bin files are built by same command
spectrum/inst_INST.bin : spectrum/inst.bin

# final bin from the hex output by inst
spectrum/orterforth.bin : spectrum/orterforth.bin.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# run inst which writes hex file to disc 01
ifeq ($(SPECTRUMINSTMACHINE),fuse)
SPECTRUMINSTDEPS := \
	spectrum/inst-2.tap | \
	$(DISC) \
	$(ORTER) \
	spectrum/fuse-rs232-rx \
	spectrum/fuse-rs232-tx \
	rx \
	tx
endif
ifeq ($(SPECTRUMINSTMACHINE),real)
SPECTRUMINSTDEPS := \
	spectrum/inst-2.ser | \
	$(DISC) \
	$(ORTER)
endif
ifeq ($(SPECTRUMINSTMACHINE),superzazu)
SPECTRUMINSTDEPS := \
	spectrum/inst-2.tap | \
	$(SYSTEM)/emulate_spectrum \
	$(SPECTRUMROMS)
endif

spectrum/orterforth.bin.hex : model.img $(SPECTRUMINSTDEPS)

# validate memory limits
	@$(CHECKMEMORY) $(SPECTRUMORG) $(SPECTRUMORIGIN) $(shell $(STAT) spectrum/inst.bin)

# empty DR1
	@printf '* \033[1;33mClearing DR1\033[0;0m\n'
	@rm -f $@.io
	@touch $@.io

# start machine
ifeq ($(SPECTRUMINSTMACHINE),fuse)
	@printf '* \033[1;33mStarting Fuse\033[0;0m\n'
	@$(ORTER) spectrum fuse serial read  > tx < spectrum/fuse-rs232-tx &
	@$(ORTER) spectrum fuse serial write < rx > spectrum/fuse-rs232-rx &
	@$(START) fuse.pid $(FUSE) $(FUSEOPTS) --speed=200 --tape spectrum/inst-2.tap
endif
ifeq ($(SPECTRUMINSTMACHINE),superzazu)
	@printf '* \033[1;33mRunning headless emulator\033[0;0m\n'
	@./$(SYSTEM)/emulate_spectrum
endif

# load inst
ifeq ($(SPECTRUMINSTMACHINE),real)
	@printf '* \033[1;35mOn the Spectrum type:\033[0;0m\n'
	@printf '  FORMAT "b";$(SERIALBAUD) <enter>\n'
	@printf '  LOAD *"b" <enter>\n'
	@read -p '  then press enter to start: ' LINE

	@printf '* \033[1;33mLoading loader\033[0;0m\n'
	@# TODO load-serial could send ACK and we could use -a
	@$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas
	@printf '* \033[1;33mLoading inst\033[0;0m\n'
	@$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < spectrum/inst-2.ser
endif

# start disc
ifneq ($(SPECTRUMINSTMACHINE),superzazu)
	@$(SPECTRUMSTARTDISC) model.img $@.io
endif
ifeq ($(SPECTRUMINSTMACHINE),real)
	@printf '  \033[1;35mNB Unfortunately this usually fails due to Spectrum RS232 unreliability\033[0;0m\n'
endif

# wait for save
ifneq ($(SPECTRUMINSTMACHINE),superzazu)
	@$(WAITUNTILSAVED) $@.io
endif

# stop machine
ifeq ($(SPECTRUMINSTMACHINE),fuse)
	@printf '* \033[1;33mStopping Fuse\033[0;0m\n'
	@sh scripts/stop.sh fuse.pid
endif

# stop disc
ifneq ($(SPECTRUMINSTMACHINE),superzazu)
	@$(STOPDISC)
endif

# done
	@printf '* \033[1;33mDone\033[0;0m\n'
	@mv $@.io $@

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

	zcc $(SPECTRUMZCCOPTS) -x -o $@ $<

# Z80 assembly optimised code
spectrum/rf_z80.lib : rf_z80.asm | spectrum

	zcc $(SPECTRUMZCCOPTS) -x -o $@ $<

# system code, which may be C or assembler
spectrum/system.lib : $(SPECTRUMSYSTEM) | spectrum

	zcc $(SPECTRUMZCCOPTS) -x -o $@ $<

tools/github.com/superzazu/z80/z80.c tools/github.com/superzazu/z80/z80.h :

	git submodule update --init tools/github.com/superzazu/z80
