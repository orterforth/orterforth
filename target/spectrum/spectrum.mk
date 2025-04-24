# === ZX Spectrum ===

# Fuse Emulator
SPECTRUMFUSEFIFOS := \
	spectrum/fuse-rs232-rx.fifo spectrum/fuse-rs232-tx.fifo
FUSEOPTS := \
	--auto-load \
	--graphics-filter 2x \
	--interface1 \
	--machine 48 \
	--no-autosave-settings \
	--no-confirm-actions \
	--phantom-typist-mode keyword \
	--rs232-rx spectrum/fuse-rs232-rx.fifo \
	--rs232-tx spectrum/fuse-rs232-tx.fifo

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
# real serial load
SPECTRUMLOADSERIAL := \
	$(PROMPT) 'On the Spectrum type:\n  FORMAT "b";$(SERIALBAUD) <enter>\n  LOAD *"b" <enter>' && \
	$(INFO) 'Loading loader' && \
	$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < spectrum/load-serial.bas && \
	$(INFO) 'Loading binary' && \
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < 
# real tape load
SPECTRUMLOADTAPE := \
	$(PROMPT) 'On the Spectrum type:\n  LOAD "" <enter>' && \
	$(INFO) 'Loading' && \
	$(PLAY) 
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 0x8000
# ROM files for emulator
SPECTRUMROMS := \
	roms/spectrum/if1-2.rom \
	roms/spectrum/spectrum.rom
# C impl of system dependent code uses z88dk libs
SPECTRUMSYSTEM := target/spectrum/system.c

SPECTRUMZCCOPTS := +zx \
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
SPECTRUMDEPS += spectrum/io.lib spectrum/rf_z80.lib
SPECTRUMLIBS += -lspectrum/io -lspectrum/rf_z80 -lrs232if1
SPECTRUMORIGIN := 0x9080
SPECTRUMZCCOPTS += -DRF_ASSEMBLY -DRF_ASSEMBLY_Z88DK
endif

# z88dk / pure C based
ifeq ($(SPECTRUMOPTION),default)
SPECTRUMDEPS += spectrum/io.lib spectrum/rf.lib
SPECTRUMLIBS += -lspectrum/io -lspectrum/rf -lrs232if1
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

# SPECTRUMLOADINGMETHOD := serial
SPECTRUMLOADINGMETHOD := tape

ifeq ($(SPECTRUMMACHINE),fuse)
# assume ROMS are available to Fuse
SPECTRUMROMS :=
ifeq ($(SPECTRUMLOADINGMETHOD),serial)
SPECTRUMRUNDEPS := spectrum/orterforth.ser spectrum/load-serial.bas $(DR0) $(DR1) | $(DISC) $(SPECTRUMFUSEFIFOS)
endif
ifeq ($(SPECTRUMLOADINGMETHOD),tape)
SPECTRUMRUNDEPS := spectrum/orterforth.tap $(DR0) $(DR1) | $(DISC) $(SPECTRUMFUSEFIFOS)
endif
SPECTRUMSTARTDISC := $(STARTDISC) serial $$(cat spectrum/ptyname) $(SERIALBAUD)
endif
ifeq ($(SPECTRUMMACHINE),mame)
SPECTRUMRUNDEPS := spectrum/orterforth.tap $(DR0) $(DR1) | $(DISC) $(SPECTRUMROMS)
SPECTRUMSTARTDISC := $(STARTDISCTCP)
endif
ifeq ($(SPECTRUMMACHINE),real)
SPECTRUMRUNDEPS := spectrum/orterforth.ser spectrum/load-serial.bas $(DR0) $(DR1) | $(DISC) $(ORTER)
SPECTRUMSTARTDISC := $(STARTDISC) serial $(SERIALPORT) $(SERIALBAUD)
ifeq ($(SPECTRUMLOADINGMETHOD),tape)
SPECTRUMRUNDEPS := spectrum/orterforth.wav $(DR0) $(DR1) | $(DISC) $(ORTER)
endif
endif

