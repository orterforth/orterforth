# === Commodore 64 ===

c64 :

	mkdir $@

.PHONY : c64-build
c64-build : c64/inst

.PHONY : c64-clean
c64-clean :

	rm -rf c64/*

.PHONY : c64-example
c64-example : ../c64-up2400-cc65/example/example.d64

	x64 -userportdevice 2 -rsuserdev 3 -rsuserbaud 2400 -rsdev4 "|echo 'hello'" -rsdev4baud 2400 -autostart "$<:example.prg"

.PHONY : c64-hw
c64-hw : c64/hw.prg

	x64 -userportdevice 2 -rsuserdev 3 -rsuserbaud 2400 -rsdev4 "|$(DISC) standard model.disc data.disc" -rsdev4baud 2400 -autostartprgmode 1 -autostart $<

.PHONY : c64-run
c64-run : c64/inst.prg

	# start disc
	sh scripts/start.sh /dev/stdin /dev/stdout disc.pid $(DISC) tcp 25232 model.disc data.disc

	# x64 -userportdevice 2 -rsuserdev 3 -rsuserbaud 2400 -rsdev4 "|$(DISC) standard model.disc data.disc" -rsdev4baud 2400 -autostartprgmode 1 -autostart $<
	x64 -userportdevice 2 -rsuserdev 2 -rsuserbaud 2400 -rsdev3baud 2400 -autostartprgmode 1 -autostart $<

	@$(STOPDISC)

# general assemble rule
c64/%.o : c64/%.s

	ca65 -t c64 -o $@ $<

# general compile rule
c64/%.s : %.c | c64

	cc65 -O -t c64 -DRF_TARGET_INC='"target/c64/default.inc"' -o $@ $<

c64/c64-up2400.s : c64/c64-up2400.ser

	co65 --code-label _c64_serial -o $@ $<
  
# C system lib
c64/rf_system_c.s : target/c64/system.c | c64

	cc65 -O -t c64 -o $@ $<

# Hello World
c64/hw.prg : hw.c | c64

	cl65 -O -t c64 -o $@ $^

# inst binary
c64/inst.prg : c64/main.o c64/rf.o c64/inst.o c64/rf_system_c.o c64/c64-up2400.o | c64

	cl65 -O -t c64 -o $@ -m c64/inst.map $^
