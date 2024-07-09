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
amiga-hw : amiga/hw.adf

	@$(INFO) "Starting FS-UAE"
	@$(WARN) "Open Shell and execute df1:hw"
	@fs-uae --amiga-model=A500+ --floppy-drive-1=$<

.PHONY : amiga-hw
amiga-run : amiga/inst.adf model.img

	@$(INFO) "Starting FS-UAE"
	@$(START) fsuae.pid fs-uae --amiga-model=A500+ --floppy-drive-1=$< --serial-port=tcp://127.0.0.1:5705
	@sleep 5
	@$(INFO) "Running disc"
	@$(WARN) "Open Shell and execute df1:inst"
	@$(DISC) tcp client 5705 model.img amiga/orterforth.img

amiga/amiga.o : target/amiga/amiga.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/hw : amiga/hw.o

	$(AMIGAVC) $< -lamiga -lauto -o $@

amiga/hw.adf : amiga/hw

	xdftool $@ format hw
	xdftool $@ write $< hw

amiga/hw.o : hw.c | amiga

	$(AMIGAVC) -c $< -o $@

amiga/inst : amiga/main.o amiga/amiga.o amiga/rf.o amiga/inst.o amiga/inst.o amiga/io.o

	$(AMIGAVC) $^ -static -lamiga -lauto -M -v -o $@

amiga/inst.adf : amiga/inst

	xdftool $@ format inst
	xdftool $@ write $< inst

amiga/inst.o : inst.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/io.o : io.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/main.o : main.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@

amiga/rf.o : rf.c rf.h target/amiga/amiga.inc | amiga

	$(AMIGAVC) -c $< -o $@
