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

.PHONY : zx81-build
zx81-build : zx81/inst.tzx

ZX81ORG := 0x4082
ZX81ORIGIN := 0x5500

ZX81ZCCOPTS := +zx81 \
	-lm81_tiny \
	-Ca-DRF_ORG=$(ZX81ORG) \
	-Ca-DRF_ORIGIN=$(ZX81ORIGIN) \
	-DRF_ORG=$(ZX81ORG) \
	-DRF_ORIGIN=$(ZX81ORIGIN) \
	-pragma-define:CRT_ENABLE_STDIO=0 \
	-pragma-define:CRT_INITIALIZE_BSS=0

.PHONY : zx81-hw
zx81-hw : zx81/hw.tzx zx81/hw.wav | tools/jtyone.jar

#	java -jar tools/jtyone.jar zx81/hw.tzx@0 -scale 3 -machine ZX81
	@$(PROMPT) 'Type LOAD ""'
	@$(PLAY) zx81/hw.wav

ZX81SERIALOPTS=serial /home/david/Desktop/pty 300

.PHONY : zx81-run
zx81-run : zx81/inst.bin zx81/inst.tzx zx81/inst.wav | tools/jtyone.jar $(DISC) $(DR0) $(DR1)

	@$(CHECKMEMORY) $(ZX81ORG) $(ZX81ORIGIN) $$($(STAT) zx81/inst.bin)
#	java -jar tools/jtyone.jar zx81/inst.tzx@0 -scale 3 -machine ZX81
	@$(PROMPT) 'Type LOAD ""'
#	@$(PLAY) zx81/inst.wav
	@$(STARTDISC) $(ZX81SERIALOPTS) model.img
	@$(PROMPT) "Wait for inst to complete"
	@$(STOPDISC)
	@$(INFO) "Starting disc $(DR0) $(DR1)"
	@$(DISC) $(ZX81SERIALOPTS) $(DR0) $(DR1)

zx81/%.lib : %.c rf.h target/zx81/zx81.inc | zx81

	zcc $(ZX81ZCCOPTS) -x -o $@ $<

zx81/%.tzx : zx81/%.P | $(SYSTEM)/zx81putil

	$(SYSTEM)/zx81putil -tzx $<

zx81/%.wav : zx81/%.P | $(SYSTEM)/zx81putil

	$(SYSTEM)/zx81putil -p2w $<

zx81/hw.bin zx81/hw.P : hw.c

	zcc $(ZX81ZCCOPTS) -lm -create-app -o zx81/hw.bin $<

zx81/inst.bin zx81/inst.P : zx81/inst.lib zx81/io.lib zx81/rf_z80.lib zx81/system.lib main.c

	zcc $(ZX81ZCCOPTS) -lm -lzx81/inst -lzx81/io -lzx81/rf_z80 -lzx81/system -create-app -m -o zx81/inst.bin main.c

zx81/rf_z80.lib : rf_z80.asm | zx81

	zcc $(ZX81ZCCOPTS) -x -o $@ $<

zx81/system.lib : target/zx81/system.c rf.h target/zx81/zx81.inc | zx81

	zcc $(ZX81ZCCOPTS) -x -o $@ $<
