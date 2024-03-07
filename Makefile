# C compiler options
CFLAGS += -Wall -Werror -std=c89 -ansi -Wpedantic -Wextra

# global defaults
INFO           := printf '* \033[1;33m%s\033[0;0m\n'
WARN           := printf '* \033[1;35m%s\033[0;0m\n'
CHECKMEMORY    := $(INFO) 'Checking memory limits' ; sh scripts/check-memory.sh
DR0=forth/library.img
DR1=forth/data.img
COMPLETEDR1FILE = mv $@.io $@ ; $(INFO) 'Done'
EMPTYDR1FILE   := $(INFO) 'Clearing DR1'           ; printf '' >
MAMEOPTS       := -rompath roms -video opengl -resolution 1024x768 -skip_gameinfo -nomax -window
PROMPT         := sh scripts/prompt.sh
SERIALBAUD     := 9600
START          := sh scripts/start.sh /dev/stdin /dev/stdout
STARTMAME      := $(INFO) 'Starting MAME'          ; $(START) mame.pid mame
STARTDISCMSG   := $(INFO) 'Starting disc'
STOPDISC       := $(INFO) 'Stopping disc'          ; sh scripts/stop.sh disc.pid
STOPMAME       := $(INFO) 'Stopping MAME'          ; sh scripts/stop.sh mame.pid
WAITUNTILSAVED := $(INFO) 'Waiting until saved'    ; sh scripts/wait-until-saved.sh

# local OS
UNAME_S := $(shell uname -s)
ifneq ($(filter CYGWIN%,$(UNAME_S)),)
	LDFLAGS += -t gcc.ld
	OPER := cygwin
	SERIALPORT := /dev/ttyS2
	STAT := stat -c %s
endif
ifeq ($(UNAME_S),Darwin)
	OPER := darwin
	PLAY := afplay
	SERIALPORT := /dev/cu.usbserial-FT2XIBOF
	STAT := stat -f%z
endif
ifeq ($(UNAME_S),Linux)
	LDFLAGS += -t gcc.ld
	OPER := linux
	PLAY := aplay
	SERIALPORT := /dev/ttyUSB0
	STAT := stat -c %s
endif
ifneq ($(filter MINGW%,$(UNAME_S)),)
	CC := gcc
	OPER := mingw
endif

# local processor architecture
UNAME_M := $(shell uname -m)
PROC := $(UNAME_M)
# 32 bit kernel on 64 bit host (e.g., container)
ifeq (${OPER},linux)
ifeq (${PROC},x86_64)
ifeq ($(shell getconf LONG_BIT),32)
	PROC := i686
endif
endif
# Raspberry Pi 2 onwards
ifeq (${PROC},armv7l)
	PROC := armv6l
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

# scripts for disc
STARTDISC := $(STARTDISCMSG) && $(START) disc.pid $(DISC)
STARTDISCTCP := $(STARTDISC) tcp 5705

# local system object files
SYSTEMDEPS := \
	$(SYSTEM)/inst.o \
	$(SYSTEM)/persci.o \
	$(SYSTEM)/system.o

# default target
.PHONY : default
default : build

# local system disc server executable
$(DISC) : \
	$(SYSTEM)/orter_io.o \
	$(SYSTEM)/orter_pty.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_tcp.o \
	$(SYSTEM)/persci.o \
	disc.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^ -lutil

# === LOCAL SYSTEM ===

# SYSTEMOPTION := assembly
SYSTEMOPTION := default
ifeq ($(TARGET),$(SYSTEM))
ifneq ($(OPTION),)
SYSTEMOPTION := $(OPTION)
endif
endif

# assembly option config:
ifeq ($(SYSTEMOPTION),assembly)
# add the assembly code to deps
SYSTEMDEPS += $(SYSTEM)/rf_$(PROC).o
# tell C code it is there
CPPFLAGS += -DRF_ASSEMBLY
endif

# default option config:
ifeq ($(SYSTEMOPTION),default)
# add C code to deps
SYSTEMDEPS += $(SYSTEM)/rf.o
endif

# local system executable
$(ORTERFORTH) : $(SYSTEMDEPS) main.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^ $(LDFLAGS)

# local system build dir
$(SYSTEM) :

	mkdir $@

# build all local system executables
.PHONY : $(SYSTEM)-build
$(SYSTEM)-build : \
	$(DISC) \
	$(ORTER) \
	$(ORTERFORTH)

# clean
.PHONY : $(TARGET)-clean
$(TARGET)-clean :

	rm -rf $(TARGET)/*
	rm -f model.img
	rm -f model.inc

# build and run
.PHONY : $(SYSTEM)-run
$(SYSTEM)-run : $(ORTERFORTH) $(DR0) $(DR1)

	@$^

$(SYSTEM)/inst.o : inst.c model.inc rf.h system.inc persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/persci.o : persci.c persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/rf.o : rf.c rf.h system.inc | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/rf_$(PROC).o : rf_$(PROC).s | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(SYSTEM)/system.o : system.c rf.h system.inc persci.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# audio for tape load
.PHONY : audio
audio : $(TARGET)/orterforth.wav

# help
.PHONY : $(TARGET)-help
$(TARGET)-help :

	@if [ "$(TARGET)" = "$(SYSTEM)" ] ; then more help.txt ; else more target/$(TARGET)/help.txt ; fi

# Forth source file to disc image
%.img : %.fs | $(DISC)

	$(DISC) create < $< > $@.io
	mv $@.io $@

# build
.PHONY : build
build : $(TARGET)-build

# clean
.PHONY : clean
clean : $(TARGET)-clean

# empty disc image to use as default DR1
forth/data.img :

	touch $@

# run disc on physical serial port
.PHONY : disc
disc : $(DISC) $(DR0) $(DR1)

	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) $(DR1)

# help
.PHONY : help
help : $(TARGET)-help

include orter/orter.mk

include target/apple2/apple2.mk

include target/bbc/bbc.mk

include target/c64/c64.mk

include target/dragon/dragon.mk

#include target/esp32c3/esp32c3.mk

include target/m100/m100.mk

include target/pico/pico.mk

include target/ql/ql.mk

include target/rc2014/rc2014.mk

include target/spectrum/spectrum.mk

include target/z88/z88.mk

include target/zx81/zx81.mk

# symlink to local
.PHONY : link
link : $(ORTER) $(ORTERFORTH)

	ln -fs "$$(pwd)/$(ORTER)" /usr/local/bin/orter
	ln -fs "$$(pwd)/$(ORTERFORTH)" /usr/local/bin/orterforth

# install to local
.PHONY : install
install : $(ORTER) $(ORTERFORTH)

	cp "$(ORTER)" /usr/local/bin/orter
	cp "$(ORTERFORTH)" /usr/local/bin/orterforth

# disc image to C include
model.inc : model.img | $(ORTER)

	# xxd -i $< > $@.io
	$(ORTER) hex include model_img < $< > $@.io
	mv $@.io $@

# general rule for missing ROM files
roms/% :

	@[ -f $@ ] || (echo "ROM file required: $@" && exit 1)

# run
.PHONY : run
run : $(TARGET)-run

# run working script
.PHONY : script
script : scripts/script.sh

	@[ -f $< ] && sh $<

scripts/script.sh :

	@echo "Create the file $@ for your working script and run it using: make script"

# basic test
.PHONY : test
test : $(ORTERFORTH) forth/test.img

	echo 'EMPTY-BUFFERS 1 LOAD MON' | $(ORTERFORTH) forth/test.img

# uninstall from local
.PHONY : uninstall
uninstall :

	rm -f /usr/local/bin/orter
	rm -f /usr/local/bin/orterforth
