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
amiga-build : amiga/hw

.PHONY : amiga-run
amiga-run : amiga/hw

	fs-uae --amiga-model=A500+

amiga/hw : amiga/hw.o

	$(AMIGAVC) $< -lamiga -lauto -o $@

amiga/hw.o : hw.c | amiga

	$(AMIGAVC) -c $< -o $@

amiga/inst.o : inst.c rf.h | amiga

	$(AMIGAVC) -c $< -o $@

amiga/io.o : io.c rf.h | amiga

	$(AMIGAVC) -c $< -o $@

amiga/main.o : main.c rf.h | amiga

	$(AMIGAVC) -c $< -o $@

amiga/orterforth : amiga/rf.o amiga/inst.o amiga/io.o amiga/main.o

	$(AMIGAVC) $< -lamiga -lauto -o $@

amiga/rf.o : rf.c rf.h | amiga

	$(AMIGAVC) -c $< -o $@
