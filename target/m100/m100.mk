# === TRS-80 Model 100 ===

m100 :

	mkdir $@

.PHONY : m100-hw
m100-hw : m100/hw.ba

	@printf '  \033[1;35mOn the target type RUN "COM:38N1D" <enter>\033[0;0m\n'
	@printf '  \033[1;35mThen on here press <enter>\033[0;0m\n'
	@read LINE
	@$(ORTER) serial -e 5 $(SERIALPORT) 300 < $<

m100/hw.ba : | m100

	printf '\r\n\r\n10 PRINT "Hello World ";\r\n' > $@.io
	printf '20 GOTO 10\r\n' >> $@.io
	printf '\r\n\032' >> $@.io
	mv $@.io $@

m100/hw.co : | m100

	zcc +m100 -subtype=default hw.c -o $@ -create-app
