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
AMIGALOADSERIAL=$(WARN) "NB set serial handshaking to RTS/CTS" && \
	$(PROMPT) "Open Shell and type: type ser: to ram:$(<F)" && \
	$(INFO) "Sending $<" && \
	(cat $< amiga/long amiga/long amiga/long amiga/long $< && sleep 20) | $(AMIGASERIAL) && \
	$(AMIGASERIALBREAK)
AMIGAKICKSTART='roms/amiga/Kickstart - 315093-01 (USA, Europe) (v1.2 Rev 33.180) (A500, A2000).rom'
AMIGAWORKBENCH='roms/amiga/Workbench v1.3 rev 34.20 (1988)(Commodore)(A500-A2000)(GB)(Disk 1 of 2)(Workbench).adf'
endif
ifeq ($(AMIGAMODEL),A500+)
AMIGALOADSERIAL=$(WARN) "NB set serial handshaking to RTS/CTS" && \
	$(PROMPT) "Open Shell and type: type ser: > ram:$(<F).rexx" && \
	$(INFO) "Sending $<.rexx" && \
	(cat $<.rexx amiga/long && sleep 15) | $(AMIGASERIAL) && \
	$(AMIGASERIALBREAK) && \
	$(PROMPT) "Type: rx ram:$(<F)" && \
	$(INFO) "Sending $<" && \
	(cat $< amiga/long amiga/long amiga/long amiga/long && sleep 10) | $(AMIGASERIAL)
AMIGAKICKSTART='roms/amiga/Kickstart - 390979-01 (USA, Europe) (v2.04 Rev 37.175) (A500 Plus, A2000).rom'
AMIGAWORKBENCH='roms/amiga/Workbench v2.04 rev 37.67 (1991)(Commodore)(Disk 1 of 4)(Workbench).adf'
endif

AMIGASTARTFSUAE=$(INFO) "Starting FS-UAE" && \
	$(START) amiga/machine.pid fs-uae --amiga-model=$(AMIGAMODEL) --kickstart-file=$(AMIGAKICKSTART) --floppy-drive-0=$(AMIGAWORKBENCH) --serial-port=tcp://127.0.0.1:5705

AMIGAVBCCHOME=/opt/amiga/vbcc
AMIGAVBCCOPTS=+kick13
ifeq ($(AMIGAOPTION),assembly)
AMIGAVBCCOPTS += -DRF_ASSEMBLY
endif
AMIGAVC=PATH=/opt/amiga/bin:$$PATH \
	VBCC=$(AMIGAVBCCHOME) \
	vc $(AMIGAVBCCOPTS)

ifeq ($(AMIGALOADINGMETHOD),disk)
AMIGAINSTDEPS := amiga/inst amiga/inst.adf model.img | amiga/long $(DISC) $(ORTER)
ifeq ($(AMIGAMACHINE),real)
AMIGALOAD += $(WARN) "Write amiga/$(<F).adf to disk" &&
endif
AMIGALOAD += $(WARN) "Open Shell and execute df1:$(<F)"
AMIGARUNDEPS := amiga/orterforth amiga/orterforth.adf | $(DISC) $(DR0) $(DR1)
AMIGASTARTFSUAE += --floppy-drive-1=$<.adf
endif

ifeq ($(AMIGALOADINGMETHOD),serial)
AMIGAINSTDEPS := amiga/inst amiga/inst.bas amiga/inst.rexx model.img | amiga/long $(DISC) $(ORTER)
ifeq ($(AMIGAMACHINE),fsuae)
AMIGALOAD += $(WARN) "NB FS-UAE serial load fails due to a leading 0xF2 in the received file" &&
endif
AMIGALOAD += $(AMIGALOADSERIAL) && $(WARN) "Type: ram:$(<F)"
AMIGARUNDEPS := amiga/orterforth amiga/orterforth.bin amiga/orterforth.bin.bas amiga/orterforth.bin.rexx amiga/orterforth.bas amiga/orterforth.rexx | amiga/long $(DISC) $(DR0) $(DR1)
endif

ifeq ($(AMIGAMACHINE),fsuae)
AMIGASTARTMACHINE=$(AMIGASTARTFSUAE) && sleep 3 && $(WARN) "NB set serial handshaking to None"
endif

ifeq ($(AMIGAMACHINE),real)
AMIGASTARTMACHINE=:
endif

amiga :

	mkdir $@

.PHONY : amiga-build
amiga-build : $(AMIGARUNDEPS)

.PHONY : amiga-hw
amiga-hw : amiga/hw amiga/hw.adf amiga/hw.rexx | amiga/long $(ORTER)

	@$(AMIGASTARTMACHINE)
	@$(AMIGALOAD)

.PHONY : amiga-run
amiga-run : $(AMIGARUNDEPS)

	@$(AMIGASTARTMACHINE)
ifeq ($(AMIGALOADINGMETHOD),disk)
	@$(AMIGALOAD)
endif
ifeq ($(AMIGALOADINGMETHOD),serial)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(WARN) "NB FS-UAE serial load fails due to a leading 0xF2 in the received file"
endif
	@$(AMIGALOADSERIAL)
