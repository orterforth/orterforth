(Looking for * Retro *, the excellent modern Forth
implementation? Go here instead: http://www.retroforth.org )


orterforth
==========


INTRODUCTION

orterforth is an implementation of Forth for multiple
platforms. It is closely based on the "fig-FORTH Installation
Manual" created by the Forth Interest Group (fig) in 1980.


QUICK START

To build and run orterforth, type:

 make run

You will see the following prompt:

 orterforth

Type:

 VLIST

for a list of all fig-Forth words and a few additional ones 
defined in orterforth.

To exit orterforth, type:

 MON

For more information on building and running, including for
other platforms, particularly retro ones, type:

 make help

Discussions and Issues are welcome:

https://github.com/orterforth/orterforth/discussions

https://github.com/orterforth/orterforth/issues


ORTERFORTH IS IMPLEMENTED IN C

A typical Forth implementation rests on a number of base words
implemented in native machine code. Higher-level words,
implemented in terms of these words, make up the rest of the
Forth vocabulary.

The Installation Manual contains source code that uses an
assembler (implemented in Forth) to assemble 6502 native code
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


THE INSTALLATION PROCESS

orterforth is bootstrapped from Forth source code derived from
the Installation Manual, loaded from an emulated disc drive.
The code is modified to allow for different platforms' 
processor architectures, cell sizes, I/O, memory layouts, and
so on.

On historical platforms, when install is complete, the memory
map containing the installation and the required native code
is saved to the emulated disc drive. (This is in a hex format
to avoid issues with control characters used by the disc
controller.)

This is then used to create completed installation binaries.

(On modern platforms, this whole installation process takes
place on startup every time the program is launched - the 
installation code and disc contents are part of the binary.)

To save space, the original installation code is loaded into a
memory location outside this area and does not form part of the
final binary.

When installation is complete, or when the final binary is
loaded, Forth starts with an interactive prompt.

The emulated disc drive is available to the user to load
programs in the same way it was used for install.


THE RETRO DISC CONTROLLER - EMULATED HERE

The Installation Manual contains an implementation of the 
protocol used by the PerSci 1070 Intelligent Diskette
Controller to communicate with a disc drive. Forth reads and
writes disc sectors directly rather than using a hierarchical
file system. Forth source code is stored in "screens" of 1024
bytes, corresponding directly to disc sectors.

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
use more general hand-assembled optimisation techniques.

However, it is possible to implement the inner interpreter and 
the native code words in assembly code and integrate them with 
the C code. This allows you to benefit from performance 
improvement but keep the practical advantages of C interop.

This is done by providing a mechanism to switch context
between assembly code, that uses direct jumps and registers,
and C code that uses the trampoline and memory locations. All
C code words must start by calling a hook to switch the
context, and the trampoline will switch it back.

NB In some cases this involves copying stack frames and other
intricate moves, to support everything the C compiler might do
with the stack before the first C statement (the hook) is
executed. These calling conventions and techniques vary between
C compilers.

Compiler defines are provided to allow assembly code to be
implemented incrementally, by omitting individual code words
from the C implementation and linking the assembly code
implemented thus far.

Once most of the code words have been implemented in assembly
code, control will flow between them via direct jumps and the
trampoline and hook will not be called, and performance will
generally be much better.


ADDITIONAL WORDS - PLATFORM INDEPENDENCE

To support different platforms, while making the minimum of 
changes to the fig-Forth language itself, there are a small 
number of words added to the Forth dictionary to help make code
system-independent:

 cl ( -- n )             Returns the cell size in bytes. (CELL
                         is not part of this version of fig-
                         Forth.)

 cs ( n -- n )           Multiplies the value on the stack by
                         the cell size. (CELLS is not part of
                         this version of fig-Forth.)

 ln ( c-addr -- a-addr ) Aligns the stack value according to
                         CPU requirements. (ALIGNED is not part
                         of this version of fig-Forth.)


BACKGROUND

orterforth is an attempt to reflect on the efforts of the Forth
Interest Group and create a working executable model for Forth
that could be ported to multiple machines. The Forth model
source was intended to be illustrative, for Forth implementers
to go away and create assembly listings of respective fig-Forth
implementations, which they did.

orterforth takes it literally and treats the model code as an
installation process, to generate a final binary (or, in modern
architectures, to simply run on startup).

The installation process for each machine is executable on real
hardware wherever possible - using the host machine's serial
port to connect to the emulated disc controller.

(It should, in theory, also work with a real PerSci 1070 disc
controller and 8" disc drives as was described in the
Installation Manual, via the serial interface - were anyone
able to locate working examples of these and write the model
source to a disc.)

More practically, modern automation scripts and machine
emulators can be used to create working Forth binaries for
different targets from the same source code on the same host
machine.

The idea is extended to modern architectures, but without
modifying the model source or the resulting Forth word set more
than necessary to make this work in a general way.

I have resisted extending the language with additional words
and capabilities; extensions like these can be added as desired
by linking in C or assembly code implementing these words, or
implementing them in Forth. Interesting projects in this
direction might be implementing bindings to the C standard
library, creating a platform-independent graphics library,
implementing multitasking, implementing security, and so on.

The C / assembly interop is, admittedly, an awkward exercise.
It requires a number of changes to the C code, such as calls
to worker functions after the RF_START hook, that would not
make sense outside of the context of attempting to override or
anticipate a particular C compiler's calling convention and
optimisations.

If we give the C code the role of a mere facilitator of the
installation process, and allow the possibility that other
approaches might be attempted (e.g., fully hand-assembled
code, or a more managed environment such as Python), then it
might seem less of an issue.

The idea of self-hosting - creating a Forth implementation that
builds itself from the absolute minimum of bootstrap code and
using few or no external tools - is a compelling one, but it's 
not the primary goal of this project. I am certainly open to
ways to reduce the amount of install code required as they
present themselves.


ACKNOWLEDGEMENTS

orterforth builds upon the work of many, most obviously the 
Forth Interest Group and those involved in putting together the
Installation Manual and their other public domain works.

GPLv3 does not, of course, apply to the works copied and/or
modified - they have their own terms, as do dependencies and
tools (compilers, emulators, system ROMs, utilities).

If any attribution has been missed I am happy to add it in here 
or in the appropriate place in the source code.
