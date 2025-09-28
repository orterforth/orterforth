#ifndef ORTER_WAV_H_
#define ORTER_WAV_H_

#include <stdint.h>

void orter_wav_start(void);

void orter_wav_write_16le(uint16_t u);

void orter_wav_write_silence(float len);

void orter_wav_write_cycle(float len);

void orter_wav_write_half_cycle(float len, float amp);

void orter_wav_end(void);

#endif /* ORTER_WAV_H_ */

