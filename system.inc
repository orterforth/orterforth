/*
system.inc - System specific details, included in rf.h
*/

/*
The disc impl is process local, not accessed over serial.
Also, the model disc is included in the binary, so the inst
process "inserts" this disc data and "ejects" it after inst.
*/
#define RF_INST_LOCAL_DISC

/*
Accept command line arguments. Some platforms may put garbage
in argc/argv, so undefine this to avoid processing them.
*/
#ifndef PICO
#ifndef ESP_PLATFORM
#define RF_ARGS
#endif
#endif

/*
Put RP and SP operations inline, code is larger but faster.
Undefine these to define RP and SP operations as functions,
for smaller but slower code.
*/
#define RF_INLINE_RP
#define RF_INLINE_SP

/*
Write a table of code addresses at the end of the save process
described under RF_INST_SAVE below. This is used by platforms
where the install location is static but the executable code
is loaded dynamically (e.g., Sinclair QL, which installs into
RESPR but loads the executable as a job). The table is used on
startup to relink code fields, and other fields that need to
be relocated.
*/
#undef RF_INST_LINK

/*
Define this to save the resulting installation once inst is
complete. This does not make sense on most modern platforms,
as memory addresses are dynamic and the executable code is
not located within the memory area defined for this save
process.
*/
#undef RF_INST_SAVE

/*
Hide output during inst time. Once a working EMIT is available
to the inst process, defining some words leads to a MSG # 4 as
they are already defined for inst purposes. Defining this 
suppresses output until inst is complete, for those platforms
where inst is always carried out on startup.
*/
#define RF_INST_SILENT

/*
Don't treat memory addresses as constants. Targets that don't
define this benefit from knowing the address of ORIGIN, S0,
TIB, R0, USER, etc at compile time and the install is smaller.
*/
#define RF_INST_DYNAMIC

/*
Allocated memory size. Platforms that allocate the Forth memory
map dynamically need a reasonable amount of memory available.
Modify if your purpose requires it. Here it is proportional to 
cell size to account for memory usage being proportional to 
cell size.
*/
#define RF_MEMORY_SIZE (32768*RF_WORD_SIZE)

/*
Pointer to the start of memory, whether heap or static.
*/
extern char *rf_origin;

/*
ORIGIN at start of memory, used for +ORIGIN and to initialise DP.
*/
#define RF_ORIGIN (rf_origin)

/*
LIMIT at the end of memory, by default much of the memory map
(FIRST, UP, R0, TIB, S0) is defined by working back from this.
*/
#define RF_LIMIT ((char *) rf_origin + RF_MEMORY_SIZE)
