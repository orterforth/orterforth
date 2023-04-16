# https://github.com/mcleod-ideafix/zx81putil
$(SYSTEM)/zx81putil : tools/github.com/mcleod-ideafix/zx81putil/zx81putil.c | $(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -o $@ $<
	
# https://github.com/mcleod-ideafix/zx81putil
tools/github.com/mcleod-ideafix/zx81putil/zx81putil.c :

	git submodule update --init tools/github.com/mcleod-ideafix/zx81putil

tools/jtyone.jar :

	curl --output $@ http://www.zx81stuff.org.uk/zx81/jtyone.jar

zx81 :

	mkdir $@

.PHONY : zx81-clean
zx81-clean :

	rm -f zx81/*

ZX81ORG := 0x4082
ZX81ORIGIN := 0x6000

ZX81ZCCOPTS := +zx81 \
	-DRF_ORG=$(ZX81ORG) \
	-DRF_ORIGIN=$(ZX81ORIGIN)
	# -pragma-define:CRT_ENABLE_STDIO=0 \
	# -pragma-define:CRT_INITIALIZE_BSS=0

.PHONY : zx81-run
zx81-run : zx81/inst.bin zx81/inst.tzx | tools/jtyone.jar

	@$(CHECKMEMORY) $(ZX81ORG) $(ZX81ORIGIN) $(shell $(STAT) zx81/inst.bin)

	java -jar tools/jtyone.jar zx81/inst.tzx@0 -scale 3 -machine ZX81

zx81/inst.tzx : zx81/inst.P | $(SYSTEM)/zx81putil

	$(SYSTEM)/zx81putil -tzx $<

zx81/inst.bin zx81/inst.P : zx81/rf.lib zx81/system.lib zx81/inst.lib main.c

	zcc $(ZX81ZCCOPTS) -lm -lzx81/rf -lzx81/system -lzx81/inst \
		-create-app -m -o zx81/inst.bin main.c

zx81/inst.lib : inst.c rf.h | zx81

	zcc $(ZX81ZCCOPTS) -x -o $@ $<

zx81/rf.lib : rf.c rf.h target/zx81/system.inc | zx81

	zcc $(ZX81ZCCOPTS) -x -o $@ $<

zx81/system.lib : target/zx81/system.c rf.h | zx81

	zcc $(ZX81ZCCOPTS) -x -o $@ $<
