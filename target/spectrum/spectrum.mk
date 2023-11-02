# === ZX Spectrum ===

# configure Fuse Emulator
FUSEOPTS := \
	--auto-load \
	--graphics-filter 2x \
	--interface1 \
	--machine 48 \
	--no-autosave-settings \
	--no-confirm-actions \
	--phantom-typist-mode keyword \
	--rs232-rx spectrum/fuse-rs232-rx \
	--rs232-tx spectrum/fuse-rs232-tx
# default inst time emulator
SPECTRUMINSTMACHINE := fuse
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# library files as dependencies
SPECTRUMDEPS := \
	spectrum/inst.lib \
	spectrum/system.lib
# command line linked libraries
SPECTRUMLIBS := \
	-lmzx_tiny \
	-lndos \
	-lspectrum/inst \
	-lspectrum/system
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 0x8000
# ROM files for emulator
SPECTRUMROMS := \
	roms/spectrum/if1-2.rom \
	roms/spectrum/spectrum.rom
# C impl of system dependent code uses z88dk libs
SPECTRUMSYSTEM := target/spectrum/system.c

SPECTRUMZCCOPTS := +zx \
		-DRF_TARGET_INC='\"target/spectrum/spectrum.inc\"' \
		-Ca-DSPECTRUM \
		-Ca-DRF_INST_OFFSET=$(SPECTRUMINSTOFFSET) \
		-Ca-DRF_ORG=$(SPECTRUMORG) \
		-DRF_ORG=$(SPECTRUMORG)

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

# locate Fuse Emulator
ifeq ($(OPER),cygwin)
FUSE := "/cygdrive/c/Program Files/Fuse/fuse.exe"
else
FUSE := $(shell which fuse)
endif

# config option
SPECTRUMOPTION := assembly
# SPECTRUMOPTION := assembly-z88dk
# SPECTRUMOPTION := default
ifeq ($(TARGET),spectrum)
ifneq ($(OPTION),)
SPECTRUMOPTION := $(OPTION)
endif
endif

# minimal ROM-based:
# use ROM routines including Interface 1 ROM for RS232
ifeq ($(SPECTRUMOPTION),assembly)
SPECTRUMDEPS += spectrum/rf_z80.lib
SPECTRUMLIBS += -lspectrum/rf_z80
SPECTRUMORIGIN := 0x8700
SPECTRUMSYSTEM := target/spectrum/system.asm
# superzazu emulator is minimal and launches no GUI
# it can only be used if RS232 ROM calls are used
SPECTRUMINSTMACHINE := superzazu
SPECTRUMZCCOPTS += -DRF_ASSEMBLY -pragma-redirect:fputc_cons=fputc_cons_rom_rst
endif

# z88dk library based
ifeq ($(SPECTRUMOPTION),assembly-z88dk)
SPECTRUMDEPS += spectrum/rf_z80.lib
SPECTRUMLIBS += -lspectrum/rf_z80 -lrs232if1
SPECTRUMORIGIN := 0x9080
SPECTRUMZCCOPTS += -DRF_ASSEMBLY -DRF_ASSEMBLY_Z88DK
endif

# z88dk / pure C based
ifeq ($(SPECTRUMOPTION),default)
SPECTRUMDEPS += spectrum/rf.lib
SPECTRUMLIBS += -lspectrum/rf -lrs232if1
SPECTRUMORIGIN := 0x9C00
endif

SPECTRUMZCCOPTS += \
	-Ca-DRF_ORIGIN=$(SPECTRUMORIGIN) \
	-DRF_ORIGIN=$(SPECTRUMORIGIN)

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
SPECTRUMSTARTDISC := \
	$(STARTDISCMSG) && \
	sh scripts/start.sh tx rx disc.pid $(DISC)
endif
ifeq ($(SPECTRUMMACHINE),mame)
SPECTRUMRUNDEPS := \
	spectrum/orterforth.tap \
	$(DR0) \
	$(DR1) | \
	$(DISC) \
	$(SPECTRUMROMS)
SPECTRUMSTARTDISC := $(STARTDISCTCP)
endif
ifeq ($(SPECTRUMMACHINE),real)
SPECTRUMRUNDEPS := \
	spectrum/orterforth.ser \
	target/spectrum/load-serial.bas \
	$(DR0) \
	$(DR1) | \
	$(DISC) \
	$(ORTER)
# run and wait rather than start
SPECTRUMSTARTDISC := \
	$(STARTDISCMSG) && \
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD)
endif

.PHONY : spectrum-hw
spectrum-hw : spectrum/hw.tap

	$(FUSE) $(FUSEOPTS) --tape $<

.PHONY : spectrum-run
spectrum-run : $(SPECTRUMRUNDEPS) $(DR0) $(DR1)