.PHONY : spectrum-hw
spectrum-hw : spectrum/hw.tap

	$(FUSE) $(FUSEOPTS) --tape $<

STARTFUSE    := $(INFO) 'Starting Fuse' && $(START) spectrum/machine.pid $(FUSE) $(FUSEOPTS)
STARTFUSEPTY := sh scripts/start.sh spectrum/fuse-rs232-tx.fifo spectrum/fuse-rs232-rx.fifo spectrum/pty.pid $(ORTER) spectrum fuse serial pty spectrum/pty && \
	sleep 2 && readlink -n spectrum/pty > spectrum/ptyname && rm spectrum/pty
STOPFUSE     := $(INFO) 'Stopping Fuse' ; sh scripts/stop.sh spectrum/machine.pid ; sh scripts/stop.sh spectrum/pty.pid

ifeq ($(SPECTRUMINSTMACHINE),fuse)
ifeq ($(SPECTRUMLOADINGMETHOD),serial)
SPECTRUMINSTDEPS := \
	spectrum/inst-2.ser spectrum/load-serial.bas | \
	$(DISC) \
	$(ORTER) \
	$(SPECTRUMFUSEFIFOS)
SPECTRUMSTARTINSTMACHINE := \
	$(STARTFUSE) --speed=100 && \
	$(STARTFUSEPTY) && \
	$(PROMPT) 'On the Spectrum type:\n  FORMAT "b";$(SERIALBAUD) <enter>\n  LOAD *"b" <enter>' && \
	$(INFO) 'Loading loader' && \
	$(ORTER) serial -e 2 $$(cat spectrum/ptyname) $(SERIALBAUD) < spectrum/load-serial.bas && \
	$(INFO) 'Loading binary' && \
	$(ORTER) serial -a $$(cat spectrum/ptyname) $(SERIALBAUD) < spectrum/inst-2.ser
endif
ifeq ($(SPECTRUMLOADINGMETHOD),tape)
SPECTRUMINSTDEPS := \
	spectrum/inst-2.tap | \
	$(DISC) \
	$(ORTER) \
	$(SPECTRUMFUSEFIFOS)
SPECTRUMSTARTINSTMACHINE := \
	$(STARTFUSE) --speed=200 --tape spectrum/inst-2.tap && \
	$(STARTFUSEPTY)
endif
SPECTRUMSTOPINSTMACHINE := $(STOPFUSE)
endif

ifeq ($(SPECTRUMINSTMACHINE),real)
ifeq ($(SPECTRUMLOADINGMETHOD),serial)
SPECTRUMINSTDEPS := spectrum/inst-2.ser | $(DISC) $(ORTER)
SPECTRUMSTARTINSTMACHINE := $(SPECTRUMLOADSERIAL) spectrum/inst-2.ser
endif
ifeq ($(SPECTRUMLOADINGMETHOD),tape)
SPECTRUMINSTDEPS := spectrum/inst-2.wav | $(DISC) $(ORTER)
SPECTRUMSTARTINSTMACHINE := $(SPECTRUMLOADTAPE) spectrum/inst-2.wav
endif
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

.PHONY : spectrum-run
spectrum-run : $(SPECTRUMRUNDEPS) $(DR0) $(DR1)

ifeq ($(SPECTRUMMACHINE),real)
ifeq ($(SPECTRUMLOADINGMETHOD),serial)
	@$(SPECTRUMLOADSERIAL) spectrum/orterforth.ser
endif
ifeq ($(SPECTRUMLOADINGMETHOD),tape)
	@$(SPECTRUMLOADTAPE) spectrum/orterforth.wav
endif
	@$(SPECTRUMSTARTDISC) $(DR0) $(DR1)
