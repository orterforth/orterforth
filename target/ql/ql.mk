# === Sinclair QL ===

# xtc86 may not be on PATH
export PATH := $(HOME)/xtc68/bin:$(PATH)

# QLOPTION := assembly
QLOPTION := default

QLQCCOPTS =

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

QLMACHINE := sqlux
QLROM := ah.rom

.PHONY : ql-hw
ql-hw : ql/hw

	@sqlux --ramsize 128 --romdir roms/ql --sysrom $(QLROM) --device mdv1,ql --speed 1.0 --win_size 2x --boot_cmd 'EXEC_W "mdv1_hw"'

QLSERIALBAUD := 4800

# load from serial
.PHONY : ql-load-serial
#ql-load-serial :  ql/orterforth.ser ql/loader.ser | $(DISC) $(ORTER)
ql-load-serial : ql/orterforth.bin.ser ql/orterforth.ser ql/loader.ser | $(DISC) $(ORTER)

	@echo "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@read -p "Then press enter to start: " LINE

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

STARTDISCPTY := rm -f pty && $(STARTDISC) pty pty

.PHONY : ql-run
ql-run : ql/orterforth.bin ql/orterforth | roms/ql/$(QLROM) $(DR0) $(DR1)

	@$(STARTDISCPTY) $(DR0) $(DR1)

	@sqlux --ramsize 128 --romdir roms/ql --sysrom $(QLROM) --device mdv1,ql --ser2 $$(readlink -n pty && rm pty) --speed 1.0 --win_size 2x --boot_cmd 'PRINT RESPR(RESPR(0)-196608):LBYTES "mdv1_orterforth.bin",196608:EXEC_W "mdv1_orterforth"'

	@$(STOPDISC)

ql/hw.ser : ql/hw

	$(ORTER) ql serial-xtcc $< > $@

ql/hw : ql/hw.o

	qld -ms -o $@ $^

ql/hw.o : hw.c | ql

	qcc -o $@ -c $<

# inst executable
ql/inst : ql/inst.o $(QLDEPS)

	qld -ms -o $@ $^

# installer
ql/inst.o : inst.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

# inst executable with serial header
ql/inst.ser : ql/inst | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

# relinker
ql/link.o : link.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

# loader terminated with Ctrl+Z, to load via SER2Z
ql/loader-inst.ser : target/ql/loader-inst.bas

	cat $< > $@.io
	printf '\032' >> $@.io
	mv $@.io $@

# loader terminated with Ctrl+Z, to load via SER2Z
ql/loader.ser : target/ql/loader.bas

	cat $< > $@.io
	printf '\032' >> $@.io
	mv $@.io $@

# main program
ql/main.o : main.c rf.h $(QLINC) inst.h | ql

	qcc -o $@ -c $<

# final executable
ql/orterforth : ql/link.o $(QLDEPS)

	qld -ms -o $@ $^

# saved binary
ql/orterforth.bin : ql/orterforth.bin.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

# saved binary as hex
ql/orterforth.bin.hex : ql/inst.ser ql/loader-inst.ser model.img | roms/ql/$(QLROM) $(DISC) $(ORTER)

	@$(EMPTYDR1FILE) $@.io

ifeq ($(QLMACHINE),real)
	@echo "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/loader-inst.ser

	@echo "* Loading installer..."
	@sleep 1
	@$(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) < ql/inst.ser

	# TODO use disc start/stop script
	@echo "* Starting disc and waiting for completion..."
	@touch $@.io
	@$(DISC) serial $(SERIALPORT) $(QLSERIALBAUD) model.img $@.io & pid=$$! ; \
		scripts/wait-until-saved.sh $@.io ; \
		kill -9 $$pid

endif
ifeq ($(QLMACHINE),sqlux)
	@$(STARTDISCPTY) model.img $@.io

	@$(START) sqlux.pid sqlux --ramsize 128 --romdir roms/ql --sysrom $(QLROM) --device mdv1,ql --ser2 $$(readlink -n pty && rm pty) --speed 0.0 --win_size 2x --boot_cmd 'PRINT RESPR(RESPR(0)-196608):EXEC_W "mdv1_inst"'

	@$(WAITUNTILSAVED) $@.io

	@sh scripts/stop.sh sqlux.pid
	
	@$(STOPDISC)

endif

	@$(COMPLETEDR1FILE)

# saved binary with serial header
ql/orterforth.bin.ser : ql/orterforth.bin | $(ORTER)

	$(ORTER) ql serial-bytes $< > $@

# final binary with serial header
ql/orterforth.ser : ql/orterforth | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

# machine and code
ql/rf.o : rf.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/rf.s : rf.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -S -c $<

# assembly code
ql/rf_m68k.o : rf_m68k.s | ql

	qcc -o $@ -c $<

# system support
ql/system.o : target/ql/system.c rf.h $(QLINC) | ql

	qcc $(QLQCCOPTS) -o $@ -c $<
