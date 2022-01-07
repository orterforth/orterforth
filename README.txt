(Looking for * Retro *, the excellent non-traditional take on 
the Forth language? Go here instead: http://www.retroforth.org )


orterforth
==========


# Introduction #

orterforth is an implementation of fig-Forth 1.1 for multiple 
platforms. It is closely based on the fig-FORTH Installation 
Manual, Glossary, Model, Editor (1980).


# Building orterforth for the local system #

To target the local system (Linux, macOS, Cygwin), call:

 make

The target executable is built at the location:

 <os>-<arch>/orterforth.exe (on Cygwin)
 <os>-<arch>/orterforth     (on others)

where <os>   is e.g.: cygwin, darwin, linux
      <arch> is e.g.: armv6l, armv7l, i686, x86_64

To build and run the local system build call:

 make run


# Building orterforth for a target platform #

To target a historical platform, you will need prerequisites 
for each platform, such as a C compiler/assembler for the 
target platform, system ROM files in the roms directory, system
emulator source files and/or emulator installations.

For example, for the ZX Spectrum 48K, you will need:

* z88dk https://z88dk.org/
* Fuse emulator http://fuse-emulator.sourceforge.net
* Interface 1 ROM file (place in roms/spectrum )
* Z80 emulator https://github.com/superzazu/z80

To build, call:

 make TARGET=spectrum (to build using superzazu's emulator)
 make TARGET=spectrum SPECTRUMIMPL=fuse (to build in Fuse)

The target files will be built in the respective named 
directory, e.g.:

 spectrum/orterforth.bin (the pure binary)
 spectrum/orterforth.ser (with Interface 1 serial header for 
                         loading over RS-232 or ZX Net) 
 spectrum/orterforth.tap (TAP file with loader)

To run in Fuse, call:

 make run TARGET=spectrum

To load and run on a physical machine, connect the Interface 1
to your host system via RS-232 and call:

 make spectrum-load-serial


# Running orterforth #

First, bootstrap code reads and interprets Forth source code 
from an emulated disc drive, in the manner described in the 
Installation Manual. This compiles and builds up a complete 
Forth installation.

The fig-Forth source code comes from the Installation Manual, 
but is modified to allow for different platforms' processor 
architectures, word sizes, I/O, and so on.


# Using orterforth #

When installation is complete, the user is placed at Forth's 
interactive prompt.

The user can also use the emulated disc drive to load programs 
in the same way - with fig-Forth commands to load and 
manipulate "screens" of text (rather than a file system more 
familiar to modern users).


# orterforth is implemented in C #

A typical Forth implementation rests on a number of base words 
implemented in native machine code. Higher-level words are 
implemented with reference to other words, and "threaded" 
together to build complex programs.

In the Installation Manual, 6502 native code is assembled 
immediately following each word in memory (using an assembler 
implemented in Forth). The word's code field address (CFA) is 
pointed at this code.

By contrast, orterforth has platform-independent 
implementations of the base words in ANSI C. In the place of 
the 6502 assembly code, the CFA is set to point to this C code.


# Threaded jumps are implemented with a trampoline #

Forth implementations normally rely on jumps from successive 
native code, rather than subroutine calls. Because C does not 
properly allow such jumps, orterforth emulates them using a 
trampoline (a loop that successively calls function pointers).


# The retro disc controller is emulated #

orterforth interfaces with the emulated disc drive using the 
method found in the Installation Manual. The protocol used by 
the PerSci 1070 Intelligent Diskette Controller is partially 
implemented in Forth and used to read and write disc sectors 
directly.

Unlike in the Installation Manual, though, orterforth uses a 
serial interface to communicate with the disc drive. These are 
widely available on many historical platforms and can be 
generalised about in code.

Local system builds implement this interface in-process and 
access the disc files locally, but other target builds use the 
target's serial port capability and a server executable 
provides the interface over a serial link.

An RS-232 serial port can be added to a modern machine that 
doesn't have one, using a USB to RS-232 converter.


# Native machine code implementations can be integrated #

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


# Language extensions #

To support different platforms, while making the minimum of 
changes to the fig-Forth language itself, there are a small 
number of words added to the Forth dictionary to help make code
system-independent:

 rf-cell   ( -- n )    Returns the word size in bytes. (CELL is
                       not part of this version of fig-Forth.)

 rf-cells  ( n -- n )  Multiplies the value on the stack by the
                       word size. (CELLS is not part of this 
                       version of fig-Forth.)

 rf-code   ( addr -- ) Sets the code field of the most recent 
                       definition. Used by defining words 
                       instead of ;CODE and during installation
                       instead of inline assembler definitions.

 rf-exit   ( -- )      Exits orterforth (and returns to the 
                       shell, BASIC prompt or equivalent).

 rf-target ( -- d )    Returns a base-36 representation of
                       the target system (e.g., one of:
                       CYGWIN. DARWIN. LINUX. SPECTR. etc).

# Acknowledgements #

orterforth builds upon the work of many, most obviously the 
Forth Interest Group and those involved in putting together the
Installation Manual. Some other code has been adapted from works
believed to be in the public domain.

Dependencies (compilers, emulators, system ROMs, utilities) have
their own licence terms of course.

If any attribution has been missed I am happy to add it in here 
or in the appropriate place in the source code.
