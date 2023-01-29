# https://github.com/mcleod-ideafix/zx81putil
$(SYSTEM)/zx81putil : tools/zx81putil/zx81putil.c | $(SYSTEM)

	$(CC) -g -Wall -Wextra -O2 -std=c99 -pedantic -o $@ $<

tools/zx81putil/zx81putil.c : | tools

	cd tools && git clone https://github.com/mcleod-ideafix/zx81putil.git

zx81 :

	mkdir $@

.PHONY : zx81-run
zx81-run : zx81/inst.tzx | zx81/jtyone.jar

	java -jar zx81/jtyone.jar zx81/inst.tzx@0 -scale 3 -machine ZX81

zx81/%.tzx : zx81/%.P $(SYSTEM)/zx81putil

	$(SYSTEM)/zx81putil -tzx $<

zx81/inst.bin zx81/inst.P : zx81/rf.lib zx81/system.lib zx81/inst.lib main.c

	zcc +zx81 -lm -lzx81/rf -lzx81/system -lzx81/inst -create-app -m -o zx81/inst.bin main.c

zx81/inst.lib : inst.c rf.h | zx81

	zcc +zx81 -x -o $@ $<

zx81/jtyone.jar : | zx81

	curl --output $@ http://www.zx81stuff.org.uk/zx81/jtyone.jar

zx81/rf.lib : rf.c rf.h target/zx81/system.inc | zx81

	zcc +zx81 -x -o $@ $<

zx81/system.lib : target/zx81/system.c rf.h | zx81

	zcc +zx81 -x -o $@ $<
