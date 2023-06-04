# C compiler options
CFLAGS += -Wall -Werror -std=c89 -ansi -Wpedantic
# CFLAGS += -Wall -Werror -std=c89 -ansi -Wpedantic -Wextra
# CFLAGS += -Wall -Werror -std=c89 -ansi -Wpedantic -Wextra -Wmissing-prototypes -Wstrict-prototypes -Wold-style-definition

# global defaults
CHECKMEMORY := printf '* \033[1;33mChecking memory limits\033[0;0m\n' ; sh scripts/check-memory.sh
DR0=library.img
DR1=data.img
MAMEOPTS := -rompath roms -video opengl -resolution 1024x768 -skip_gameinfo -nomax -window
SERIALBAUD := 9600
START := sh scripts/start.sh /dev/stdin /dev/stdout
STARTMAME := printf '* \033[1;33mStarting MAME\033[0;0m\n' ; $(START) mame.pid mame
STARTDISCMSG := printf '* \033[1;33mStarting disc\033[0;0m\n'
STOPDISC := printf '* \033[1;33mStopping disc\033[0;0m\n' ; sh scripts/stop.sh disc.pid
STOPMAME := printf '* \033[1;33mStopping MAME\033[0;0m\n' ; sh scripts/stop.sh mame.pid
WAITUNTILSAVED := printf '* \033[1;33mWaiting until saved\033[0;0m\n' ; sh scripts/wait-until-saved.sh

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
	SERIALPORT := /dev/cu.usbserial-FT2XIBOF
	STAT := stat -f%z
endif
ifeq ($(UNAME_S),Linux)
	LDFLAGS += -t gcc.ld
	OPER := linux
	SERIALPORT := /dev/ttyUSB0
	STAT := stat -c %s
endif
# TODO mingw32 support
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
STARTDISC := $(STARTDISCMSG) ; $(START) disc.pid $(DISC)
STARTDISCTCP := $(STARTDISC) tcp 5705

# local system object files
SYSTEMDEPS := \
	$(SYSTEM)/inst.o \
	$(SYSTEM)/persci.o \
	$(SYSTEM)/rf.o \
	$(SYSTEM)/system.o

# default target
.PHONY : default
default : build

# local system disc server executable
$(DISC) : \
	$(SYSTEM)/orter_io.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_spectrum.o \
	$(SYSTEM)/orter_tcp.o \
	$(SYSTEM)/persci.o \
	disc.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

# === LOCAL SYSTEM ===

# SYSTEMOPTION := assembly
SYSTEMOPTION := default
ifeq ($(TARGET),$(SYSTEM))
ifneq ($(OPTION),)
SYSTEMOPTION := $(OPTION)
else
endif

# local system assembly option config:
ifeq ($(SYSTEMOPTION),assembly)
# add the assembly code to deps
SYSTEMDEPS += $(SYSTEM)/rf_$(PROC).o
# tell C code it is there
CPPFLAGS += -DRF_ASSEMBLY
endif

# local system executable
$(ORTERFORTH) : $(SYSTEMDEPS) main.c

	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $^

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
.PHONY : $(SYSTEM)-clean
$(SYSTEM)-clean :

	rm -f $(SYSTEM)/*
	rm -f model.img
	rm -f model.inc

# build and run
.PHONY : $(SYSTEM)-run
$(SYSTEM)-run : $(ORTERFORTH) $(DR0) $(DR1)

	@$< $(DR0) $(DR1)

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
data.img :

	touch $@

# run disc on physical serial port
.PHONY : disc
disc : $(DISC) $(DR0) $(DR1)

	$(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) $(DR1)

# help
.PHONY : help
help : $(TARGET)-help

include orter/orter.mk

include target/bbc/bbc.mk

include target/c64/c64.mk

include target/dragon/dragon.mk

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

	ln -fs "$(shell pwd)/$(ORTER)" /usr/local/bin/orter
	ln -fs "$(shell pwd)/$(ORTERFORTH)" /usr/local/bin/orterforth

# install to local
.PHONY : install
install : $(ORTER) $(ORTERFORTH)

	cp "$(ORTER)" /usr/local/bin/orter
	cp "$(ORTERFORTH)" /usr/local/bin/orterforth

# disc image to C include
model.inc : model.img | $(ORTER)

	# xxd -i $< > $@.io
	$(ORTER) hex include model_disc < $< > $@.io
	mv $@.io $@

# ROM file dir
roms : 

	mkdir $@

# run
.PHONY : run
run : $(TARGET)-run

rx :

	mkfifo $@

# run working script
.PHONY : script
script :

	@[ -f scripts/script.sh ] || (echo "Create the file scripts/script.sh for your working script and run it using: make script" && exit 1)
	sh scripts/script.sh

# basic test
.PHONY : test
test : $(ORTERFORTH) $(DR0)

	echo 'VLIST 3 22 INDEX CR MON' | $(ORTERFORTH) $(DR0)

tx :

	mkfifo $@

# uninstall from local
.PHONY : uninstall
uninstall :

	rm -f /usr/local/bin/orter
	rm -f /usr/local/bin/orterforth
