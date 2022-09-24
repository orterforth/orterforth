# C compiler options
CFLAGS += -Wall -Werror -std=c89 -ansi -Wpedantic

# local system OS
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
ifneq ($(filter MINGW%,$(UNAME_S)),)
	OPER := mingw
endif

# local processor architecture
UNAME_M := $(shell uname -m)
PROC := $(UNAME_M)
ifeq (${OPER},linux)
ifeq (${PROC},x86_64)
ifeq ($(shell getconf LONG_BIT),32)
		PROC := i686
endif
endif
endif

# local system
SYSTEM := $(OPER)-$(PROC)

# default build is local system platform
TARGET := $(SYSTEM)

# local system target executables
DISC := $(SYSTEM)/disc
ORTER := $(SYSTEM)/orter
ORTERFORTH := $(SYSTEM)/orterforth

# serial port
ifeq ($(OPER),cygwin)
SERIALPORT := /dev/ttyS2
endif
ifeq ($(OPER),darwin)
SERIALPORT := /dev/cu.usbserial-FT2XIBOF
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
	$(SYSTEM)/orter_fuse.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/rf_persci.o \
	disc.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

# orter - retrocomputing multitool
$(ORTER) : \
	$(SYSTEM)/orter_fuse.o \
	$(SYSTEM)/orter_ql.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_spectrum.o \
	$(SYSTEM)/orter_uef.o \
	orter/main.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^


# === LOCAL SYSTEM ===

# SYSTEMOPTION := assembly
SYSTEMOPTION := default

SYSTEMDEPSALL := \
	$(SYSTEM)/rf.o \
	$(SYSTEM)/rf_inst.o \
	$(SYSTEM)/rf_persci.o \
	$(SYSTEM)/rf_system.o

ifeq ($(SYSTEMOPTION),assembly)
SYSTEMDEPS := $(SYSTEMDEPSALL) $(SYSTEM)/rf_$(PROC).o
SYSTEMINC := target/system/assembly.inc
# linker script to reconcile leading underscore handling
ifeq ($(OPER),cygwin)
LDFLAGS += -t target/system/linux.ld
endif
ifeq ($(OPER),linux)
LDFLAGS += -t target/system/linux.ld
endif
endif

ifeq ($(SYSTEMOPTION),default)
SYSTEMDEPS := $(SYSTEMDEPSALL)
SYSTEMINC := target/system/default.inc
endif

CPPFLAGS += -DRF_TARGET_INC='"$(SYSTEMINC)"'

# local system executable
$(ORTERFORTH) : $(SYSTEMDEPS) orterforth.c

	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $^

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
	rm -f orterforth.disc
	rm -f orterforth.inc

# run local build
.PHONY : $(SYSTEM)-run
$(SYSTEM)-run : $(ORTERFORTH) orterforth.disc library.disc

	@$(ORTERFORTH) library.disc

# local system lib default
$(SYSTEM)/%.o : %.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# local system lib default
$(SYSTEM)/%.s : %.c | $(SYSTEM)

	$(CC) -S $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# emulator to build fast
$(SYSTEM)/emulate_spectrum : \
	$(SYSTEM)/emulate_spectrum.o \
	$(SYSTEM)/z80.o \
	$(SYSTEM)/rf_persci.o

	$(CC) -o $@ $^

