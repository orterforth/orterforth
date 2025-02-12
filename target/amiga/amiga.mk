# === Commodore Amiga ===

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

AMIGADEPS := amiga/amiga.o amiga/io.o amiga/main.o
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

AMIGASERIAL := $(ORTER) $(AMIGASERIALOPTS)
AMIGASERIALBREAK := \
	$(PROMPT) "Type Ctrl+C" && \
	$(INFO) "Breaking serial send" && \
	cat amiga/long | $(AMIGASERIAL)

ifeq ($(AMIGAMODEL),A500)
AMIGAWORKBENCH=workbench1.3.adf
endif
ifeq ($(AMIGAMODEL),A500+)
AMIGALOADSERIAL=$(WARN) "NB set serial handshaking to RTS/CTS" && \
	$(PROMPT) "Open Shell and type: type ser: > ram:$(<F).rexx" && \
	$(INFO) "Sending $<.rexx" && \
	(cat $<.rexx amiga/long && sleep 10) | $(AMIGASERIAL) && \
	$(AMIGASERIALBREAK) && \
	$(PROMPT) "Type: rx ram:$(<F)" && \
	$(INFO) "Sending $<" && \
	(cat $< amiga/long amiga/long amiga/long amiga/long && sleep 10) | $(AMIGASERIAL)
AMIGAWORKBENCH=workbench2.05.adf
endif

AMIGASTARTFSUAE=$(INFO) "Starting FS-UAE" && \
	$(START) amiga/machine.pid fs-uae --amiga-model=$(AMIGAMODEL) --floppy-drive-0=$(AMIGAWORKBENCH) --floppy-drive-0=extras1.3.adf --serial-port=tcp://127.0.0.1:5705

AMIGASTOPFSUAE := $(INFO) "Stopping FS-UAE" && sh scripts/stop.sh amiga/machine.pid

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

ifeq ($(AMIGALOADINGMETHOD),disk)
AMIGAINSTDEPS := amiga/inst amiga/inst.adf model.img | amiga/long $(DISC) $(ORTER)
AMIGARUNDEPS := amiga/orterforth amiga/orterforth.adf | $(DISC) $(DR0) $(DR1)
AMIGASTARTFSUAE += --floppy-drive-1=$<.adf
endif
ifeq ($(AMIGALOADINGMETHOD),serial)
AMIGAINSTDEPS := amiga/inst amiga/inst.bas amiga/inst.rexx model.img | amiga/long $(DISC) $(ORTER)
AMIGARUNDEPS := amiga/orterforth amiga/orterforth.bin amiga/orterforth.bin.bas amiga/orterforth.bin.rexx amiga/orterforth.bas amiga/orterforth.rexx | amiga/long $(DISC) $(DR0) $(DR1)
endif

.PHONY : amiga-build
amiga-build : $(AMIGARUNDEPS)

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
amiga-run : $(AMIGARUNDEPS)

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
	@$(WARN) "Open Shell and execute: copy df1: to ram: <enter>"
	@$(WARN) "                        ram:orterforth <enter>"
endif
ifeq ($(AMIGALOADINGMETHOD),serial)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(WARN) "NB FS-UAE serial load fails due to a leading 0xF2 in the received file"
endif
ifeq ($(AMIGAMODEL),A500)
	@$(PROMPT) "Open Shell and type: type ser: to ram:orterforth.bas"
	@$(INFO) "Sending amiga/orterforth.bas"
	@(cat amiga/orterforth.bas amiga/long && sleep 15) | $(AMIGASERIAL)
	@$(AMIGASERIALBREAK)
	@$(PROMPT) "Insert Extras disk and type: amigabasic ram:orterforth.bas"
	@$(INFO) "Sending amiga/orterforth"
	@(cat amiga/orterforth amiga/long amiga/long amiga/long amiga/long && sleep 10) | $(AMIGASERIAL)
	@$(PROMPT) "Type: type ser: > ram:bin.bas"
	@$(INFO) "Sending amiga/orterforth.bin.bas"
	@(cat amiga/orterforth.bin.bas amiga/long && sleep 15) | $(AMIGASERIAL)
	@$(AMIGASERIALBREAK)
	@$(PROMPT) "Type: amigabasic ram:bin.bas"
	@$(INFO) "Sending amiga/orterforth.bin"
	@(cat amiga/orterforth.bin amiga/long amiga/long amiga/long amiga/long && sleep 10) | $(AMIGASERIAL)
	@$(WARN) "Now type: ram:orterforth <enter>"
