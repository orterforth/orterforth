Z88ORG := 0x0000
Z88ORIGIN := 0x0000

Z88ZCCOPTS := +z88 \
	-DRF_ORG=$(Z88ORG) \
	-DRF_ORIGIN=$(Z88ORIGIN) \
	-DRF_TARGET_INC='\"target/z88/system.inc\"'

z88 :

	mkdir $@

z88/hw.bin z88/hw.map : hw.c

	zcc $(Z88ZCCOPTS) -m -o z88/hw.bin hw.c

z88/inst.bin z88/inst.map z88/INST.BAS : z88/rf.lib z88/system.lib z88/inst.lib main.c

	zcc $(Z88ZCCOPTS) -lm -lz88/rf -lz88/system -lz88/inst \
		-create-app -m -o z88/inst.bin main.c

z88/inst.lib : inst.c rf.h | z88

	zcc $(ZX81ZCCOPTS) -x -o $@ $<

z88/rf.lib : rf.c rf.h target/z88/system.inc | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<

z88/system.lib : target/z88/system.c rf.h | z88

	zcc $(Z88ZCCOPTS) -x -o $@ $<
