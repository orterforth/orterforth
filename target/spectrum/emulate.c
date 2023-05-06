#include <stdio.h>
#include <stdlib.h>

#include "../../persci.h"
#include "../../tools/github.com/superzazu/z80/z80.h"

static z80 *z = 0;

static uint8_t in(z80* const z, uint8_t port) {

  switch (port) {
    /* keyboard - no key pressed */
    case 0xFE:
      return 0x1F;
      break;
    /* Interface 1 */
    case 0xEF:
      return 0x00;
      break;
    default:
      break;
  }

  return 0x00;
}

static void out(z80* const z, uint8_t port, uint8_t val) {
}

static uint8_t bus_rd(void* userdata, uint16_t addr);

static void bus_wr(void* userdata, uint16_t addr, uint8_t val);

static void cpu_init(void)
{
  z = malloc(sizeof(z80));
  if (!z) {
    fprintf(stderr, "malloc failed for z80\n");
    exit(1);
  }

  z80_init(z);

  z->read_byte = bus_rd;
  z->write_byte = bus_wr;
  z->port_in = in;
  z->port_out = out;
}

static unsigned long cpu_cycles(void)
{
  return z->cyc;
}

static uint8_t cpu_a_get(void)
{
  return z->a;
}

static void cpu_a_set(uint8_t a)
{
  z->a = a;
}

static void cpu_cf_set(uint8_t cf)
{
  z->cf = cf;
}

static uint16_t cpu_de_get(void)
{
  return (z->d << 8) | z->e;
}

static uint16_t cpu_ix_get(void)
{
  return z->ix;
}

static uint16_t cpu_pc_get(void)
{
  return z->pc;
}

static void cpu_pc_set(uint16_t pc)
{
  z->pc = pc;
}

static void cpu_push(uint16_t val)
{
  bus_wr(0, --(z->sp), val >> 8);
  bus_wr(0, --(z->sp), val & 0xFF);
}

static uint16_t cpu_pop(void)
{
  uint16_t val;
  
  val = (uint16_t) bus_rd(0, (z->sp)++);
  val |= (uint16_t) (bus_rd(0, (z->sp)++)) << 8;
  return val;
}

/* memory */

static uint8_t *rom = 0;
static uint8_t *if1rom = 0;
static uint8_t *ram = 0;
static uint8_t *ram_ptr = 0;
static uint8_t *paged = 0;

static uint8_t bus_rd(void* userdata, uint16_t addr)
{
  /* ROM */
  if (!(addr & 0xE000)) {
    uint8_t b = paged[addr];
    switch (addr) {
      /* page in */
      case 0x0008:
      case 0x1708:
        paged = if1rom;
        break;
      /* page out */
      case 0x0700:
        paged = rom;
        break;
      default:
        break;
    }
    return b;
  }
  if (!(addr & 0xC000)) {
    return rom[addr];
  }
  /* RAM */
  return ram_ptr[addr];
}

static void bus_wr(void *userdata, uint16_t addr, uint8_t val)
{
  /* ROM */
  if (addr < 0x4000) {
    return;
  }
  /* RAM */
  ram_ptr[addr] = val;
}

static uint8_t *load(const char* filename)
{
  long size;
  uint8_t *memory;

  /* open file */
  FILE* f = fopen(filename, "rb");
  if (!f) {
    perror("can't open file");
    exit(1);
  }

  /* get file size */
  if (fseek(f, 0, SEEK_END)) {
    perror("can't fseek file");
    exit(1);
  }
  size = ftell(f);
  if (size == -1) {
    perror("can't ftell file");
    exit(1);
  }
  if (fseek(f, 0, SEEK_SET)) {
    perror("can't fseek file");
    exit(1);
  }

  /* allocate memory */
  memory = malloc(size);
  if (memory == 0) {
    perror("can't malloc");
    exit(1);
  }

  /* read data into memory */
  if ((long) fread(memory, sizeof(uint8_t), size, f) != size) {
    perror("can't read file");
    exit(1);
  } 

  /* close file */
  if (fclose(f)) {
    perror("can't close file");
    exit(1);
  }

  return memory;
}

/* LOAD "" <enter> */
static char *keys = "\357\"\"\r";
static int keyidx = 0;

static FILE *tap = 0;

static void tape_load(char *name)
{
  if (tap) {
    fprintf(stderr, "tape already loaded");
    exit(1);
  }

  tap = fopen(name, "rb");
  if (!tap) {
    perror("tap file open failed");
    exit(1);
  }
}

static uint8_t tape_getc(void)
{
  int c;

  /* check tape loaded */
  if (!tap) {
    fprintf(stderr, "tape not present");
    exit(1);
  }

  /* read a byte */
  c = fgetc(tap);
  if (c == -1) {
    if (fclose(tap)) {
      perror("tap file close failed");
    }
    tap = 0;
  }

  /* return byte */
  return c;
}

static int finished = 0;

static void hook_key_input(void)
{
  if (keys[keyidx] == '\0') {
    return;
  }

  bus_wr(0, 0x5C3B, bus_rd(0, 0x5C38) | 0x20); /* FLAGS 5 key pressed */
  bus_wr(0, 0x5C08, keys[keyidx++]); /* LAST_K */
}

