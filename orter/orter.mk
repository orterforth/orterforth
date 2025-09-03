# orter - retrocomputing multitool
$(ORTER) : \
	$(SYSTEM)/orter_atari.o \
	$(SYSTEM)/orter_bbc.o \
	$(SYSTEM)/orter_c64.o \
	$(SYSTEM)/orter_dragon.o \
	$(SYSTEM)/orter_hex.o \
	$(SYSTEM)/orter_hx20.o \
	$(SYSTEM)/orter_io.o \
	$(SYSTEM)/orter_m100.o \
	$(SYSTEM)/orter_pty.o \
	$(SYSTEM)/orter_ql.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_spectrum.o \
	$(SYSTEM)/orter_tcp.o \
	$(SYSTEM)/orter_wav.o \
	$(SYSTEM)/orter_z88.o \
	orter/main.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^ -lm -lutil

# Atari 8-bit
$(SYSTEM)/orter_atari.o : orter/atari.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# BBC Micro
$(SYSTEM)/orter_bbc.o : orter/bbc.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Commodore 64
$(SYSTEM)/orter_c64.o : orter/c64.c orter/io.h orter/wav.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Dragon 32/64
$(SYSTEM)/orter_dragon.o : orter/dragon.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# hex utilities
$(SYSTEM)/orter_hex.o : orter/hex.c orter/hex.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Epson HX-20
$(SYSTEM)/orter_hx20.o : orter/hx20.c orter/io.h orter/wav.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# nonblocking I/O utilities
$(SYSTEM)/orter_io.o : orter/io.c orter/io.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# TRS-80 Model 100
$(SYSTEM)/orter_m100.o : orter/m100.c orter/m100.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# pty handling
$(SYSTEM)/orter_pty.o : orter/pty.c orter/io.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Sinclair QL
$(SYSTEM)/orter_ql.o : orter/ql.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# serial port handling
$(SYSTEM)/orter_serial.o : orter/serial.c orter/io.h orter/serial.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# TCP
$(SYSTEM)/orter_tcp.o : orter/tcp.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Sinclair ZX Spectrum
$(SYSTEM)/orter_spectrum.o : orter/spectrum.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# WAV
$(SYSTEM)/orter_wav.o : orter/wav.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# Cambridge Z88
$(SYSTEM)/orter_z88.o : orter/z88.c orter/z88.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<
