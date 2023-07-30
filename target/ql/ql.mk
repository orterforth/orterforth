# === Sinclair QL ===

# xtc86 may not be on PATH
export PATH := $(HOME)/xtc68/bin:$(PATH)

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

QLMACHINE := sqlux

.PHONY : ql-hw
ql-hw : ql/hw.ser

	(sleep 10 && cat ql/hw.ser && sleep 50) | $(ORTER) pty ql/pty &
#	(sleep 5 && cat ql/hw.ser && sleep 50) | socat - pty,rawer,link=ql/pty &

ifeq ($(QLMACHINE),sqlux)
#	sqlux --ramsize 128 --romdir ../sQLux/roms --win_size 2x --ser2 ql/pty --boot_cmd 'LRUN SER2Z'
	sqlux --ramsize 128 --romdir ../sQLux/roms --win_size 2x --ser2 ql/pty # --boot_cmd 'EXEC_W SER2Z'
endif

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

#ql/hw.ser : target/ql/hw.bas

#	cat $< > $@.io
#	printf '\032' >> $@.io
#	mv $@.io $@

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

	@$(COMPLETEDR1FILE)
	@sleep 1
endif
ifeq ($(QLMACHINE),sqlux)
# pty test for QL emulator
# socat -d -d -v pty,rawer,link=pty EXEC:cat,pty,rawer &
# socat -d -d -v - pty,rawer,link=pty
# sleep 1
	# sleep 1
	# ls -l /dev/pts
	# sleep 5
	# TODO link will be read by IDE file watching
	socat - pty,rawer,link=ql/pty < rx &
	(sleep 15 && cat ql/hw.ser && sleep 1000) > rx &
	sleep 1
	ps
	sqlux --ser2 ql/pty --ramsize 128 --romdir ../sQLux/roms --win_size 2x &
	sleep 60
	exit 1

	@echo "On the QL type: baud $(QLSERIALBAUD):lrun ser2z"
	@read -p "Then press enter to start: " LINE

	@echo "* Loading loader..."
	(cat ql/loader-inst.ser && sleep 1000) > rx

	@echo "* Loading installer..."
	sleep 10
	cat ql/inst.ser > rx

	# TODO use disc start/stop script
	@echo "* Starting disc and waiting for completion..."
	@touch $@.io
	sh scripts/start.sh tx rx disc.pid $(DISC)

	$(WAITUNTILSAVED)

	$(STOPDISC)

	@$(COMPLETEDR1FILE)
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
