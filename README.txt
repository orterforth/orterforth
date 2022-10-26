(Looking for * Retro *, the excellent modern Forth
implementation? Go here instead: http://www.retroforth.org )


orterforth
==========


INTRODUCTION

orterforth is an implementation of fig-Forth 1.1 for multiple 
platforms. It is closely based on the fig-FORTH Installation 
Manual, Glossary, Model, Editor created by the Forth Interest
Group (fig) in 1980.


BUILDING

To build orterforth for the local system (Linux, macOS, 
Cygwin), call:

 make

The target executable is built at the location:

 <os>-<arch>/orterforth.exe (on Cygwin)
 <os>-<arch>/orterforth     (on others)

where <os>   is e.g.: cygwin, darwin, linux
      <arch> is e.g.: armv6l, armv7l, i686, x86_64

To build a version implemented in assembly, for performance,
call:

 make clean
 make SYSTEMOPTION=assembly

The target executable is built at the location:

 <os>-<arch>/orterforth.exe (on Cygwin)
 <os>-<arch>/orterforth     (on others)

where <os>   is e.g.: cygwin, darwin, linux
      <arch> is e.g.: armv6l, armv7l, i686, x86_64


BUILDING

To build and run the local system build call:

 make run


BUILDING FOR RETRO PLATFORMS

To build orterforth for a historical platform, you will need 
prerequisites such as:

* a C compiler/assembler for the target platform,
* system ROM files in the roms directory,
* system emulator source files, and/or 
* emulator installations.

For more details of what is needed for a target, call:

 make help TARGET=<target>

where <target> is e.g.: bbc, spectrum

Then to build call:

 make TARGET=<target>


RUNNING ON RETRO PLATFORMS

orterforth can be built and run in an emulator (if installed)
by calling:

 make run TARGET=<target>


ORTERFORTH IS IMPLEMENTED IN C

A typical Forth implementation rests on a number of base words
implemented in native machine code. Higher-level words are 
implemented in terms of these words, making up the rest of the
Forth vocabulary.

The Installation Manual contains source code that uses an
assembler implemented in Forth to assemble 6502 native code
immediately following each base word in memory. The word's code
field address (CFA) points at this code.

Instead of this, orterforth has platform-independent 
implementations of each base word in C. The CFA is set to point
to this C code.


THE TRAMPOLINE - EMULATING JUMPS IN C

Forth implementations normally use jump instructions to
transfer control through successive native code, rather than 
subroutine calls. Because C does not properly allow such jumps,
orterforth emulates them using a trampoline - a loop that 
successively calls function pointers.


THE RETRO DISC CONTROLLER - EMULATED HERE

The Installation Manual contains an implementation of the 
protocol used by the PerSci 1070 Intelligent Diskette
Controller to communicate with a disc drive. Forth reads and
writes disc sectors directly rather than using a hierarchical
file system, providing access to "screens" of source code.

orterforth provides an emulated version of this. It partly
implements the protocol at the controller end, uses files as
disc images and reads or writes to them as necessary.

Unlike in the Installation Manual, though, orterforth uses a 
serial interface to communicate with the disc drive. Because
many platforms have serial ports, they can connect to such a 
disc controller in a common way.

The build for the local system implements this serial interface
in-process and accesses the disc files locally, but builds for
other targets use the target's serial port capability. A server
executable provides the interface over a serial link, or via
a virtual mechanism of some kind for an emulator.

An RS-232 serial port can be added to a modern machine that 
doesn't have one, using a USB to RS-232 converter.


INTEGRATING WITH ASSEMBLY CODE - IMPROVING PERFORMANCE

orterforth will usually be substantially slower than other 
Forth implementations written in assembly code, because many 
of the optimisations available to those aren't practical in C.

Most Forth implementations do not use a trampoline, but 
instead use direct jumps to and from the inner interpreter. 
They also use registers rather than memory locations to hold 
values such as pointers and/or stack values. Finally, they can 
use more general hand optimisation techniques.

However, it is possible to implement the inner interpreter and 
the native code words in assembly code and integrate them with 
the C code. This allows you to benefit from performance 
improvement but keep the practical advantages of C interop.

This is done by providing a mechanism to switch context
between optimised code, that uses direct jumps and registers,
and C code that uses the trampoline and memory locations. All
C code words must start by calling a hook to switch the
context, and the trampoline will switch it back.

NB In some cases this involves copying stack frames and other
intricate moves, to support everything the C compiler might do
with the stack. It is also necessary to try to prevent the C
compiler from moving stack operations before the hook.

Compiler defines are provided to allow assembly code to be
implemented incrementally, by omitting individual code words
from the C implementation and linking the assembly code
implemented thus far.


ADDITIONAL WORDS - PLATFORM INDEPENDENCE

To support different platforms, while making the minimum of 
changes to the fig-Forth language itself, there are a small 
number of words added to the Forth dictionary to help make code
system-independent:

 cl ( -- n )             Returns the word size in bytes. (CELL
                         is not part of this version of fig-
                         Forth.)

 cs ( n -- n )           Multiplies the value on the stack by
                         the word size. (CELLS is not part of
                         this version of fig-Forth.)

 ln ( c-addr -- a-addr ) Aligns the stack value according to
                         CPU requirements. Used in CREATE when
                         adding the name field and in other 
                         non-aligned dictionary operations. 
                         (ALIGNED is not part of this version
                         of fig-Forth.)

 tg ( -- d )             Returns a base-36 representation of
                         the target system (e.g., one of: BBC.
                         CYGWIN. DARWIN. LINUX. PICO. RC2014.
                         SPECTR. etc).

 xt ( -- )               Exits orterforth (and returns to the
                         shell, BASIC prompt or equivalent).
                         Used to exit the install process.


THE INSTALLATION PROCESS

First, installation code written in C reads and interprets
Forth source code from the emulated disc drive, in the manner
described in the Installation Manual. This compiles and builds
up the complete Forth installation.

The fig-Forth source code comes from the Installation Manual, 
but is modified to allow for different platforms' processor 
architectures, word sizes, I/O, memory layouts, and so on.

On historical platforms, when install is complete, the memory
map containing the installation and the required native code
is saved to the emulated disc drive. (This is in a hex format
to avoid issues with control characters used by the disc
controller).

This is then used to create completed installation binaries.

To save space, the original installation code is loaded into a
memory location outside this area and does not form part of the
final binary.

(On modern platforms, this whole installation process takes
place on startup every time the program is launched - the 
installation code and disc contents are part of the binary.)

When installation is complete, or when the final binary is
loaded, the user is placed at Forth's interactive prompt.

The emulated disc drive is available to the user to load
programs in the same way it was used for install.


ACKNOWLEDGEMENTS

orterforth builds upon the work of many, most obviously the 
Forth Interest Group and those involved in putting together the
Installation Manual and their other public domain works.

Dependencies (compilers, emulators, system ROMs, utilities) have
their own licence terms of course.

If any attribution has been missed I am happy to add it in here 
or in the appropriate place in the source code.
