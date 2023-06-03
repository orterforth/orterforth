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
pico-run : | $(ORTER) $(DISC)

	$(DISC) mux $(PICOSERIALPORT) 115200 $(DR0) $(DR1)

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
	target/pico/system.c \
	system.inc

	rm -rf pico/orterforth.*
	cd pico && PICO_SDK_PATH=~/pico-sdk make