endif
ifeq ($(SPECTRUMMACHINE),fuse)
ifeq ($(SPECTRUMLOADINGMETHOD),serial)
	@$(STARTFUSE) --speed=100
	@$(STARTFUSEPTY)
	@$(PROMPT) 'On the Spectrum type:\n  FORMAT "b";$(SERIALBAUD) <enter>\n  LOAD *"b" <enter>'
	@$(INFO) 'Loading loader'
	@$(ORTER) serial -e 2 $$(cat spectrum/ptyname) $(SERIALBAUD) < spectrum/load-serial.bas
	@$(INFO) 'Loading binary'
	@$(ORTER) serial -a $$(cat spectrum/ptyname) $(SERIALBAUD) < spectrum/orterforth.ser
endif
ifeq ($(SPECTRUMLOADINGMETHOD),tape)
	@$(STARTFUSE) --speed=100 --tape $<
	@$(STARTFUSEPTY)
endif
	@$(STARTDISC) serial $$(cat spectrum/ptyname) $(SERIALBAUD) $(DR0) $(DR1)
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
ifeq ($(SPECTRUMMACHINE),real)
	@$(PROMPT) "Press <enter> to stop disc"
endif
ifeq ($(SPECTRUMMACHINE),fuse)
	@$(PROMPT) "Press <enter> to stop disc"
	@$(STOPFUSE)
endif
	@$(STOPDISC)

spectrum/%.fifo : | spectrum

	mkfifo $@

spectrum/%.lib : %.c rf.h target/spectrum/spectrum.inc | spectrum

	zcc $(SPECTRUMZCCOPTS) -x -o $@ $<

spectrum/%.ser : spectrum/%.bin | $(ORTER)

	$(ORTER) spectrum header $< 3 32768 0 > $@

spectrum/%.tap spectrum/%.wav : spectrum/%.bin

	z88dk-appmake +zx --audio -b $< --org $(SPECTRUMORG) --clearaddr 0x7A9F -o $@

spectrum/hw.tap : hw.c

	zcc +zx -lndos -create-app -o spectrum/hw.bin $<

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

spectrum/inst.lib : inst.c rf.h target/spectrum/spectrum.inc | spectrum

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

spectrum/orterforth.bin : spectrum/orterforth.img | $(ORTER)

	$(ORTER) hex read < $< > $@

spectrum/orterforth.img : model.img $(SPECTRUMINSTDEPS)

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

spectrum/rf_z80.lib : rf_z80.asm | spectrum

	zcc $(SPECTRUMZCCOPTS) -x -o $@ $<

spectrum/system.lib : $(SPECTRUMSYSTEM) | spectrum

	zcc $(SPECTRUMZCCOPTS) -x -o $@ $<

tools/github.com/superzazu/z80/z80.c tools/github.com/superzazu/z80/z80.h :

	git submodule update --init tools/github.com/superzazu/z80

spectrum/load-serial.bas : spectrum/load-serial.hex

	$(ORTER) hex read < $< > $@

spectrum/load-serial.hex :

	# type 00 0055 5D05 0055 000A
	printf '00 55 00 05 5d 55 00 0a 00' > $@
	# 10 CLEAR 31391
	printf '00 0a 0d 00 fd 33 31 33 39 31 0e 00 00 9f 7a 00 0d' >> $@
	## 10 CLEAR 32767
	#printf '00 0a 0d 00 fd 33 32 37 36 37 0e 00 00 ff 7f 00 0d' >> $@
	# 20 LOAD *"b"CODE
	printf '00 14 07 00 ef 2a 22 62 22 af 0d' >> $@
	# 25 OPEN #4;"b":PRINT #4;CHR$(6);
	printf '00 19 23 00 d3 34 0e 00 00 04 00 00 3b 22 62 22 3a f5 23 34 0e 00 00 04 00 00 3b c2 28 36 0e 00 00 06 00 00 29 3b 0d' >> $@
	# 30 RANDOMIZE USR 32768
	printf '00 1e 0e 00 f9 c0 33 32 37 36 38 0e 00 00 00 80 00 0d' >> $@
