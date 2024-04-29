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

amiga/hw : amiga/hw.o

	$(AMIGAVC) $< -lamiga -lauto -o $@

amiga/hw.o : hw.c | amiga

	$(AMIGAVC) -c $< -o $@
