# === Sinclair QL ===

# QLOPTION := assembly
QLOPTION := default

ifeq ($(QLOPTION),assembly)
QLDEPS := ql/rf.o ql/rf_m68k.o ql/system.o ql/main.o
QLINC := target/ql/assembly.inc
endif

ifeq ($(QLOPTION),default)
QLDEPS := ql/rf.o ql/system.o ql/main.o
QLINC := target/ql/default.inc
endif

ql :

	mkdir $@

.PHONY : ql-build
ql-build : ql/orterforth

.PHONY : ql-clean
ql-clean :

	rm -rf ql/*

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

# inst executable
ql/inst : ql/inst.o $(QLDEPS)

	qld -ms -o $@ $^

# installer
ql/inst.o : inst.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<

# inst executable with serial header
ql/inst.ser : ql/inst | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

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

QLMACHINE := sqlux

# saved binary as hex
ql/orterforth.bin.hex : ql/inst.ser ql/loader-inst.ser | $(DISC) $(ORTER)

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

	@mv $@.io $@
	@echo "* Done"
	@sleep 1
endif
ifeq ($(QLMACHINE),sqlux)
# pty test for QL emulator
# socat -d -d -v pty,rawer,link=pty EXEC:cat,pty,rawer &
# socat -d -d -v - pty,rawer,link=pty
# sleep 1
	socat -d -d -v - pty,rawer,link=pty,wait-slave < rx > tx
	sleep 1
	ls -l /dev/pts
	sleep 5
	sqlux --ser2 pty --ramsize 128 --romdir ../sQLux/roms --win_size 2x &

	@echo "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	cat ql/loader-inst.ser > rx

	@echo "* Loading installer..."
	sleep 10
	cat ql/inst.ser > rx

	# TODO use disc start/stop script
	@echo "* Starting disc and waiting for completion..."
	@touch $@.io
	sh scripts/start.sh tx rx disc.pid $(DISC)

	$(WAITUNTILSAVED)

	$(STOPDISC)

	@mv $@.io $@
	@echo "* Done"
	@sleep 1
endif

# saved binary with serial header
ql/orterforth.bin.ser : ql/orterforth.bin | $(ORTER)

	$(ORTER) ql serial-bytes $< > $@

# final binary with serial header
ql/orterforth.ser : ql/orterforth | $(ORTER)

	$(ORTER) ql serial-xtcc $< > $@

# relinker
ql/link.o : link.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<

# machine and code
ql/rf.o : rf.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<

ql/rf.s : rf.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -S -c $<

# assembly code
ql/rf_m68k.o : rf_m68k.s | ql

	qcc -o $@ -c $<

# system support
ql/system.o : target/ql/system.c rf.h $(QLINC) | ql

	qcc -D RF_TARGET_INC='"$(QLINC)"' -o $@ -c $<
