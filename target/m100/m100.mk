# === TRS-80 Model 100 ===

M100ORG := 45000
M100PROMPT := $(PROMPT) 'On the target type RUN "COM:78N1E" <enter>'
M100SERIAL := $(ORTER) serial -o ixon -o ixoff -o onlcrx -e 2 $(SERIALPORT) 4800
M100SLOWSEND := (while read -r l; do echo "$$l"; sleep 1; done && printf '\032' && sleep 1)
M100LOADLOADER := printf '* \033[1;33mLoading loader\033[0;0m\n' ; $(M100SLOWSEND) < target/m100/hexloa.ba | $(M100SERIAL)
M100ZCCOPTS := \
	+m100 -subtype=default -m \
	-pragma-define:CLIB_EXIT_STACK_SIZE=0 \
	-pragma-define:CRT_ORG_CODE=$(M100ORG) \
	-DRF_ORG=$(M100ORG)

m100 :

	mkdir $@

.PHONY : m100-hw
m100-hw : target/m100/hexloa.ba m100/hw.ihx | $(ORTER)

	@$(M100PROMPT)
	@$(M100LOADLOADER)
	@printf '* \033[1;33mLoading hex\033[0;0m\n'
	@$(M100SLOWSEND) < m100/hw.ihx | $(M100SERIAL)

.PHONY : m100-run
m100-run : target/m100/hexloa.ba m100/inst.ihx | $(ORTER)

	@$(M100PROMPT)
	@$(M100LOADLOADER)
	@printf '* \033[1;33mLoading hex\033[0;0m\n'
	@$(M100SLOWSEND) < m100/inst.ihx | $(M100SERIAL)

m100/%.ihx : m100/%.co

	z88dk-appmake +hex --binfile $< --org $$(( $(M100ORG) - 6 )) --output $@

m100/hw.co : hw.c | m100

	zcc $(M100ZCCOPTS) -create-app -m -o $@ $<

m100/inst.co : main.c m100/rf.lib m100/system.lib m100/inst.lib

	zcc $(M100ZCCOPTS) \
		-lm100/rf -lm100/system -lm100/inst \
		-create-app -m -o $@ $<

m100/inst.lib : inst.c inst.h rf.h target/m100/m100.inc | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<

m100/rf.lib : rf.c rf.h target/m100/m100.inc | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<

m100/system.lib : target/m100/system.c rf.h target/m100/m100.inc | m100

	zcc $(M100ZCCOPTS) -x -o $@ $<
