AMIGALOADINGMETHOD=disk
# AMIGALOADINGMETHOD=serial
AMIGAMACHINE=fsuae
# AMIGAMACHINE=real
# AMIGAMODEL=A500
AMIGAMODEL=A500+
AMIGAOPTION=assembly
# AMIGAOPTION=default
ifeq ($(TARGET),amiga)
ifneq ($(OPTION),)
AMIGAOPTION := $(OPTION)
endif
endif

AMIGADEPS := amiga/amiga.o amiga/inst.o amiga/io.o amiga/main.o
ifeq ($(AMIGAOPTION),assembly)
AMIGADEPS += amiga/rf_m68k.o
endif
ifeq ($(AMIGAOPTION),default)
AMIGADEPS += amiga/rf.o
endif

ifeq ($(AMIGAMACHINE),fsuae)
AMIGASERIALOPTS=tcp client 5705
endif
ifeq ($(AMIGAMACHINE),real)
AMIGASERIALOPTS=serial $(SERIALPORT) $(SERIALBAUD)
endif

AMIGALOADSERIAL=$(WARN) "NB set serial handshaking to RTS/CTS" && \
	$(PROMPT) "Open Shell and type: type ser: > ram:$(<F).rexx" && \
	$(INFO) "Sending $<.rexx" && \
	(cat $<.rexx amiga/long && sleep 10) | $(ORTER) $(AMIGASERIALOPTS) && \
	$(PROMPT) "Type Ctrl+C" && \
	$(INFO) "Breaking serial send" && \
	cat amiga/long | $(ORTER) $(AMIGASERIALOPTS) && \
	$(PROMPT) "Type: rx ram:$(<F)" && \
	$(INFO) "Sending $<" && \
	(cat $< amiga/long amiga/long amiga/long amiga/long && sleep 2) | $(ORTER) $(AMIGASERIALOPTS)

AMIGASTARTFSUAE=$(INFO) "Starting FS-UAE" && \
	$(START) fsuae.pid fs-uae --amiga-model=$(AMIGAMODEL) --floppy-drive-1=$<.adf --serial-port=tcp://127.0.0.1:5705

AMIGAVBCCHOME=/opt/vbcc/sdk
AMIGAVBCCOPTS=-L$(AMIGAVBCCHOME)/NDK_3.9/Include/linker_libs \
	-I$(AMIGAVBCCHOME)/NDK_3.9/Include/include_h \
	+kick13
ifeq ($(AMIGAOPTION),assembly)
AMIGAVBCCOPTS += -DRF_ASSEMBLY
endif
AMIGAVC=PATH=$(AMIGAVBCCHOME)/vbcc/bin:$$PATH \
	VBCC=$(AMIGAVBCCHOME)/vbcc \
	vc $(AMIGAVBCCOPTS)

amiga :

	mkdir $@

.PHONY : amiga-build
amiga-build : amiga/inst.adf

.PHONY : amiga-hw
amiga-hw : amiga/hw amiga/hw.adf amiga/hw.rexx | amiga/long $(ORTER)

ifeq ($(AMIGAMACHINE),fsuae)
	@$(AMIGASTARTFSUAE)
	@sleep 3
endif
ifeq ($(AMIGALOADINGMETHOD),disk)
ifeq ($(AMIGAMACHINE),real)
	@$(WARN) "Physical disk load not supported"
	@exit 1
endif
	@$(WARN) "Open Shell and execute df1:hw"
endif
ifeq ($(AMIGALOADINGMETHOD),serial)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(WARN) "NB FS-UAE serial load fails due to a leading 0xF2 in the received file"
endif
	@$(AMIGALOADSERIAL)
	@$(WARN) "Type: ram:hw"
endif

.PHONY : amiga-run
amiga-run : amiga/inst amiga/inst.adf amiga/inst.rexx model.img | amiga/long $(DISC) $(DR0) $(DR1) $(ORTER)

ifeq ($(AMIGAMACHINE),fsuae)
	@$(AMIGASTARTFSUAE)
	@sleep 3
	@$(WARN) "NB set serial handshaking to None"
endif
ifeq ($(AMIGALOADINGMETHOD),disk)
ifeq ($(AMIGAMACHINE),real)
	@$(WARN) "Physical disk load not supported"
	@exit 1
endif
	@$(WARN) "Open Shell and execute df1:inst"
endif
ifeq ($(AMIGALOADINGMETHOD),serial)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(WARN) "NB FS-UAE serial load fails due to a leading 0xF2 in the received file"
endif
	@$(AMIGALOADSERIAL)
	@$(WARN) "Type: ram:inst"
endif
	@$(EMPTYDR1FILE) amiga/orterforth.img
	@$(STARTDISC) $(AMIGASERIALOPTS) model.img amiga/orterforth.img
	@$(WAITUNTILSAVED) amiga/orterforth.img
	@$(STOPDISC)
	@$(INFO) "Starting disc $(DR0) $(DR1)"
	@$(DISC) $(AMIGASERIALOPTS) $(DR0) $(DR1)

amiga/%.adf : amiga/%

	xdftool $@ format $(<F)
	xdftool $@ write $< $(<F)

amiga/%.o : %.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/%.rexx : amiga/% target/amiga/receive.rexx

	printf "/* $(@F) modified with pre-set values */\n" > $@
	printf "file = 'ram:$(<F)'\n" >> $@
	printf "size = $$($(STAT) $<)\n" >> $@
	cat target/amiga/receive.rexx >> $@

amiga/amiga.o : target/amiga/amiga.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/hw : amiga/hw.o

	$(AMIGAVC) $< -lamiga -lauto -o $@

amiga/inst : $(AMIGADEPS)

	$(AMIGAVC) $^ -static -lamiga -lauto -M -v -o $@

amiga/long :

	# repeat HUNK_END and use this to flush serial buffer
	for i in $$(seq 0 127) ; do printf '\0\0\003\362' >> $@ ; done

amiga/rf_m68k.o : amiga/rf_m68k.s

	$(AMIGAVC) -c $< -o $@

amiga/rf_m68k.s : rf_m68k.s | amiga

	cp $< $@.io
	sed -i 's/\.sect \.text/section "CODE",code/' $@.io
	sed -i 's/\.sect \.data/section "DATA",data/' $@.io
	sed -i 's/\.align 2/cnop 0,4/' $@.io
	sed -i 's/\.extern/public/' $@.io
	mv $@.io $@
