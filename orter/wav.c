#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "io.h"

#define SAMPLERATE 44100.0

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static uint8_t *orter_wav_buf = 0;
static size_t orter_wav_buf_siz = 0;
static size_t orter_wav_buf_idx = 0;

void orter_wav_start(void)
{
  orter_wav_buf = 0;
  orter_wav_buf_siz = 0;
  orter_wav_buf_idx = 0;
}

void orter_wav_write_16le(uint16_t u)
{
  while (orter_wav_buf_idx >= orter_wav_buf_siz) {
    orter_wav_buf_siz += 256;
    orter_wav_buf = realloc(orter_wav_buf, orter_wav_buf_siz);
  }

  orter_io_set_16le(u, orter_wav_buf + orter_wav_buf_idx);
  orter_wav_buf_idx += 2;
}

void orter_wav_write_silence(float len)
{
    int steps = SAMPLERATE * len;
    int i;

    for (i = 0; i < steps; ++i) {
        orter_wav_write_16le(0);
    }
}

void orter_wav_write_cycle(float len)
{
    int steps = SAMPLERATE * len;
    int i;

    for (i = 0; i < steps; ++i) {
        orter_wav_write_16le(0 - (32767.0 * sin((float) i / (float) steps * 2.0 * M_PI)));
    }
}

void orter_wav_end(void)
{
  /* RIFF header */
  fputs("RIFF", stdout);
  orter_io_write_32le(orter_wav_buf_idx + 36);
  fputs("WAVE", stdout);

  /* format chunk */
  fputs("fmt ", stdout);
  /* format length */
  orter_io_write_32le(16);
  /* PCM */
  orter_io_write_16le(1);
  /* 1 channel */
  orter_io_write_16le(1);
  /* CD sample rate */
  orter_io_write_32le(44100);
  /* (sample rate * 16 bits per sample * 1 channel) / 8 */
  orter_io_write_32le(88200);
  /* (16 bits per sample * 1 channel) / 8 */
  orter_io_write_16le(2);
  /* 16 bits per sample */
  orter_io_write_16le(16);

  /* data chunk */
  fputs("data", stdout);
  /* length */
  orter_io_write_32le(orter_wav_buf_idx);
  /* data */
  fwrite(orter_wav_buf, 1, orter_wav_buf_idx, stdout);

  fflush(stdout);
}