# spectrum emulator
$(SYSTEM)/emulate_spectrum.o : target/spectrum/emulate.c rf_persci.h | $(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

$(SYSTEM)/orter_fuse.o : orter/fuse.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_ql.o : orter/ql.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_serial.o : orter/serial.c orter/serial.h orter/io.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_spectrum.o : orter/spectrum.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_uef.o : orter/uef.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# main lib
$(SYSTEM)/rf.o : rf.c rf.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# inst lib
$(SYSTEM)/rf_inst.o : rf_inst.c orterforth.inc rf.h rf_persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# disc impl lib
$(SYSTEM)/rf_persci.o : rf_persci.c rf_persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# local system lib
$(SYSTEM)/rf_system.o : rf_system.c rf.h rf_persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# x86_64 assembly code
$(SYSTEM)/rf_$(PROC).o : rf_$(PROC).s | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# https://github.com/superzazu/z80.git
$(SYSTEM)/z80.o : tools/z80/z80.c tools/z80/z80.h | $(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

# help
.PHONY : $(TARGET)-help
$(TARGET)-help :

	@if [ "$(TARGET)" = "$(SYSTEM)" ] ; then cat help.txt ; else more target/$(TARGET)/help.txt ; fi

# disc images from %.f files including orterforth.f
%.disc : %.f | $(DISC)

	$(DISC) create <$< >$@.io
	mv $@.io $@


# === BBC Micro ===

# build config option
# BBCOPTION := assembly
BBCOPTION := default
# BBCOPTION := tape

# emulator ROM files
BBCROMS := \
	roms/bbcb/basic2.rom \
	roms/bbcb/dnfs120.rom \
	roms/bbcb/os12.rom \
	roms/bbcb/phroma.bin \
	roms/bbcb/saa5050

# assembly code
ifeq ($(BBCOPTION),assembly)
	BBCDEPS := bbc/orterforth.o bbc/rf.o bbc/rf_6502.o bbc/rf_inst.o bbc/rf_system_asm.o bbc/bbc.lib
	BBCINC := target/bbc/assembly.inc
	BBCINSTMEDIA = bbc/orterforth-inst.ssd
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1 bbc/orterforth-inst.ssd
	BBCORG := 1720
	BBCORIGIN := 2300
	BBCRUN := bbc-run-disk
endif

# default C code
ifeq ($(BBCOPTION),default)
	BBCDEPS := bbc/mos.o bbc/orterforth.o bbc/rf.o bbc/rf_inst.o bbc/rf_system_c.o bbc/bbc.lib
	BBCINC := target/bbc/default.inc
	BBCINSTMEDIA = bbc/orterforth-inst.ssd
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1 bbc/orterforth-inst.ssd
	BBCORG := 1720
	BBCORIGIN := 2E00
	BBCRUN := bbc-run-disk
endif

# assembly code, tape only config starting at 0xE00
ifeq ($(BBCOPTION),tape)
	BBCDEPS := bbc/orterforth.o bbc/rf.o bbc/rf_6502.o bbc/rf_inst.o bbc/rf_system_asm.o bbc/bbc.lib
	BBCINC := target/bbc/tape.inc
	BBCINSTMEDIA = bbc/orterforth-inst.uef
	BBCMAMEINST := -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\r' -cassette bbc/orterforth-inst.uef
	BBCORG := 1220
	BBCORIGIN := 1E00
	BBCRUN := bbc-run-tape
endif

bbc :

	mkdir $@

.PHONY : bbc-build
bbc-build : bbc/orterforth.ssd bbc/orterforth.uef

.PHONY : bbc-clean
bbc-clean : 

	rm -f bbc/*

# MAME command line
BBCMAME := mame bbcb -rompath roms -video opengl \
	-skip_gameinfo -nomax -window \
	-rs423 null_modem -bitb socket.127.0.0.1:5705

# MAME command line for fast inst, no video and timeout
BBCMAMEFAST := mame bbcb -rompath roms -video none -sound none \
	-skip_gameinfo -nomax -window \
	-speed 50 -frameskip 10 -nothrottle -seconds_to_run 2000 \
	-rs423 null_modem -bitb socket.127.0.0.1:5705

# default is to load from disk
.PHONY : bbc-run
bbc-run : $(BBCRUN)

# load from disk and run
.PHONY : bbc-run-disk
bbc-run-disk : bbc/orterforth.ssd $(BBCROMS) | $(DISC) messages.disc

	# start disc
	touch 1.disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 messages.disc 1.disc

	# run mame
	@$(BBCMAME) -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\r' -flop1 bbc/orterforth.ssd

	# stop disc
	sh scripts/stop.sh disc.pid

# load from tape and run
.PHONY : bbc-run-tape
bbc-run-tape : bbc/orterforth.uef $(BBCROMS) | $(DISC) messages.disc

	# start disc
	touch 1.disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 messages.disc 1.disc

	@$(BBCMAME) -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\r' -cassette bbc/orterforth.uef

	# stop disc
	sh scripts/stop.sh disc.pid

# general assemble rule
bbc/%.o : bbc/%.s

	ca65 -DRF_ORIGIN='$$$(BBCORIGIN)' -o $@ $<

# general compile rule
bbc/%.s : %.c | bbc

	cc65 -O -t none -D__BBC__ -DRF_TARGET_INC='"$(BBCINC)"' -o $@ $<

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

# MOS bindings
bbc/mos.o : target/bbc/mos.s | bbc

	ca65 -o $@ $<

# final binary from the hex
bbc/orterforth : bbc/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# final binary hex
bbc/orterforth.hex : $(BBCINSTMEDIA) orterforth.disc $(BBCROMS) | $(DISC)

	# start disc
	rm -f $@.io
	touch $@.io
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 orterforth.disc $@.io

	# run emulator, wait for result
	$(BBCMAMEFAST) $(BBCMAMEINST) & pid=$$! ; \
		scripts/waitforhex $@.io ; \
		kill -9 $$pid

	# copy result
	mv $@.io $@

	# stop disc
	sh scripts/stop.sh disc.pid

# final disc inf
bbc/orterforth.inf : | bbc

	echo "$$.orterfo  $(BBCORG)   $(BBCORG)  CRC=0" > $@

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

	echo "$$.orterfo  $(BBCORG)   $(BBCORG)  CRC=0" > $@

# inst serial load file
ifeq ($(OPER),cygwin)
STAT := stat -c %s
endif
ifeq ($(OPER),darwin)
STAT := stat -f%z
endif
ifeq ($(OPER),linux)
STAT := stat -c %s
endif
bbc/orterforth-inst.ser : bbc/orterforth-inst

	printf "5P.\"Loading...\"\r10FOR I%%=&$(BBCORG) TO &$(BBCORG)+$(shell $(STAT) $<)-1:?I%%=GET:NEXT I%%:P.\"done\"\r20*FX3,7\r30VDU 6\r40CALL &$(BBCORG)\rRUN\r" > $@.io
	cat -u $< >> $@.io
	mv $@.io $@

# inst disc image
bbc/orterforth-inst.ssd : bbc/boot bbc/boot.inf bbc/orterforth-inst bbc/orterforth-inst.inf

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ bbc/orterforth-inst

# inst tape image
bbc/orterforth-inst.uef : bbc/orterforth-inst $(ORTER)

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


# === Commodore 64 ===

c64 :

	mkdir $@

.PHONY : c64-build
c64-build : c64/orterforth-inst

.PHONY : c64-clean
c64-clean :

	rm -rf c64/*

.PHONY : c64-run
c64-run : c64/orterforth-inst

	export PATH="/Applications/vice-x86-64-gtk3-3.6.1/bin:$$PATH" && x64sc -userportdevice 2 -rsuserdev 3 -rsuserbaud 2400 -rsdev4 "|$(DISC) standard orterforth.disc 1.disc" -rsdev4baud 2400 -autostart $<


# general assemble rule
c64/%.o : c64/%.s

	ca65 -t c64 -o $@ $<

# general compile rule
c64/%.s : %.c | c64

	cc65 -O -t c64 -DRF_TARGET_INC='"target/c64/default.inc"' -o $@ $<

c64/c64-up2400.s : c64/c64-up2400.ser

	co65 --code-label _c64_serial -o $@ $<
  
# C system lib
c64/rf_system_c.s : target/c64/system.c | c64

	cc65 -O -t c64 -o $@ $<

# inst binary
c64/orterforth-inst : c64/orterforth.o c64/rf.o c64/rf_inst.o c64/rf_system_c.o c64/c64-up2400.o | c64

	cl65 -O -t c64 -o $@ -m c64/orterforth-inst.map $^

# clean
.PHONY : clean
clean : $(TARGET)-clean

# clean all
.PHONY : clean-all
clean-all : $(SYSTEM)-clean spectrum-clean

# run disc on physical serial port
.PHONY : disc
disc : $(DISC) orterforth.disc

	touch 1.disc
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) orterforth.disc 1.disc

# help
.PHONY : help
help : $(TARGET)-help

# install to local
.PHONY : install
install : $(ORTERFORTH)

	cp $< /usr/local/bin/orterforth


# === TRS-80 Model 100 ===

m100 :

	mkdir $@

m100/hw.co : | m100

	zcc +m100 -subtype=default hw.c -o $@ -create-app

# disc image as C include
orterforth.inc : orterforth.disc | $(ORTER)

	# xxd -i $< > $@
	$(ORTER) hex include orterforth_disc <$< >$@.io
	mv $@.io $@

# === Raspberry Pi Pico ===

.PHONY : pico-build
pico-build : orterforth.inc | pico

	cd pico && PICO_SDK_PATH=~/pico-sdk cmake ../target/pico && make

.PHONY : pico-clean
pico-clean :

	rm -rf pico/*

pico :

	mkdir $@


# === Sinclair QL ===

# QLOPTION := assembly
QLOPTION := default

ifeq ($(QLOPTION),assembly)
QLDEPS := ql/rf.o ql/rf_m68k.o ql/system.o ql/orterforth.o
QLINC := target/ql/assembly.inc
endif

ifeq ($(QLOPTION),default)
QLDEPS := ql/rf.o ql/system.o ql/orterforth.o
QLINC := target/ql/default.inc
endif

ql :

	mkdir $@

.PHONY : ql-build
ql-build : ql/orterforth

.PHONY : ql-clean
ql-clean :

	rm -rf ql/*

QLSERIALBAUD := 4800

# load from serial
.PHONY : ql-load-serial
#ql-load-serial :  ql/orterforth.ser ql/loader.ser | $(DISC) $(ORTER)
ql-load-serial : ql/orterforth.bin.ser ql/orterforth.ser ql/loader.ser | $(DISC) $(ORTER)

	@echo "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/loader.ser
	@sleep 3

	@echo "* Loading install..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/orterforth.bin.ser
	@sleep 3

	@echo "* Loading job..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/orterforth.ser
	@sleep 3

	@echo "* Starting disc..."
	@touch 1.disc
	@$(DISC) serial $(SERIALPORT) $(QLSERIALBAUD) orterforth.disc 1.disc

# loader terminated with Ctrl+Z, to load via SER2Z
ql/loader-inst.ser : target/ql/loader-inst.bas

	cat $< > $@.io
	printf '\032' >> $@.io
	mv $@.io $@

# loader terminated with Ctrl+Z, to load via SER2Z
ql/loader.ser : target/ql/loader.bas

	cat $< > $@.io
	printf '\032' >> $@.io
	mv $@.io $@

# final executable
ql/orterforth : ql/relink.o $(QLDEPS)

	qld -ms -o $@ $^

# inst executable
ql/orterforth-inst : ql/rf_inst.o $(QLDEPS)

	qld -ms -o $@ $^

# inst executable with serial header
ql/orterforth-inst.ser : ql/orterforth-inst | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

# saved binary
ql/orterforth.bin : ql/orterforth.bin.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# saved binary as hex
ql/orterforth.bin.hex : ql/orterforth-inst.ser ql/loader-inst.ser | $(DISC) $(ORTER)

	@echo "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/loader-inst.ser

	@echo "* Loading installer..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/orterforth-inst.ser

	@echo "* Starting disc and waiting for completion..."
	@touch $@.io
	@$(DISC) serial $(SERIALPORT) $(QLSERIALBAUD) orterforth.disc $@.io & pid=$$! ; \
		scripts/waitforhex $@.io ; \
		kill -9 $$pid

	@mv $@.io $@
	@echo "* Done"
	@sleep 1

# saved binary with serial header
ql/orterforth.bin.ser : ql/orterforth.bin | $(ORTER)

	$(ORTER) ql serial-bytes $< > $@

# main program
ql/orterforth.o : orterforth.c rf.h $(QLINC) rf_inst.h | ql

	qcc -o $@ -c $<

# final binary with serial header
ql/orterforth.ser : ql/orterforth | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

# relinker
ql/relink.o : target/ql/relink.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<

# machine and code
ql/rf.o : rf.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<

# assembly code
ql/rf_m68k.o : rf_m68k.s | ql

	qcc -o $@ -c $<

# installer
ql/rf_inst.o : rf_inst.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<

# system support
ql/system.o : target/ql/system.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<


# === RC2014 ===

.PHONY : rc2014-build
rc2014-build : rc2014/orterforth-inst.ihx

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

.PHONY : rc2014-run
rc2014-run : target/rc2014/hexload.bas rc2014/orterforth-inst.ihx | $(ORTER)

	#echo "C35071" | $(ORTER) serial -o olfcr -e 5 $(RC2014SERIALPORT) 115200
	echo "A"
	sleep 10
	$(ORTER) serial -o olfcr -e 3 $(RC2014SERIALPORT) 115200 < target/rc2014/hexload.bas
	echo "B"
	sleep 10
	$(ORTER) serial -o olfcr -e 3 $(RC2014SERIALPORT) 115200 < rc2014/orterforth-inst.ihx
	echo "C"
	sleep 3
	$(DISC) serial $(RC2014SERIALPORT) 115200 orterforth.disc 1.disc

rc2014 :

	mkdir $@

# inst executable
rc2014/orterforth-inst.ihx : \
	rc2014/rf.lib \
	rc2014/rf_inst.lib \
	rc2014/rf_system.lib \
	orterforth.c

	zcc +rc2014 -subtype=basic \
		-lrc2014/rf -lrc2014/rf_inst -lrc2014/rf_system \
		-m \
		-o $@ \
		orterforth.c -create-app

# base orterforth code
rc2014/rf.lib : rf.c rf.h target/rc2014/default.inc | rc2014

	zcc +rc2014 -x -o $@ $<

# inst code
rc2014/rf_inst.lib : rf_inst.c rf.h target/rc2014/default.inc rf_inst.h | rc2014

	zcc +rc2014 -x -o $@ $<

# system code
rc2014/rf_system.lib : target/rc2014/rc2014.c rf.h target/rc2014/default.inc | rc2014

	zcc +rc2014 -x -o $@ $<

# ROM file dir
roms : 

	mkdir $@

# BBC Micro ROM files dir
roms/bbcb : | roms

	mkdir $@

# BBC Micro ROM files
roms/bbcb/% : | roms/bbcb

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

# ZX Spectrum ROM files dir
roms/spectrum : | roms

	mkdir $@

# ZX Spectrum ROM files
roms/spectrum/% : | roms/spectrum

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

# run local build
.PHONY : run
run : $(TARGET)-run

# run utility script
.PHONY : script
script :

	sh scripts/script.sh


# === ZX Spectrum ===

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

# load from serial
# TODO should not rebuild orterforth-inst-2.tap via dependency chain
.PHONY : spectrum-load-serial
spectrum-load-serial : spectrum/orterforth.ser target/spectrum/load-serial.bas

	@echo "On the Spectrum type: FORMAT \"b\";$(SERIALBAUD)"
	@echo "                      LOAD *\"b\""
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas

	@echo "* Loading orterforth..."
	$(ORTER) serial -e 15 $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth.ser

	@echo "* Starting disc..."
	touch 1.disc
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) messages.disc 1.disc

# config option
SPECTRUMOPTION := a

SPECTRUMLIBSALL := \
	-lmzx_tiny \
	-lndos \
	-lspectrum/rf \
	-lspectrum/rf_inst \
	-lspectrum/rf_system

# minimal ROM-based
ifeq ($(SPECTRUMOPTION),a)
# uses Interface 1 ROM for RS232
SPECTRUMLIBS := \
	$(SPECTRUMLIBSALL) \
	-lspectrum/rf_z80 \
	-pragma-redirect:fputc_cons=fputc_cons_rom_rst
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 0x8000
# ORIGIN
SPECTRUMORIGIN := 0x8A00
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
	$(SPECTRUMLIBSALL) \
	-lspectrum/rf_z80 \
	-lrs232if1
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 0x8000
# ORIGIN higher, 0x9200, C code is larger as uses z88dk libs
SPECTRUMORIGIN := 0x9200
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
	$(SPECTRUMLIBSALL) \
	-lrs232if1
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 0x8000
# ORIGIN higher, 0x9B00, C code is larger as uses z88dk libs and pure C impl
SPECTRUMORIGIN := 0x9B00
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
spectrum-run-fuse : spectrum/orterforth.tap | $(DISC) roms/spectrum/if1-2.rom spectrum/fuse-rs232-rx spectrum/fuse-rs232-tx

	# start disc
	touch 1.disc
	sh scripts/start.sh spectrum/fuse-rs232-tx spectrum/fuse-rs232-rx disc.pid $(DISC) fuse messages.disc 1.disc

	# run fuse
	$(FUSE) \
		--speed=100 \
		--machine 48 \
		--graphics-filter 2x \
		--interface1 \
		--rom-48 roms/spectrum/spectrum.rom \
		--rom-interface-1 roms/spectrum/if1-2.rom \
		--auto-load \
		--phantom-typist-mode keyword \
		--rs232-rx spectrum/fuse-rs232-rx \
		--rs232-tx spectrum/fuse-rs232-tx \
		--tape $<

	# stop disc
	sh scripts/stop.sh disc.pid

# run Mame emulator, load TAP
.PHONY: spectrum-run-mame
spectrum-run-mame : spectrum/orterforth.tap

	# start disc
	touch 1.disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 messages.disc 1.disc

	@echo '1. Press Enter to skip the warning'
	@echo '2. Start the tape via F2 or the Tape Control menu'
	@mame spectrum -rompath roms -video opengl \
		-exp intf1 \
		-exp:intf1:rs232 null_modem \
		-bitb socket.localhost:5705 \
		-window -skip_gameinfo \
		-autoboot_delay 5 \
		-autoboot_command 'j""\n' \
		-cassette $<

	# stop disc
	sh scripts/stop.sh disc.pid

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
	# cat $< > $@.io
	# head -c 32768 /dev/null >> $@.io
	# head -c $(SPECTRUMINSTOFFSET) $@.io > $@
	# cat spectrum/orterforth-inst_INST.bin >> $@


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
SPECTRUMINSTDEPS := spectrum/orterforth-inst-2.tap $(DISC) $(ORTER) $(FUSE) roms/spectrum/if1-2.rom roms/spectrum/spectrum.rom spectrum/fuse-rs232-rx spectrum/fuse-rs232-tx
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
	sh scripts/start.sh spectrum/fuse-rs232-tx spectrum/fuse-rs232-rx disc.pid $(DISC) fuse orterforth.disc $@.io

	# start Fuse
	sh scripts/start.sh /dev/stdin /dev/stdout fuse.pid $(FUSE) \
		--speed=1000 \
		--machine 48 \
		--interface1 \
		--rom-48 roms/spectrum/spectrum.rom \
		--rom-interface-1 roms/spectrum/if1-2.rom \
		--auto-load \
		--phantom-typist-mode keyword \
		--rs232-rx spectrum/fuse-rs232-rx \
		--rs232-tx spectrum/fuse-rs232-tx \
		--tape spectrum/orterforth-inst-2.tap

	# wait for install and save
	sh scripts/waitforhex $@.io

	# stop Fuse
	sh scripts/stop.sh fuse.pid

	# stop disc
	sh scripts/stop.sh disc.pid
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
	@$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas

	@echo "* Loading inst..."
	@$(ORTER) serial -e 21 $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth-inst-2.ser

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

.PHONY : test
test : $(ORTERFORTH) test.disc

	echo "1 LOAD" | $< test.disc

.PHONY : todo
todo : $(ORTERFORTH)

	$< < todo.f

tools :

	mkdir $@

tools/z80/z80.c : | tools

	cd tools && git clone https://github.com/superzazu/z80.git

tools/z80/z80.h : tools/z80/z80.c
