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
	$(SYSTEM)/orter_io.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/persci.o \
	disc.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

# orter - retrocomputing multitool
$(ORTER) : \
	$(SYSTEM)/orter_bbc.o \
	$(SYSTEM)/orter_fuse.o \
	$(SYSTEM)/orter_io.o \
	$(SYSTEM)/orter_ql.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_spectrum.o \
	orter/main.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^


# === LOCAL SYSTEM ===

# SYSTEMOPTION := assembly
SYSTEMOPTION := default

SYSTEMDEPSALL := \
	$(SYSTEM)/rf.o \
	$(SYSTEM)/inst.o \
	$(SYSTEM)/persci.o \
	$(SYSTEM)/system.o

# assembler based inner interpreter and code
ifeq ($(SYSTEMOPTION),assembly)
SYSTEMDEPS := $(SYSTEMDEPSALL) $(SYSTEM)/rf_$(PROC).o
CPPFLAGS += -DRF_ASSEMBLY
# linker script to reconcile leading underscore handling
ifeq ($(OPER),cygwin)
LDFLAGS += -t gcc.ld
endif
ifeq ($(OPER),linux)
LDFLAGS += -t gcc.ld
endif
endif

# C based inner interpreter and code
ifeq ($(SYSTEMOPTION),default)
SYSTEMDEPS := $(SYSTEMDEPSALL)
endif

# local system executable
$(ORTERFORTH) : $(SYSTEMDEPS) main.c

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
	rm -f model.disc
	rm -f model.inc

# runtime disc images
DR0=messages.disc
DR1=data.disc

# run local build
.PHONY : $(SYSTEM)-run
$(SYSTEM)-run : $(ORTERFORTH) $(DR0)

	@touch $(DR1)
	@$< $(DR0) $(DR1)

# run local build with test disc
.PHONY : $(SYSTEM)-test
$(SYSTEM)-test : $(ORTERFORTH) test.disc

	echo "EMPTY-BUFFERS 1 LOAD" | $< test.disc

# for working with assembly
$(SYSTEM)/%.s : %.c | $(SYSTEM)

	$(CC) -S $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# emulator to build fast
$(SYSTEM)/emulate_spectrum : \
	$(SYSTEM)/emulate_spectrum.o \
	$(SYSTEM)/z80.o \
	$(SYSTEM)/persci.o

	$(CC) -o $@ $^

