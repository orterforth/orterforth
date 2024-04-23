amiga :

	mkdir $@

amiga/hw : amiga/hw.o

	vc $< -o $@

amiga/hw.o : hw.c | amiga

	vc -c $< -o $@