endif
ifeq ($(AMIGAMODEL),A500+)
	@$(PROMPT) "Open Shell and type: type ser: > ram:orterforth.rexx"
	@$(INFO) "Sending amiga/orterforth.rexx"
	@(cat amiga/orterforth.rexx amiga/long && sleep 15) | $(AMIGASERIAL)
	@$(AMIGASERIALBREAK)
	@$(PROMPT) "Type: rx ram:orterforth"
	@$(INFO) "Sending amiga/orterforth"
	@(cat amiga/orterforth amiga/long amiga/long amiga/long amiga/long && sleep 10) | $(AMIGASERIAL)
	@$(PROMPT) "Type: type ser: > ram:bin.rexx"
	@$(INFO) "Sending amiga/orterforth.bin.rexx"
	@(cat amiga/orterforth.bin.rexx amiga/long && sleep 15) | $(AMIGASERIAL)
	@$(AMIGASERIALBREAK)
	@$(PROMPT) "Type: rx ram:bin"
	@$(INFO) "Sending amiga/orterforth.bin"
	@(cat amiga/orterforth.bin amiga/long amiga/long amiga/long amiga/long && sleep 10) | $(AMIGASERIAL)
	@$(WARN) "Now type: ram:orterforth <enter>"
endif
endif
	@$(INFO) "Starting disc $(DR0) $(DR1)"
	@$(DISC) $(AMIGASERIALOPTS) $(DR0) $(DR1)

amiga/%.adf : amiga/%

	xdftool $@ format $(<F)
	xdftool $@ write $< $(<F)

amiga/%.bas : amiga/% target/amiga/receive.bas

	printf "' $(@F) modified with pre-set values\n" > $@
	printf "file"'$$'" = "'"'"ram:$(<F)"'"'"\n" >> $@
	printf "size& = $$($(STAT) $<)\n" >> $@
	cat target/amiga/receive.bas >> $@

amiga/%.ihx : amiga/%

	z88dk-appmake +hex \
		--binfile $< \
		--org 0 \
		--output $@

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

amiga/inst : $(AMIGADEPS) amiga/inst.o

	$(AMIGAVC) $^ -static -lamiga -lauto -M -v -o $@

amiga/link.o : target/amiga/link.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/long : | amiga

	# repeat HUNK_END and use this to flush serial buffer
	for i in $$(seq 0 127) ; do printf '\0\0\003\362' >> $@ ; done

amiga/orterforth : $(AMIGADEPS) amiga/link.o

	$(AMIGAVC) $^ -static -lamiga -lauto -M -v -o $@

amiga/orterforth.adf : amiga/orterforth amiga/orterforth.bin

	xdftool $@ format orterforth
	xdftool $@ write amiga/orterforth orterforth
	xdftool $@ write amiga/orterforth.bin orterforth.bin

amiga/orterforth.bin : amiga/orterforth.img

	$(ORTER) hex read < $< > $@

STOPMACHINE=$(INFO) "Stopping machine" && sh scripts/stop.sh $(@D)/machine.pid

amiga/orterforth.img : $(AMIGAINSTDEPS)

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
	@$(EMPTYDR1FILE) $@
	@$(STARTDISC) $(AMIGASERIALOPTS) model.img $@
	@$(WAITUNTILSAVED) $@
	@$(STOPDISC)
	@$(STOPMACHINE)

amiga/rf_m68k.o : amiga/rf_m68k.s

	$(AMIGAVC) -c $< -o $@

amiga/rf_m68k.s : rf_m68k.s | amiga

	cp $< $@.io
	sed -i 's/\.sect \.text/section "CODE",code/' $@.io
	sed -i 's/\.sect \.data/section "DATA",data/' $@.io
	sed -i 's/\.align 2/cnop 0,4/' $@.io
	sed -i 's/\.extern/public/' $@.io
	mv $@.io $@
