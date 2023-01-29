# === TRS-80 Model 100 ===

m100 :

	mkdir $@

m100/hw.co : | m100

	zcc +m100 -subtype=default hw.c -o $@ -create-app
