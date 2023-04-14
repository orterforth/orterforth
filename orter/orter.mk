# orter - retrocomputing multitool
$(ORTER) : \
	$(SYSTEM)/orter_bbc.o \
	$(SYSTEM)/orter_hex.o \
	$(SYSTEM)/orter_io.o \
	$(SYSTEM)/orter_ql.o \
	$(SYSTEM)/orter_serial.o \
	$(SYSTEM)/orter_spectrum.o \
	$(SYSTEM)/orter_z88.o \
	orter/main.c

	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $^

# orter libs - BBC Micro
$(SYSTEM)/orter_bbc.o : orter/bbc.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# orter libs - hex utilities
$(SYSTEM)/orter_hex.o : orter/hex.c orter/hex.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# orter libs - nonblocking I/O utilities
$(SYSTEM)/orter_io.o : orter/io.c orter/io.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# orter libs - Sinclair QL
$(SYSTEM)/orter_ql.o : orter/ql.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# orter libs - serial port handling
$(SYSTEM)/orter_serial.o : orter/serial.c orter/io.h orter/serial.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# orter libs - Sinclair ZX Spectrum
$(SYSTEM)/orter_spectrum.o : orter/spectrum.c | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

# orter libs - Cambridge Z88
$(SYSTEM)/orter_z88.o : orter/z88.c orter/z88.h | $(SYSTEM)

	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<
