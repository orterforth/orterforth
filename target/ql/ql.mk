# === Sinclair QL ===

# xtc86 may not be on PATH
export PATH := $(HOME)/xtc68/bin:$(PATH)

QLMACHINE := sqlux
QLQCCOPTS =
QLROM := ah.rom
QLSERIALBAUD := 4800
QLSERIALLOAD := $(ORTER) serial -a $(SERIALPORT) $(QLSERIALBAUD) <
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
QLORIGIN := 184320 # 0x2D000
QLQCCOPTS += -D RF_ASSEMBLY
endif

ifeq ($(QLOPTION),default)
QLDEPS := ql/rf.o ql/system.o ql/main.o
QLORIGIN := 188416 # 0x2E000
endif

QLQCCOPTS += -D RF_ORIGIN=$(QLORIGIN)

ifeq ($(QLMACHINE),real)
QLRUNDEPS := ql/loader.bas.ser ql/orterforth.bin.ser ql/orterforth.ser
QLSTARTDISC := $(STARTDISC) serial $(SERIALPORT) $(QLSERIALBAUD)
endif
ifeq ($(QLMACHINE),sqlux)
QLRUNDEPS := ql/orterforth.bin ql/orterforth
QLSTARTDISC := $(STARTDISCPTY)
endif

ql :

	mkdir $@

.PHONY : ql-build
ql-build : ql/orterforth

.PHONY : ql-hw
ql-hw : ql/hw

	@sqlux $(QLSQLUXOPTS) --speed 1.0 --boot_cmd 'EXEC_W "mdv1_hw"'

.PHONY : ql-run
ql-run : $(QLRUNDEPS) | $(DISC) roms/ql/$(QLROM) $(DR0) $(DR1)

ifeq ($(QLMACHINE),real)
	@$(PROMPT) "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@$(INFO) "Loading loader..."
	@$(QLSERIALLOAD) ql/loader.bas.ser
	@sleep 3
	@$(INFO) "Loading install..."
	@$(QLSERIALLOAD) ql/orterforth.bin.ser
	@sleep 3
	@$(INFO) "Loading job..."
	@$(QLSERIALLOAD) ql/orterforth.ser
	@sleep 3
	@$(INFO) "Starting disc..."
	@$(DISC) serial $(SERIALPORT) $(QLSERIALBAUD) $(DR0) $(DR1)
endif
ifeq ($(QLMACHINE),sqlux)
	@$(STARTDISCPTY) $(DR0) $(DR1)
	@sqlux $(QLSQLUXOPTS) --speed 1.0 --ser2 $(SERIALPTY) --boot_cmd 'PRINT RESPR(RESPR(0)-$(QLORIGIN)):LBYTES "mdv1_orterforth.bin",$(QLORIGIN):EXEC_W "mdv1_orterforth"'
	@$(STOPDISC)
endif

ql/%.bas.ser : target/ql/%.bas

	cp $< $@.io
	printf '\032' >> $@.io
	mv $@.io $@

ql/hw.ser : ql/hw

	$(ORTER) ql serial-xtcc $< > $@

ql/hw : ql/hw.o

	qld -ms -o $@ $^

ql/hw.o : hw.c | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/inst : ql/inst.o $(QLDEPS)

	qld -ms -o $@ $^

ql/inst.o : inst.c rf.h target/ql/ql.inc | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/inst.ser : ql/inst | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

ql/link.o : link.c rf.h target/ql/ql.inc | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/main.o : main.c rf.h target/ql/ql.inc inst.h | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/orterforth : ql/link.o $(QLDEPS)

	qld -ms -o $@ $^

ql/orterforth.bin : ql/orterforth.bin.hex | $(ORTER)

	$(ORTER) hex read < $< > $@

ql/orterforth.bin.hex : ql/inst.ser ql/loader-inst.bas.ser model.img | roms/ql/$(QLROM) $(DISC) $(ORTER)

	@$(EMPTYDR1FILE) $@.io
ifeq ($(QLMACHINE),real)
	@$(PROMPT) "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@$(INFO) "Loading loader..."
	@$(QLSERIALLOAD) ql/loader-inst.bas.ser
	@$(INFO) "Loading installer..."
	@sleep 1
	@$(QLSERIALLOAD) ql/inst.ser
endif
	@$(QLSTARTDISC) model.img $@.io
ifeq ($(QLMACHINE),sqlux)
	@$(START) sqlux.pid sqlux $(QLSQLUXOPTS) --speed 0.0 --ser2 $(SERIALPTY) --boot_cmd 'PRINT RESPR(RESPR(0)-$(QLORIGIN)):EXEC_W "mdv1_inst"'
endif
	@$(WAITUNTILSAVED) $@.io
ifeq ($(QLMACHINE),sqlux)
	@sh scripts/stop.sh sqlux.pid
endif
	@$(STOPDISC)
	@$(COMPLETEDR1FILE)

ql/orterforth.bin.ser : ql/orterforth.bin | $(ORTER)

	$(ORTER) ql serial-bytes $< > $@

ql/orterforth.ser : ql/orterforth | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

ql/rf.o : rf.c rf.h target/ql/ql.inc | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/rf_m68k.o : rf_m68k.s | ql

	qcc $(QLQCCOPTS) -o $@ -c $<

ql/system.o : target/ql/system.c rf.h target/ql/ql.inc | ql

	qcc $(QLQCCOPTS) -o $@ -c $<