# spectrum emulator
$(SYSTEM)/emulate_spectrum.o : target/spectrum/emulate.c persci.h | $(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

# inst lib
$(SYSTEM)/inst.o : inst.c model.inc rf.h system.inc persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_bbc.o : orter/bbc.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_fuse.o : orter/fuse.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_io.o : orter/io.c orter/io.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_ql.o : orter/ql.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_serial.o : orter/serial.c orter/io.h orter/serial.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/orter_spectrum.o : orter/spectrum.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# disc impl lib
$(SYSTEM)/persci.o : persci.c persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# C code lib
$(SYSTEM)/rf.o : rf.c rf.h system.inc | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# assembly code lib
$(SYSTEM)/rf_$(PROC).o : rf_$(PROC).s | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# system dependent code lib
$(SYSTEM)/system.o : system.c rf.h system.inc persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# https://github.com/superzazu/z80.git
$(SYSTEM)/z80.o : tools/z80/z80.c tools/z80/z80.h | $(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -c -o $@ $<

# https://github.com/mcleod-ideafix/zx81putil
$(SYSTEM)/zx81putil : tools/zx81putil/zx81putil.c | $(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -o $@ $<

# help
.PHONY : $(TARGET)-help
$(TARGET)-help :

	@if [ "$(TARGET)" = "$(SYSTEM)" ] ; then more help.txt ; else more target/$(TARGET)/help.txt ; fi

# disc images from %.f files including model.f
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
	BBCDEPS := bbc/main.o bbc/rf.o bbc/rf_6502.o bbc/inst.o bbc/rf_system_asm.o bbc/bbc.lib
	BBCINC := target/bbc/assembly.inc
	BBCLOADINGMETHOD := disk
	BBCORG := 1720
	BBCORIGIN := 2200
endif

# default C code
ifeq ($(BBCOPTION),default)
	BBCDEPS := bbc/mos.o bbc/main.o bbc/rf.o bbc/inst.o bbc/rf_system_c.o bbc/bbc.lib
	BBCINC := target/bbc/default.inc
	BBCLOADINGMETHOD := disk
	BBCORG := 1720
	BBCORIGIN := 3000
endif

# assembly code, tape only config starting at 0xE00
ifeq ($(BBCOPTION),tape)
	BBCDEPS := bbc/main.o bbc/rf.o bbc/rf_6502.o bbc/inst.o bbc/rf_system_asm.o bbc/bbc.lib
	BBCINC := target/bbc/tape.inc
	BBCLOADINGMETHOD := tape
	BBCORG := 1220
	BBCORIGIN := 1D00
endif

# default is to run MAME
BBCMACHINE := mame
#BBCMACHINE := real

# physical machine loading method serial by default
ifeq ($(BBCMACHINE),real)
	BBCLOADINGMETHOD := serial
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

# load and run
# TODO BBCROMS not needed for real hardware
bbc-run : $(BBCMEDIA) $(BBCROMS) | $(DISC) $(DR0) $(DR1)

ifeq ($(BBCMACHINE),mame)
	# start disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 $(DR0) $(DR1)

	# run mame
	$(BBCMAME) $(BBCMAMERUN)

	# stop disc
	sh scripts/stop.sh disc.pid
endif
ifeq ($(BBCMACHINE),real)
	@# prompt user
	@echo "  ensure RS423 connected to serial port"
	@echo "  type the following"
	@# TODO baud settings parameterised
	@echo "   *FX7,7 <enter>"
	@echo "   *FX8,7 <enter>"
	@echo "   *FX2,1 <enter>"
	@read -p "  then on this machine press enter " LINE

	@# load via serial
	@echo "* loading via serial..."
	@$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < bbc/orterforth.ser

	# run disc
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) $(DR1)
endif

# load and run tests
.PHONY : bbc-test
# TODO BBCROMS not needed for real hardware
bbc-test : $(BBCMEDIA) $(BBCROMS) | $(DISC) test.disc $(DR1)

ifeq ($(BBCMACHINE),mame)
	# start disc
	touch $(DR1)
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 test.disc $(DR1)

	# run mame
ifeq ($(BBCLOADINGMETHOD),disk)
	$(BBCMAME) -autoboot_delay 2 -autoboot_command '*DISK\r*EXEC !BOOT\rEMPTY-BUFFERS 1 LOAD\r' -flop1 bbc/orterforth.ssd
endif
ifeq ($(BBCLOADINGMETHOD),serial)
	echo "serial load currently fails on MAME" && exit 1
endif
ifeq ($(BBCLOADINGMETHOD),tape)
	$(BBCMAME) -autoboot_delay 2 -autoboot_command '*TAPE\r*RUN\rEMPTY-BUFFERS 1 LOAD\r' -cassette bbc/orterforth.uef
endif

	# stop disc
	sh scripts/stop.sh disc.pid
endif
ifeq ($(BBCMACHINE),real)
	@# prompt user
	@echo "  ensure RS423 connected to serial port"
	@echo "  type the following"
	@# TODO baud settings parameterised
	@echo "   *FX7,7 <enter>"
	@echo "   *FX8,7 <enter>"
	@echo "   *FX2,1 <enter>"
	@read -p "  then on this machine press enter " LINE

	@# load via serial
	@echo "* loading via serial..."
	@$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < bbc/orterforth.ser

	@# prompt user
	@echo "* now type EMPTY-BUFFERS 1 LOAD"

	# run disc
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) test.disc $(DR1)
endif

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
# TODO BBCROMS not needed for real hardware
bbc/orterforth.hex : $(BBCINSTMEDIA) model.disc $(BBCROMS) | $(DISC)

	# empty disc
	rm -f $@.io
	touch $@.io

ifeq ($(BBCMACHINE),mame)
	# start disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 model.disc $@.io

	# start Mame
	sh scripts/start.sh /dev/stdin /dev/stdout mame.pid $(BBCMAMEFAST) $(BBCMAMEINST)
endif
ifeq ($(BBCMACHINE),real)
	@# prompt user
	@echo "  ensure RS423 connected to serial port"
	@echo "  type the following"
	@# TODO baud settings parameterised
	@echo "   *FX7,7 <enter>"
	@echo "   *FX8,7 <enter>"
	@echo "   *FX2,1 <enter>"
	@read -p "  then on this machine press enter " LINE

	# load via serial
	@echo "* loading via serial..."
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < $(BBCINSTMEDIA)

	# start disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) serial $(SERIALPORT) $(SERIALBAUD) model.disc $@.io
endif

	# wait for save
	sh scripts/wait-until-saved.sh $@.io

ifeq ($(BBCMACHINE),mame)
	# stop Mame
	sh scripts/stop.sh mame.pid
endif

	# stop disc
	sh scripts/stop.sh disc.pid

	# copy result
	mv $@.io $@

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

	$(ORTER) bbc uef write orterforth 0x$(BBCORG) 0x$(BBCORG) <$< >$@.io
	mv $@.io $@

# inst binary
bbc/inst : $(BBCDEPS)

	cl65 -O -t none -C target/bbc/bbc.cfg --start-addr 0x$(BBCORG) -o $@ -m bbc/inst.map $^

# inst disc inf
bbc/inst.inf : | bbc

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
bbc/%.ser : bbc/%

	printf "5P.\"Loading...\"\r" > $@.io
	printf "10FOR I%%=&$(BBCORG) TO &$(BBCORG)+$(shell $(STAT) $<)-1:?I%%=GET:NEXT I%%:P.\"done\"\r" >> $@.io
	printf "20*FX3,7\r30VDU 6\r40CALL &$(BBCORG)\rRUN\r" >> $@.io
	cat -u $< >> $@.io
	mv $@.io $@

# inst disc image
bbc/inst.ssd : bbc/boot bbc/boot.inf bbc/inst bbc/inst.inf

	rm -f $@
	bbcim -a $@ bbc/boot
	bbcim -a $@ bbc/inst

# inst tape image
bbc/inst.uef : bbc/inst $(ORTER)

	$(ORTER) bbc uef write orterforth 0x$(BBCORG) 0x$(BBCORG) <$< >$@.io
	mv $@.io $@

# main lib
bbc/rf.s : rf.c rf.h $(BBCINC) | bbc

	cc65 -O -t none -D__BBC__ -DRF_ORIGIN='0x$(BBCORIGIN)' -DRF_TARGET_INC='"$(BBCINC)"' -o $@ $<

# asm bbc system lib
bbc/rf_6502.o : rf_6502.s | bbc

	ca65 -DRF_ORIGIN='0x$(BBCORIGIN)' -o $@ $<

# main lib
bbc/inst.s : inst.c rf.h $(BBCINC) | bbc

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


# === Commodore 64 ===

c64 :

	mkdir $@

.PHONY : c64-build
c64-build : c64/inst

.PHONY : c64-clean
c64-clean :

	rm -rf c64/*

# laderach order number Your order # is: 16000009993.

.PHONY : c64-example
c64-example : ../c64-up2400-cc65/example/example.d64

	x64 -userportdevice 2 -rsuserdev 3 -rsuserbaud 2400 -rsdev4 "|echo 'hello'" -rsdev4baud 2400 -autostart "$<:example.prg"

.PHONY : c64-hw
c64-hw : c64/hw.prg

	x64 -userportdevice 2 -rsuserdev 3 -rsuserbaud 2400 -rsdev4 "|$(DISC) standard model.disc data.disc" -rsdev4baud 2400 -autostartprgmode 1 -autostart $<

.PHONY : c64-run
c64-run : c64/inst.prg

	# start disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 25232 model.disc data.disc

	# x64 -userportdevice 2 -rsuserdev 3 -rsuserbaud 2400 -rsdev4 "|$(DISC) standard model.disc data.disc" -rsdev4baud 2400 -autostartprgmode 1 -autostart $<
	x64 -userportdevice 2 -rsuserdev 2 -rsuserbaud 2400 -rsdev3baud 2400 -autostartprgmode 1 -autostart $<

	# stop disc
	sh scripts/stop.sh disc.pid

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

# Hello World
c64/hw.prg : hw.c | c64

	cl65 -O -t c64 -o $@ $^

# inst binary
c64/inst.prg : c64/main.o c64/rf.o c64/inst.o c64/rf_system_c.o c64/c64-up2400.o | c64

	cl65 -O -t c64 -o $@ -m c64/inst.map $^

# clean
.PHONY : clean
clean : $(TARGET)-clean

# clean all
.PHONY : clean-all
clean-all : $(SYSTEM)-clean spectrum-clean

# run disc on physical serial port
.PHONY : disc
disc : $(DISC) $(DR0) $(DR1)

	touch $(DR1)
	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) $(DR1)


# === Dragon 32/64 ===

dragon :

	mkdir $@

.PHONY : dragon-build
dragon-build : dragon/inst.bin

.PHONY : dragon-clean
dragon-clean :

	rm -f dragon/*

.PHONY : dragon-hw
dragon-hw : dragon/hw.cas | roms/dragon64/d64_1.rom roms/dragon64/d64_2.rom

	mame dragon64 -rompath roms -video opengl \
	-resolution 1024x768 -skip_gameinfo -nomax -window \
	-cassette $< \
	-autoboot_delay 4 -autoboot_command "CLOADM\r"

dragon/hw.cas : dragon/hw.bin | tools/bin2cas.pl

	tools/bin2cas.pl --output $@ -D --load 0x2800 --exec 0x2800 $<

dragon/hw.bin : hw.c

	cmoc --dragon -o $@ $^

dragon/inst.bin : dragon/rf.o dragon/inst.o dragon/system.o main.c

	cmoc --dragon -o $@ $^

dragon/inst.o : inst.c rf.h target/dragon/system.inc | dragon

	cmoc --dragon -c -o $@ $<

dragon/rf.o : rf.c rf.h target/dragon/system.inc | dragon

	cmoc --dragon -c -o $@ $<

dragon/system.o : target/dragon/system.c rf.h target/dragon/system.inc | dragon

	cmoc --dragon -c -o $@ $<

# help
.PHONY : help
help : $(TARGET)-help

# install to local
.PHONY : install
install : $(ORTER) $(ORTERFORTH)

	cp "$(ORTER)" /usr/local/bin/orter
	cp "$(ORTERFORTH)" /usr/local/bin/orterforth


# === TRS-80 Model 100 ===

m100 :

	mkdir $@

m100/hw.co : | m100

	zcc +m100 -subtype=default hw.c -o $@ -create-app


# disc image as C include
model.inc : model.disc | $(ORTER)

	# xxd -i $< > $@
	$(ORTER) hex include model_disc < $< > $@.io
	mv $@.io $@


# === Raspberry Pi Pico ===

pico :

	mkdir $@

.PHONY : pico-build
pico-build : pico/orterforth.uf2

.PHONY : pico-clean
pico-clean :

	rm -rf pico/*


# Pico serial port name
ifeq ($(OPER),cygwin)
PICOSERIALPORT := /dev/ttyS2
endif
ifeq ($(OPER),darwin)
PICOSERIALPORT := /dev/cu.usbmodem123451
endif
ifeq ($(OPER),linux)
PICOSERIALPORT := /dev/ttyACM0
endif

.PHONY : pico-run
pico-run :

	$(ORTER) serial $(PICOSERIALPORT) 115200

pico/Makefile : target/pico/CMakeLists.txt | pico

	cd pico && PICO_SDK_PATH=~/pico-sdk cmake ../target/pico

pico/orterforth.uf2 : \
	pico/Makefile \
	inst.c \
	inst.h \
	main.c \
	model.inc \
	persci.c \
	persci.h \
	rf.c \
	rf.h \
	system.c \
	system.inc

	rm -rf pico/orterforth.*
	cd pico && PICO_SDK_PATH=~/pico-sdk make


# === Sinclair QL ===

# QLOPTION := assembly
QLOPTION := default

ifeq ($(QLOPTION),assembly)
QLDEPS := ql/rf.o ql/rf_m68k.o ql/system.o ql/main.o
QLINC := target/ql/assembly.inc
endif

ifeq ($(QLOPTION),default)
QLDEPS := ql/rf.o ql/system.o ql/main.o
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
	@touch data.disc
	@$(DISC) serial $(SERIALPORT) $(QLSERIALBAUD) model.disc data.disc

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
ql/inst : ql/inst.o $(QLDEPS)

	qld -ms -o $@ $^

# inst executable with serial header
ql/inst.ser : ql/inst | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

# saved binary
ql/orterforth.bin : ql/orterforth.bin.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# saved binary as hex
ql/orterforth.bin.hex : ql/inst.ser ql/loader-inst.ser | $(DISC) $(ORTER)

	@echo "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/loader-inst.ser

	@echo "* Loading installer..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/inst.ser

	# TODO use disc start/stop script
	@echo "* Starting disc and waiting for completion..."
	@touch $@.io
	@$(DISC) serial $(SERIALPORT) $(QLSERIALBAUD) model.disc $@.io & pid=$$! ; \
		scripts/wait-until-saved.sh $@.io ; \
		kill -9 $$pid

	@mv $@.io $@
	@echo "* Done"
	@sleep 1

# saved binary with serial header
ql/orterforth.bin.ser : ql/orterforth.bin | $(ORTER)

	$(ORTER) ql serial-bytes $< > $@

# main program
ql/main.o : main.c rf.h $(QLINC) inst.h | ql

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

ql/rf.s : rf.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -S -c $<

# assembly code
ql/rf_m68k.o : rf_m68k.s | ql

	qcc -o $@ -c $<

# installer
ql/inst.o : inst.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<

# system support
ql/system.o : target/ql/system.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<


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

RC2014OPTION := assembly
#RC2014OPTION := default

ifeq ($(RC2014OPTION),assembly)
RC2014DEPS := rc2014/rf.lib rc2014/inst.lib rc2014/system.lib rc2014/z80.lib
RC2014INC=target/rc2014/assembly.inc
RC2014LIBS := -lrc2014/rf -lrc2014/inst -lrc2014/system -lrc2014/z80
RC2014ORIGIN := 0x9F00
endif
ifeq ($(RC2014OPTION),default)
RC2014DEPS := rc2014/rf.lib rc2014/inst.lib rc2014/system.lib
RC2014INC := target/rc2014/default.inc
RC2014LIBS := -lrc2014/rf -lrc2014/inst -lrc2014/system
RC2014ORIGIN := 0xAB00
endif

.PHONY : rc2014-run
rc2014-run : rc2014/orterforth.ser | $(ORTER)

	# reset and get ready
	@echo "On the RC2014: Connect via serial"
	@echo "               Press reset"
	@read -p "Then press enter to start: " LINE
	sh target/rc2014/reset.sh | $(ORTER) serial -o olfcr -a $(RC2014SERIALPORT) 115200

	# load via serial
	@$(ORTER) serial -o olfcr -e 3 $(RC2014SERIALPORT) 115200 < rc2014/orterforth.ser

	# start interactive session
	@$(ORTER) serial $(RC2014SERIALPORT) 115200

# inst executable
rc2014/inst_CODE.bin : \
	$(RC2014DEPS) \
	z80_memory.asm \
	main.c

	zcc +rc2014 -subtype=basic -clib=new -DRF_TARGET_INC='\"$(RC2014INC)\"' \
		$(RC2014LIBS) \
		-Ca-DCRT_ITERM_TERMINAL_FLAGS=0x0000 \
	 	-Ca-DRF_ORG=0x9000 \
	 	-Ca-DRF_INST_OFFSET=0x5000 \
		-m \
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
		--offset 0x5000 \
		--output $@

# make inst tap from inst bin
rc2014/inst.ihx : rc2014/inst-2.bin

	z88dk-appmake +hex \
		--binfile $< \
		--org 0x9000 \
		--output $@

# both CODE and INST bin files are built by same command
rc2014/inst_INST.bin : rc2014/inst_CODE.bin

# inst code
rc2014/inst.lib : inst.c rf.h $(RC2014INC) inst.h | rc2014

	zcc +rc2014 -clib=new \
		-DRF_TARGET_INC='\"$(RC2014INC)\"' \
		-x -o $@ $< \
		--codeseg=INST \
		--dataseg=INST \
		--bssseg=INST \
		--constseg=INST

# inst serial load file - seems an unreliable approach
rc2014/inst.ser : target/rc2014/hexload.bas rc2014/inst.ihx

	cp target/rc2014/hexload.bas $@.io
	cat rc2014/inst.ihx >> $@.io
	mv $@.io $@

# final binary from hex
rc2014/orterforth : rc2014/orterforth.hex | $(ORTER)

	$(ORTER) hex read < $< > $@.io
	mv $@.io $@

# saved hex result
rc2014/orterforth.hex : target/rc2014/hexload.bas rc2014/inst.ihx | $(DISC) $(ORTER)

	# validate that code does not overlap ORIGIN
	sh target/spectrum/check-memory.sh \
		0x9000 \
		$(RC2014ORIGIN) \
		$(shell $(STAT) rc2014/inst_CODE.bin)

	# reset and get ready
	@echo "On the RC2014: Connect via serial"
	@echo "               Press reset"
	@read -p "Then press enter to start: " LINE
	sh target/rc2014/reset.sh | $(ORTER) serial -o olfcr -a $(RC2014SERIALPORT) 115200

	# load inst via hexload
	$(ORTER) serial -o olfcr -e 3 $(RC2014SERIALPORT) 115200 < target/rc2014/hexload.bas
	$(ORTER) serial -o olfcr -e 3 $(RC2014SERIALPORT) 115200 < rc2014/inst.ihx

	# empty disc
	rm -f $@.io
	touch $@.io

	# start disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) serial $(RC2014SERIALPORT) 115200 model.disc $@.io

	# wait for save
	sh scripts/wait-until-saved.sh $@.io

	# stop disc
	sh scripts/stop.sh disc.pid

	# file complete
	mv $@.io $@

# final binary as IHEX
rc2014/orterforth.ihx : rc2014/orterforth

	z88dk-appmake +hex --org 0x9000 --binfile $< --output $@

# serial load file
rc2014/orterforth.ser : target/rc2014/hexload.bas rc2014/orterforth.ihx

	cp target/rc2014/hexload.bas $@.io
	cat rc2014/orterforth.ihx >> $@.io
	mv $@.io $@

# base orterforth code
rc2014/rf.lib : rf.c rf.h $(RC2014INC) | rc2014

	zcc +rc2014 -clib=new -DRF_TARGET_INC='\"$(RC2014INC)\"' -x -o $@ $<

# system code
rc2014/system.lib : target/rc2014/system.c rf.h $(RC2014INC) | rc2014

	zcc +rc2014 -clib=new -DRF_TARGET_INC='\"$(RC2014INC)\"' -x -o $@ $<

# Z80 assembly optimised code
rc2014/z80.lib : rf_z80.asm | rc2014

	zcc +rc2014 -clib=new \
		-Ca-DRF_ORIGIN=$(RC2014ORIGIN) \
		-x -o $@ \
		$<

# Raspberry Pi 1 - armv6l assembly source is (currently) the same as armv7l
rf_armv6l.s : rf_armv7l.s

	cp -p $< $@

# ROM file dir
roms : 

	mkdir $@

# BBC Micro ROM files dir
roms/bbcb : | roms

	mkdir $@

# BBC Micro ROM files
roms/bbcb/% : | roms/bbcb

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

# Dragon 64 ROM files
roms/dragon64/% :

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

# config option
SPECTRUMOPTION := assembly
# SPECTRUMOPTION := assembly-z88dk
# SPECTRUMOPTION := default

SPECTRUMLIBSALL := \
	-lmzx_tiny \
	-lndos \
	-lspectrum/rf \
	-lspectrum/inst \
	-lspectrum/rf_system

# minimal ROM-based
ifeq ($(SPECTRUMOPTION),assembly)
# uses Interface 1 ROM for RS232
SPECTRUMLIBS := \
	$(SPECTRUMLIBSALL) \
	-lspectrum/rf_z80 \
	-pragma-redirect:fputc_cons=fputc_cons_rom_rst
# include file
SPECTRUMINC := target/spectrum/assembly.inc
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
ifeq ($(SPECTRUMOPTION),assembly-z88dk)
# include file
SPECTRUMINC := target/spectrum/assembly.inc
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
ifeq ($(SPECTRUMOPTION),default)
# include file
SPECTRUMINC := target/spectrum/default.inc
# requires z88dk RS232 library
SPECTRUMLIBS := \
	$(SPECTRUMLIBSALL) \
	-lrs232if1
# ORG starts at non-contended memory, 0x8000, for performance
SPECTRUMORG := 0x8000
# ORIGIN higher, 0x9B00, C code is larger as uses z88dk libs and pure C impl
SPECTRUMORIGIN := 0x9D00
# C impl of system dependent code uses z88dk libs
SPECTRUMSYSTEM := target/spectrum/system.c
# locates inst code at 0xC800
SPECTRUMINSTOFFSET := 18432
# no CPU hook for z88dk RS232 code so use Fuse
SPECTRUMIMPL := fuse
endif

# run Spectrum build
ifeq ($(SPECTRUMIMPL),fuse)
SPECTRUMMACHINE := fuse
endif
ifeq ($(SPECTRUMIMPL),mame)
SPECTRUMMACHINE := mame
endif
ifeq ($(SPECTRUMIMPL),superzazu)
# default is to use fast build but run in Fuse
SPECTRUMMACHINE := fuse
endif

.PHONY : spectrum-run
ifeq ($(SPECTRUMMACHINE),fuse)
spectrum-run : \
	spectrum/orterforth.tap \
	$(DR0) | \
	$(DISC) \
	roms/spectrum/if1-2.rom \
	roms/spectrum/spectrum.rom \
	spectrum/fuse-rs232-rx \
	spectrum/fuse-rs232-tx
endif
ifeq ($(SPECTRUMMACHINE),mame)
spectrum-run : \
	spectrum/orterforth.tap \
	$(DR0) | \
	$(DISC) \
	roms/spectrum/if1-2.rom \
	roms/spectrum/spectrum.rom
endif
ifeq ($(SPECTRUMMACHINE),real)
spectrum-run : \
	spectrum/orterforth.ser \
	target/spectrum/load-serial.bas \
	spectrum/orterforth.tap \
	$(DR0) | \
	$(DISC) \
	$(ORTER)
endif

ifeq ($(SPECTRUMMACHINE),real)
	@echo "On the Spectrum type: FORMAT \"b\";$(SERIALBAUD)"
	@echo "                      LOAD *\"b\""
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	$(ORTER) serial -e 2 $(SERIALPORT) $(SERIALBAUD) < target/spectrum/load-serial.bas

	@echo "* Loading orterforth..."
	$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < spectrum/orterforth.ser
endif

	# start disc
	touch data.disc
ifeq ($(SPECTRUMMACHINE),fuse)
	sh scripts/start.sh spectrum/fuse-rs232-tx spectrum/fuse-rs232-rx disc.pid $(DISC) fuse $(DR0) data.disc
endif
ifeq ($(SPECTRUMMACHINE),mame)
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 5705 $(DR0) data.disc
endif
ifeq ($(SPECTRUMMACHINE),real)
	@echo "* Starting disc..."
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) data.disc
endif

ifeq ($(SPECTRUMMACHINE),fuse)
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
endif
ifeq ($(SPECTRUMMACHINE),mame)
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

	# stop disc
	sh scripts/stop.sh disc.pid
endif

# other Spectrum libs
spectrum/%.lib : %.c | spectrum

	zcc +zx -DRF_TARGET_INC='\"$(SPECTRUMINC)\"' -x -o spectrum/$* $<

# Fuse serial named pipe
spectrum/fuse-rs232-rx : | spectrum

	mkfifo $@

# Fuse serial named pipe
spectrum/fuse-rs232-tx : | spectrum

	mkfifo $@

# inst executable
spectrum/inst.bin : \
	spectrum/rf.lib \
	spectrum/inst.lib \
	spectrum/rf_system.lib \
	spectrum/rf_z80.lib \
	z80_memory.asm \
	main.c

	zcc +zx \
 		-DRF_TARGET_INC='\"$(SPECTRUMINC)\"' \
 		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-Ca-DRF_ORG=$(SPECTRUMORG) \
		-Ca-DRF_INST_OFFSET=$(SPECTRUMINSTOFFSET) \
		$(SPECTRUMLIBS) \
		-pragma-define:CRT_ENABLE_STDIO=0 \
		-pragma-define:CRT_INITIALIZE_BSS=0 \
		-m \
		-o $@ \
		z80_memory.asm main.c

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
ifeq ($(SPECTRUMIMPL),fuse)
SPECTRUMINSTDEPS := spectrum/inst-2.tap $(DISC) $(ORTER) $(FUSE) roms/spectrum/if1-2.rom roms/spectrum/spectrum.rom spectrum/fuse-rs232-rx spectrum/fuse-rs232-tx
endif
ifeq ($(SPECTRUMIMPL),superzazu)
SPECTRUMINSTDEPS := spectrum/inst-2.tap $(SYSTEM)/emulate_spectrum roms/spectrum/if1-2.rom roms/spectrum/spectrum.rom
endif
ifeq ($(SPECTRUMIMPL),real)
SPECTRUMINSTDEPS := spectrum/inst-2.ser $(DISC) $(ORTER)
endif

spectrum/orterforth.bin.hex : model.disc $(SPECTRUMINSTDEPS)

	# validate that code does not overlap ORIGIN
	sh target/spectrum/check-memory.sh \
		$(SPECTRUMORG) \
		$(SPECTRUMORIGIN) \
		$(shell $(STAT) spectrum/inst.bin)

	# empty disc in drive 1 for hex installed file
	rm -f $@.io
	touch $@.io

ifeq ($(SPECTRUMIMPL),fuse)
	# start disc
	sh scripts/start.sh spectrum/fuse-rs232-tx spectrum/fuse-rs232-rx disc.pid $(DISC) fuse model.disc $@.io

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
		--tape spectrum/inst-2.tap

	# wait for install and save
	sh scripts/wait-until-saved.sh $@.io

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
	@$(ORTER) serial -a $(SERIALPORT) $(SERIALBAUD) < spectrum/inst-2.ser

	@echo "* Starting disc and waiting for completion..."
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) model.disc $@.io & pid=$$! ; \
		scripts/wait-until-saved.sh $@.io ; \
		kill -9 $$pid
endif

	# copy result
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
 		-DRF_TARGET_INC='\"$(SPECTRUMINC)\"' \
 		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$<

# inst code, which is located to be overwritten when complete
spectrum/inst.lib : inst.c rf.h | spectrum

	zcc +zx \
 		-DRF_TARGET_INC='\"$(SPECTRUMINC)\"' \
		-DRF_ORG=$(SPECTRUMORG) \
		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$< \
		--codeseg=INST --dataseg=INST --bssseg=INST --constseg=INST

# system code, which may be C or assembler
spectrum/rf_system.lib : $(SPECTRUMSYSTEM) | spectrum

	zcc +zx \
 		-DRF_TARGET_INC='\"$(SPECTRUMINC)\"' \
		-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$<

# Z80 assembly optimised code
spectrum/rf_z80.lib : rf_z80.asm | spectrum

	zcc +zx \
		-Ca-DRF_ORIGIN=$(SPECTRUMORIGIN) \
		-x -o $@ \
		$<

# run test disc
.PHONY : test
test : $(TARGET)-test

tools :

	mkdir $@

tools/z80/z80.c tools/z80/z80.h : | tools

	cd tools && git clone https://github.com/superzazu/z80.git

tools/zx81putil/zx81putil.c : | tools

	cd tools && git clone https://github.com/mcleod-ideafix/zx81putil.git

# uninstall from local
.PHONY : uninstall
uninstall :

	rm -f /usr/local/bin/orter
	rm -f /usr/local/bin/orterforth

zx81 :

	mkdir $@

.PHONY : zx81-run
zx81-run : zx81/inst.tzx | zx81/jtyone.jar

	java -jar zx81/jtyone.jar zx81/inst.tzx@0 -scale 3 -machine ZX81

zx81/%.tzx : zx81/%.P $(SYSTEM)/zx81putil

	$(SYSTEM)/zx81putil -tzx $<

zx81/inst.bin zx81/inst.P : zx81/rf.lib zx81/system.lib zx81/inst.lib main.c

	zcc +zx81 -lm -lzx81/rf -lzx81/system -lzx81/inst -create-app -m -o zx81/inst.bin main.c

zx81/inst.lib : inst.c rf.h | zx81

	zcc +zx81 -x -o $@ $<

zx81/jtyone.jar : | zx81

	curl --output $@ http://www.zx81stuff.org.uk/zx81/jtyone.jar

zx81/rf.lib : rf.c rf.h target/zx81/system.inc | zx81

	zcc +zx81 -x -o $@ $<

zx81/system.lib : target/zx81/system.c rf.h | zx81

	zcc +zx81 -x -o $@ $<