ifeq ($(SPECTRUMMACHINE),real)
	@$(PROMPT) 'On the Spectrum type:\n  FORMAT "b";$(SERIALBAUD) <enter>\n  LOAD *"b" <enter>'

	@$(INFO) 'Loading loader'
	@$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas

	@$(INFO) 'Loading orterforth'
	@$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth.ser
endif

	@$(SPECTRUMSTARTDISC) $(DR0) $(DR1)

ifeq ($(SPECTRUMMACHINE),fuse)
	@$(INFO) 'Running Fuse'
	@$(ORTER) spectrum fuse serial read  > tx < spectrum/fuse-rs232-tx &
	@$(ORTER) spectrum fuse serial write < rx > spectrum/fuse-rs232-rx &
	@$(FUSE) $(FUSEOPTS) --speed=100 --tape $<
endif
ifeq ($(SPECTRUMMACHINE),mame)
	@$(INFO) 'Running MAME'
	@$(WARN) ' 1. Press Enter to skip the warning'
	@$(WARN) ' 2. Scroll Lock or Delete to enable UI controls'
	@$(WARN) ' 3. Start the tape via F2 or the Tape Control menu'
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

# serial load file from binary
spectrum/%.ser : spectrum/%.bin | $(ORTER)

	$(ORTER) spectrum header $< 3 32768 0 > $@

# tap file from binary
spectrum/%.tap : spectrum/%.bin

	z88dk-appmake +zx -b $< --org $(SPECTRUMORG) -o $@

# Fuse serial named pipe
spectrum/fuse-rs232-% : | spectrum

	mkfifo $@

spectrum/hw.tap : hw.c

	zcc +zx -lndos -create-app -o spectrum/hw.bin $<

# inst executable
spectrum/inst.bin spectrum/inst_INST.bin : \
	$(SPECTRUMDEPS) \
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

# 1. start with an empty bin file to build the multi segment bin
spectrum/inst-0.bin : | spectrum

	z88dk-appmake +rom -s $(SPECTRUMORG) -f 0 -o $@

# 2. add main code at start
spectrum/inst-1.bin : spectrum/inst-0.bin spectrum/inst.bin

	z88dk-appmake +inject -b $< -i spectrum/inst.bin -s 0 -o $@

# 3. add inst code at offset, safely beyond dictionary
spectrum/inst-2.bin : spectrum/inst-1.bin spectrum/inst_INST.bin

	z88dk-appmake +inject -b $< -i spectrum/inst_INST.bin -s $(SPECTRUMINSTOFFSET) -o $@

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
SPECTRUMSTARTINSTMACHINE := \
		$(INFO) 'Starting Fuse' ; \
		$(ORTER) spectrum fuse serial read  > tx < spectrum/fuse-rs232-tx & \
		$(ORTER) spectrum fuse serial write < rx > spectrum/fuse-rs232-rx & \
		$(START) fuse.pid $(FUSE) $(FUSEOPTS) --speed=200 --tape spectrum/inst-2.tap
SPECTRUMSTOPINSTMACHINE := $(INFO) 'Stopping Fuse' ; sh scripts/stop.sh fuse.pid
endif
ifeq ($(SPECTRUMINSTMACHINE),real)
SPECTRUMINSTDEPS := \
	spectrum/inst-2.ser | \
	$(DISC) \
	$(ORTER)
SPECTRUMSTARTINSTMACHINE := \
	$(PROMPT) 'On the Spectrum type:\n  FORMAT "b";$(SERIALBAUD) <enter>\n  LOAD *"b" <enter>' ; \
	$(INFO) 'Loading loader' ; \
	$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas ; \
	$(INFO) 'Loading inst' ; \
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < spectrum/inst-2.ser ; \
	$(WARN) 'NB Unfortunately this usually fails due to Spectrum RS232 unreliability'
SPECTRUMSTOPINSTMACHINE := :
endif
ifeq ($(SPECTRUMINSTMACHINE),superzazu)
SPECTRUMINSTDEPS := \
	spectrum/inst-2.tap | \
	$(SYSTEM)/emulate_spectrum \
	$(SPECTRUMROMS)
SPECTRUMSTARTINSTMACHINE := \
	$(INFO) 'Running headless emulator' ; \
	./$(SYSTEM)/emulate_spectrum
SPECTRUMSTOPINSTMACHINE := :
endif

spectrum/orterforth.bin.hex : model.img $(SPECTRUMINSTDEPS)

	@$(CHECKMEMORY) $(SPECTRUMORG) $(SPECTRUMORIGIN) $$($(STAT) spectrum/inst.bin)

	@$(EMPTYDR1FILE) $@.io

	@$(SPECTRUMSTARTINSTMACHINE)

ifneq ($(SPECTRUMINSTMACHINE),superzazu)
	@$(SPECTRUMSTARTDISC) model.img $@.io

	@$(WAITUNTILSAVED) $@.io

	@$(SPECTRUMSTOPINSTMACHINE)

	@$(STOPDISC)
endif

	@$(COMPLETEDR1FILE)

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
