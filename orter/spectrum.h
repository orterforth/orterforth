#ifndef ORTER_SPECTRUM_H_
#define ORTER_SPECTRUM_H_

int orter_spectrum_fuse_serial_getc(FILE *ptr);

int orter_spectrum_fuse_serial_putc(int c, FILE *ptr);

int orter_spectrum_header(const char *filename, unsigned char type_, unsigned short p1, unsigned short p2);

#endif /* ORTER_SPECTRUM_H_ */