static void hook_ld_bytes(void)
{
  uint16_t i;
  uint16_t len;
  uint8_t flag;
  uint16_t st, en;

  /* SA_LD_RET */
  cpu_push(0x053F);

  /* read TAP block length */
  len = (uint16_t) tape_getc();
  len |= (tape_getc() << 8);

  /* read TAP flag byte */
  flag = tape_getc();
  if (flag != cpu_a_get()) {
    fprintf(stderr, "flag doesn't match %d %d\n", flag, cpu_a_get());
    exit(1);
  }

  /* read TAP block data into memory */
  st = cpu_ix_get();
  en = st + cpu_de_get();
  for (i = st; i != en; i++) {
    bus_wr(0, i, tape_getc());      
  }
  fgetc(tap); 

  /* continue at end of subroutine */
  cpu_cf_set(1); /* no error */
  cpu_pc_set(0x05E2); /* RET */
}

static void hook_error_1(void)
{
  /* read hook code */
  uint16_t ad = cpu_pop();
  uint8_t hook_code = bus_rd(0, ad);

  /* implement */
  switch (hook_code) {
    /* BCHAN-IN */
    case 0x1d:
      cpu_a_set(rf_persci_getc());
      cpu_cf_set(1);
      break;

    /* BCHAN-OUT */
    case 0x1e:
      if (cpu_a_get() == 'Z') {
        finished = 1;
      }
      if (rf_persci_putc(cpu_a_get()) == -1) {
        fprintf(stderr, "rf_persci_putc invalid state\n");
        exit(1);
      }
      break;

    default:
      break;
  }

  /* return after hook code */
  cpu_pc_set(++ad);
}

inline static void hook(void)
{
  switch (cpu_pc_get()) {
    case 0x0000:
      /* START or MAIN-ROM */
      if (keyidx > 0) {
        fprintf(stderr, "reset\n");
        exit(1);
        finished = 1;
      }
      break;
    case 0x0008:
      /* ERROR_1 or ST-SHADOW */
      hook_error_1();
      break;
    case 0x0556:
      /* LD_BYTES */
      hook_ld_bytes();
      break;
    case 0x10A8:
      /* KEY_INPUT */
      hook_key_input();
      break;
    default:
      break;
  }
}

static void init(void)
{
  /* ROM */
  rom = load("roms/spectrum/spectrum.rom");
  if1rom = load("roms/spectrum/if1-2.rom");
  paged = rom;

  /* RAM */
  ram = malloc(0xC000);
  if (!ram) {
    fprintf(stderr, "RAM not allocated\n");
    exit(1);
  }
  /* RAM pointer but relative to zero */
  ram_ptr = ram - 0x4000;

  /* CPU */
  cpu_init();

  /* tape */
  tape_load("spectrum/inst-2.tap");

  /* disc */
  rf_persci_insert(0, "model.img");
  rf_persci_insert(1, "spectrum/orterforth.bin.hex.io");
}

static inline uint8_t get_f(z80* const z) {
  uint8_t val = 0;
  val |= z->cf << 0;
  val |= z->nf << 1;
  val |= z->pf << 2;
  val |= z->xf << 3;
  val |= z->hf << 4;
  val |= z->yf << 5;
  val |= z->zf << 6;
  val |= z->sf << 7;
  return val;
}

static void run(void)
{
  unsigned long since_int = 0;
/*
  unsigned long steps = 0;
*/
  finished = 0;
/*
  while (!finished && steps < 0x180000) {
*/
  while (!finished) {
    /* hooks */
    hook();
/*
    printf("T:PC=%04X AF=%04X BC=%04X DE=%04X HL=%04X AF'=%04X BC'=%04X DE'=%04X HL'=%04X SP=%04X IR=%04X\n",
      z->pc, 
      (uint16_t) (z->a) << 8 | (uint16_t) get_f(z),
      (uint16_t) (z->b) << 8 | (uint16_t) (z->c),
      (uint16_t) (z->d) << 8 | (uint16_t) (z->e),
      (uint16_t) (z->h) << 8 | (uint16_t) (z->l),
      (uint16_t) (z->a_) << 8 | (uint16_t) (z->f_),
      (uint16_t) (z->b_) << 8 | (uint16_t) (z->c_),
      (uint16_t) (z->d_) << 8 | (uint16_t) (z->e_),
      (uint16_t) (z->h_) << 8 | (uint16_t) (z->l_),
      z->sp,
      (uint16_t) (z->i) << 8 | (uint16_t) (z->r)
    );
*/
/*
    if (bus_rd(0, z->pc) == 0x78) {
      exit(0);
    }
*/
    /* CPU step */
    z80_step(z);
/*
    steps++;
*/
    /* interrupt */
    if (cpu_cycles() - since_int > 70000) {
      z80_gen_int(z, 0);
      since_int = cpu_cycles();
    }
  }
}

static void fin(void)
{
  free(ram);
  free(rom);
  free(if1rom);
}

int main(void)
{
  init();
  run();
  fin();

  return 0;
}
