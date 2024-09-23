AMIGALOADINGMETHOD=disk
# AMIGALOADINGMETHOD=serial
AMIGAMACHINE=fsuae
# AMIGAMACHINE=real
# AMIGAMODEL=A500
AMIGAMODEL=A500+

AMIGALOADSERIAL=$(WARN) "NB set serial handshaking to RTS/CTS" && \
	$(PROMPT) "Open Shell and type: TYPE SER: > RAM:receive.rexx" && \
	$(INFO) "Sending receive.rexx" && \
	(cat target/amiga/receive.rexxlong && sleep 10) | $(ORTER) serial $(SERIALPORT) $(SERIALBAUD) && \
	$(PROMPT) "Type Ctrl+C" && \
	$(INFO) "Breaking serial send" && \
	cat target/amiga/receive.rexxlong | $(ORTER) serial $(SERIALPORT) $(SERIALBAUD) && \
	$(PROMPT) "Type: rx RAM:receive - Filename? ram:$(<F) - Bytes? $$($(STAT) $<)" && \
	$(INFO) "Sending $<" && \
	(cat $< amiga/long && sleep 10) | $(ORTER) serial $(SERIALPORT) $(SERIALBAUD)

AMIGASTARTFSUAE=$(INFO) "Starting FS-UAE" && \
	$(START) fsuae.pid fs-uae --amiga-model=$(AMIGAMODEL) --floppy-drive-1=$<.adf --serial-port=tcp://127.0.0.1:5705

AMIGAVBCCHOME=/opt/vbcc/sdk
AMIGAVBCCOPTS=-L$(AMIGAVBCCHOME)/NDK_3.9/Include/linker_libs \
	-I$(AMIGAVBCCHOME)/NDK_3.9/Include/include_h \
	+kick13
AMIGAVC=PATH=$(AMIGAVBCCHOME)/vbcc/bin:$$PATH \
	VBCC=$(AMIGAVBCCHOME)/vbcc \
	vc $(AMIGAVBCCOPTS)

amiga :

	mkdir $@

.PHONY : amiga-build
amiga-build : amiga/inst.adf

.PHONY : amiga-hw
amiga-hw : amiga/hw amiga/hw.adf | amiga/long $(ORTER)

ifeq ($(AMIGALOADINGMETHOD),disk)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(AMIGASTARTFSUAE)
	@$(WARN) "Open Shell and execute df1:hw"
endif
ifeq ($(AMIGAMACHINE),real)
	@$(WARN) "Physical disk load not supported"
	@exit 1
endif
endif
ifeq ($(AMIGALOADINGMETHOD),serial)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(WARN) "FS-UAE serial load not supported"
	@exit 1
endif
ifeq ($(AMIGAMACHINE),real)
	@$(AMIGALOADSERIAL)
	@$(WARN) "To run type: ram:hw"
endif
endif

.PHONY : amiga-run
amiga-run : amiga/inst amiga/inst.adf model.img | amiga/long $(DISC) $(DR0) $(DR1) $(ORTER)

ifeq ($(AMIGALOADINGMETHOD),disk)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(AMIGASTARTFSUAE)
	@sleep 3
	@$(STARTDISC) tcp client 5705 model.img
	@$(WARN) "NB set serial handshaking to None"
	@$(WARN) "Open Shell and execute df1:inst"
	@$(PROMPT) "To load discs $(DR0) $(DR1), wait for inst to complete"
	@$(STOPDISC)
	@$(INFO) "Starting disc $(DR0) $(DR1)"
	@$(DISC) tcp client 5705 $(DR0) $(DR1)
endif
ifeq ($(AMIGAMACHINE),real)
	@$(WARN) "Physical disk load not supported"
	@exit 1
endif
endif
ifeq ($(AMIGALOADINGMETHOD),serial)
ifeq ($(AMIGAMACHINE),fsuae)
	@$(WARN) "FS-UAE serial load not supported"
	@exit 1
endif
ifeq ($(AMIGAMACHINE),real)
	@$(AMIGALOADSERIAL)
	@$(EMPTYDR1FILE) amiga/orterforth.img
	@$(STARTDISC) serial $(SERIALPORT) $(SERIALBAUD) model.img amiga/orterforth.img
	@$(WARN) "Type: ram:inst"
	@$(PROMPT) "Wait for inst to complete"
	@$(STOPDISC)
	@$(INFO) "Starting disc $(DR0) $(DR1)"
	@$(DISC) serial $(SERIALPORT) $(SERIALBAUD) $(DR0) $(DR1)
endif
endif

amiga/amiga.o : target/amiga/amiga.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/hw : amiga/hw.o

	$(AMIGAVC) $< -lamiga -lauto -o $@

amiga/hw.adf : amiga/hw

	xdftool $@ format hw
	xdftool $@ write $< hw

amiga/hw.o : hw.c | amiga

	$(AMIGAVC) -c $< -o $@

amiga/inst : amiga/amiga.o amiga/inst.o amiga/io.o amiga/main.o amiga/rf.o

	$(AMIGAVC) $^ -static -lamiga -lauto -M -v -o $@

amiga/inst.adf : amiga/inst

	xdftool $@ format inst
	xdftool $@ write $< inst

amiga/inst.o : inst.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/io.o : io.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/long :

	for run in {1..50}; do printf '\0\0\x03\xF2' >> $@ ; done

amiga/main.o : main.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/rf.o : rf.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@
