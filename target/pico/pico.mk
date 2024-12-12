# === Raspberry Pi Pico ===

PICOOPTION := default
#PICOOPTION := assembly
# PICOOPTION := default
ifeq ($(TARGET),pico)
ifneq ($(OPTION),)
PICOOPTION := $(OPTION)
endif
endif

PICOCMAKEOPTION := -DRF_ASSEMBLY=OFF
ifeq ($(PICOOPTION),assembly)
PICOCMAKEOPTION := -DRF_ASSEMBLY=ON
endif

pico :

	mkdir $@

.PHONY : pico-build
pico-build : pico/orterforth.uf2

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
pico-run : | $(ORTER) $(DISC) $(DR0) $(DR1)

	$(DISC) mux $(PICOSERIALPORT) 115200 $(DR0) $(DR1)

pico/Makefile : target/pico/CMakeLists.txt | pico

	cd pico && PICO_SDK_PATH=~/.pico-sdk/sdk/2.1.0 cmake -DPICO_BOARD=pico2 $(PICOCMAKEOPTION) ../target/pico

pico/orterforth.uf2 : \
	pico/Makefile \
	inst.c \
	io.c \
	main.c \
	model.inc \
	mux.c \
	mux.h \
	persci.c \
	persci.h \
	rf.c \
	rf.h \
	rf_armm0.s \
	target/pico/system.c \
	system.inc

	rm -rf pico/orterforth.*
	cd pico && PICO_SDK_PATH=~/.pico-sdk/sdk/2.1.0 make
