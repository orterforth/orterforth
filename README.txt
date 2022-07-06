(Looking for * Retro *, the excellent modern Forth
implementation? Go here instead: http://www.retroforth.org )


orterforth
==========


# Introduction #

orterforth is an implementation of fig-Forth 1.1 for multiple 
platforms. It is closely based on the fig-FORTH Installation 
Manual, Glossary, Model, Editor (1980).


# Building #

To build orterforth for the local system (Linux, macOS, 
Cygwin), call:

 make

The target executable is built at the location:

 <os>-<arch>/orterforth.exe (on Cygwin)
 <os>-<arch>/orterforth     (on others)

where <os>   is e.g.: cygwin, darwin, linux
      <arch> is e.g.: armv6l, armv7l, i686, x86_64


# Running #

To build and run the local system build call:

 make run


# Building for another platform #

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


# Running on another platform #

orterforth can be built and run in an emulator (if installed)
by calling:

 make run TARGET=<target>


# orterforth is implemented in C #

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


# orterforth uses a trampoline to execute code #

Forth implementations normally use jump instructions to
transfer control through successive native code, rather than 
subroutine calls. Because C does not properly allow such jumps,
orterforth emulates them using a trampoline - a loop that 
successively calls function pointers.


# orterforth emulates the retro disc controller #

The Installation Manual contains an implementation of the 
protocol used by the PerSci 1070 Intelligent Diskette
Controller to communicate with a disc drive. Forth reads and
writes disc sectors directly rather than using a hierarchical
file system, providing access to "screens" of source code.

orterforth provides an emulated version of this. It partly
implements the protocol at the controller end, uses files as
disc images and reads or writes to to them as necessary.

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


# orterforth integrates with native machine code #

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


# orterforth has a few additional words #

To support different platforms, while making the minimum of 
changes to the fig-Forth language itself, there are a small 
number of words added to the Forth dictionary to help make code
system-independent:

 rcll ( -- n )    Returns the word size in bytes. (CELL is not
                  part of this version of fig-Forth.)

 rcls ( n -- n )  Multiplies the value on the stack by the word
                  size. (CELLS is not part of this version of
                  fig-Forth.)

 rcod ( addr -- ) Sets the code field of the most recent
                  definition. Used by defining words instead
                  of ;CODE and during installation instead of
                  inline assembler definitions.

 rlns ( n -- n )  Aligns the stack value according to CPU
                  requirements. Used in CREATE when adding the
                  name field and in other non-aligned
                  dictionary operations. (ALIGNED is not part
                  of this version of fig-Forth.)

 rxit ( -- )      Exits orterforth (and returns to the shell,
                  BASIC prompt or equivalent).

 rtgt ( -- d )    Returns a base-36 representation of the
                  target system (e.g., one of: BBC. CYGWIN.
                  DARWIN. LINUX. SPECTR. etc).


# It starts by installing from Forth source code #

First, installation code written in C reads and interprets
Forth source code from the emulated disc drive, in the manner
described in the Installation Manual. This compiles and builds
up a complete Forth installation.

The fig-Forth source code comes from the Installation Manual, 
but is modified to allow for different platforms' processor 
architectures, word sizes, I/O, memory layouts, and so on.


# It saves the completed Forth installation to disc #

On historical platforms, when install is complete, the memory
map containing the installation and the required native code
is saved to the emulated disc drive. This is in a hex format
to avoid issues with control characters used by the disc
controller).

This is then used to create completed installation binaries.

To save space, the original installation code is loaded into a
memory location outside this area and does not form part of the
final binary.


# Now Forth is started #

When installation is complete, or when the final binary is 
loaded, the user is placed at Forth's interactive prompt.

The user can use the emulated disc drive to load programs
in the same way it was used for install.


# Acknowledgements #

orterforth builds upon the work of many, most obviously the 
Forth Interest Group and those involved in putting together the
Installation Manual and their other public domain works.

Dependencies (compilers, emulators, system ROMs, utilities) have
their own licence terms of course.

If any attribution has been missed I am happy to add it in here 
or in the appropriate place in the source code.
