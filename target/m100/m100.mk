# === TRS-80 Model 100 ===

M100ZCCOPTS := +m100 -subtype=default

m100 :

	mkdir $@

.PHONY : m100-clean
m100-clean :

	rm -f m100/*

.PHONY : m100-hw
m100-hw : m100/hw.ba | $(ORTER)

	@printf '  \033[1;35mOn the target type RUN "COM:38N1D" <enter>\033[0;0m\n'
	@printf '  \033[1;35mThen on here press <enter>\033[0;0m\n'
	@read LINE
	@$(ORTER) serial -e 5 $(SERIALPORT) 300 < $<

m100/hw.ba : | m100

	printf '10 PRINT "Hello World ";\r\n' > $@.io
	printf '20 GOTO 10\r\n\032' >> $@.io
	mv $@.io $@

m100/hw.co : hw.c | m100

	zcc $(M100ZCCOPTS) \
		-create-app -m -o $@ $<

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
