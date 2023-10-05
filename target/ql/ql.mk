# === Sinclair QL ===

# xtc86 may not be on PATH
export PATH := $(HOME)/xtc68/bin:$(PATH)

QLMACHINE := sqlux
QLQCCOPTS =
QLROM := ah.rom
QLSERIALBAUD := 4800
QLSQLUXOPTS := --ramsize 128 --romdir roms/ql --sysrom $(QLROM) --device mdv1,ql --win_size 2x

# IDE may attempt to read from the symlink so delete it
SERIALPTY := $$(readlink -n pty && rm pty)
STARTDISCPTY := rm -f pty && $(STARTDISC) pty pty

# QLOPTION := assembly
QLOPTION := default
ifeq ($(TARGET),ql)
ifneq ($(OPTION),)
QLOPTION := $(OPTION)
endif
endif

ifeq ($(QLOPTION),assembly)
QLDEPS := ql/rf.o ql/rf_m68k.o ql/system.o ql/main.o
QLQCCOPTS += -D RF_ASSEMBLY
endif

ifeq ($(QLOPTION),default)
QLDEPS := ql/rf.o ql/system.o ql/main.o
endif

ql :

	mkdir $@

.PHONY : ql-build
ql-build : ql/orterforth

.PHONY : ql-hw
ql-hw : ql/hw

	@sqlux $(QLSQLUXOPTS) --speed 1.0 --boot_cmd 'EXEC_W "mdv1_hw"'

.PHONY : ql-load-serial
ql-load-serial : ql/loader.ser ql/orterforth.bin.ser ql/orterforth.ser | $(DISC) $(ORTER)

	@$(PROMPT) "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"

	@echo "* Loading loader..."
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/loader.ser
	@sleep 3

	@echo "* Loading install..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/orterforth.bin.ser
	@sleep 3

	@echo "* Loading job..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/orterforth.ser
	@sleep 3

	@echo "* Starting disc..."
	@touch data.img
	@$(DISC) serial $(SERIALPORT) $(QLSERIALBAUD) model.img data.img

.PHONY : ql-run
ql-run : ql/orterforth.bin ql/orterforth | roms/ql/$(QLROM) $(DR0) $(DR1)

	@$(STARTDISCPTY) $(DR0) $(DR1)

	@sqlux $(QLSQLUXOPTS) --speed 1.0 --ser2 $(SERIALPTY) --boot_cmd 'PRINT RESPR(RESPR(0)-196608):LBYTES "mdv1_orterforth.bin",196608:EXEC_W "mdv1_orterforth"'

	@$(STOPDISC)

ql/hw.ser : ql/hw

	$(ORTER) ql serial-xtcc $< > $@

ql/hw : ql/hw.o

	qld -ms -o $@ $^

ql/hw.o : hw.c | ql

	qcc -o $@ -c $<

ql/inst : ql/inst.o $(QLDEPS)

	qld -ms -o $@ $^

ql/inst.o : inst.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/inst.ser : ql/inst | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

ql/link.o : link.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/loader-inst.ser : target/ql/loader-inst.bas

	cp $< $@.io
	printf '\032' >> $@.io
	mv $@.io $@

ql/loader.ser : target/ql/loader.bas

	cp $< $@.io
	printf '\032' >> $@.io
	mv $@.io $@

ql/main.o : main.c rf.h $(QLINC) inst.h | ql

	qcc -o $@ -c $<

ql/orterforth : ql/link.o $(QLDEPS)

	qld -ms -o $@ $^

ql/orterforth.bin : ql/orterforth.bin.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

ql/orterforth.bin.hex : ql/inst.ser ql/loader-inst.ser model.img | roms/ql/$(QLROM) $(DISC) $(ORTER)

	@$(EMPTYDR1FILE) $@.io

ifeq ($(QLMACHINE),real)

	@$(PROMPT) "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"

	@echo "* Loading loader..."
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/loader-inst.ser

	@echo "* Loading installer..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/inst.ser

	@$(STARTDISC) serial $(SERIALPORT) $(QLSERIALBAUD) model.img $@.io

	@$(WAITUNTILSAVED) $@.io

	@$(STOPDISC)

endif
ifeq ($(QLMACHINE),sqlux)
	@$(STARTDISCPTY) model.img $@.io

	@$(START) sqlux.pid sqlux $(QLSQLUXOPTS) --speed 0.0 --ser2 $(SERIALPTY) --boot_cmd 'PRINT RESPR(RESPR(0)-196608):EXEC_W "mdv1_inst"'

	@$(WAITUNTILSAVED) $@.io

	@sh scripts/stop.sh sqlux.pid
	
	@$(STOPDISC)

endif

	@$(COMPLETEDR1FILE)

ql/orterforth.bin.ser : ql/orterforth.bin | $(ORTER)

	$(ORTER) ql serial-bytes $< > $@

ql/orterforth.ser : ql/orterforth | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

ql/rf.o : rf.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/rf_m68k.o : rf_m68k.s | ql

	qcc -o $@ -c $<

ql/system.o : target/ql/system.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<