ifeq ($(AMIGAMODEL),A500)
	@$(PROMPT) "Type: type ser: to ram:bin.bas"
	@$(INFO) "Sending amiga/orterforth.bin.bas"
	@(cat amiga/orterforth.bin.bas amiga/long && sleep 15) | $(AMIGASERIAL)
	@$(AMIGASERIALBREAK)
	@$(PROMPT) "Type: amigabasic ram:bin.bas"
endif
ifeq ($(AMIGAMODEL),A500+)
	@$(PROMPT) "Type: type ser: > ram:bin.rexx"
	@$(INFO) "Sending amiga/orterforth.bin.rexx"
	@(cat amiga/orterforth.bin.rexx amiga/long && sleep 15) | $(AMIGASERIAL)
	@$(AMIGASERIALBREAK)
	@$(PROMPT) "Type: rx ram:bin"
endif
	@$(INFO) "Sending amiga/orterforth.bin"
	@(cat amiga/orterforth.bin amiga/long amiga/long amiga/long amiga/long && sleep 10) | $(AMIGASERIAL)
	@$(WARN) "Now type: ram:orterforth <enter>"
endif
	@$(INFO) "Starting disc $(DR0) $(DR1)"
	@$(DISC) $(AMIGASERIALOPTS) $(DR0) $(DR1)

amiga/%.adf : amiga/% | xdftool

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

amiga/%.o : %.c rf.h target/amiga/amiga.inc | amiga vc

	$(AMIGAVC) -c $< -o $@

amiga/%.rexx : amiga/% target/amiga/receive.rexx

	printf "/* $(@F) modified with pre-set values */\n" > $@
	printf "file = 'ram:$(<F)'\n" >> $@
	printf "size = $$($(STAT) $<)\n" >> $@
	cat target/amiga/receive.rexx >> $@

amiga/amiga.o : target/amiga/amiga.c rf.h target/amiga/amiga.inc | amiga vc

	$(AMIGAVC) -c $< -o $@

amiga/hw : amiga/hw.o | vc

	$(AMIGAVC) $< -lamiga -lauto -o $@

amiga/inst : $(AMIGADEPS) amiga/inst.o | vc

	$(AMIGAVC) $^ -static -lamiga -lauto -M -v -o $@

amiga/long : | amiga

	# repeat HUNK_END and use this to flush serial buffer
	for i in $$(seq 0 127) ; do printf '\0\0\003\362' >> $@ ; done

amiga/orterforth : $(AMIGADEPS) amiga/link.o | vc

	$(AMIGAVC) $^ -static -lamiga -lauto -M -v -o $@

amiga/orterforth.adf : amiga/orterforth amiga/orterforth.bin | xdftool

	xdftool $@ format orterforth
	xdftool $@ write amiga/orterforth orterforth
	xdftool $@ write amiga/orterforth.bin orterforth.bin

amiga/orterforth.bin : amiga/orterforth.img

	$(ORTER) hex read < $< > $@

amiga/orterforth.img : $(AMIGAINSTDEPS)

	@$(AMIGASTARTMACHINE)
	@$(AMIGALOAD)
	@$(EMPTYDR1FILE) $@
	@$(STARTDISC) $(AMIGASERIALOPTS) model.img $@
	@$(WAITUNTILSAVED) $@
	@$(STOPDISC)
	@$(STOPMACHINE)

amiga/rf_m68k.o : amiga/rf_m68k.s | vc

	$(AMIGAVC) -c $< -o $@

amiga/rf_m68k.s : rf_m68k.s | amiga

	cp $< $@.io
	sed -i 's/\.sect \.text/section "CODE",code/' $@.io
	sed -i 's/\.sect \.data/section "DATA",data/' $@.io
	sed -i 's/\.align 2/cnop 0,4/' $@.io
	sed -i 's/\.extern/public/' $@.io
	mv $@.io $@

tools/github.com/bebbo/amiga-gcc :

	git submodule update --init $@

tools/phoenix.owl.de/vbcc/2022-02-28/vbcc_target_m68k-kick13.lha :

	mkdir -p $(@D)
	curl -o $@ http://phoenix.owl.de/vbcc/2022-02-28/vbcc_target_m68k-kick13.lha

/opt/amiga/bin/vc /opt/amiga/bin/vlink : | tools/github.com/bebbo/amiga-gcc

	cd $< && make update vbcc vlink

/opt/amiga/vbcc/include/NDK_1.3 : tools/ndk13.lha

	lha xw=/opt/amiga/vbcc/include/ $<

/opt/amiga/vbcc/targets/m68k-kick13/include/stdint.h : tools/phoenix.owl.de/vbcc/2022-02-28/vbcc_target_m68k-kick13.lha

	lha xw=amiga/ $<
	mv amiga/vbcc_target_m68k-kick13/targets /opt/amiga/vbcc/targets

/opt/amiga/vbcc/config :

	mkdir -p $@

/opt/amiga/vbcc/config/kick13 : target/amiga/kick13 | /opt/amiga/vbcc/config

	cp $< $@

/opt/amiga/vbcc/include :

	mkdir -p $@

.PHONY : /opt/amiga/bin/vc
vc :

	@PATH=/opt/amiga/bin:$$PATH $(REQUIRETOOL)

.PHONY : xdftool
xdftool :

	@$(REQUIRETOOL)
