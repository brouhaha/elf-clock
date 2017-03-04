# elf-clock - Clock program for COSMAC Elf with PIXIE Graphics

Copyright 2017 Eric Smith <spacewar@gmail.com>

elf-clock development is hosted at the
[elf-clock Github repository](https://github.com/brouhaha/elf-clock/).

## Introduction

This program use a COSMAC Elf microcomputer (CDP1802 microprocessor)
with a PIXIE graphics chip (CDP1861) to display a digital clock on an
NTSC monitor. Only 256 bytes of RAM are required, as provided on an
unexpanded Elf or Elf II, though the program will also work if more
RAM is present. By default a 12-hour clock is provided, but the line
"clkhrs equ 12" can be changed to "clkhrs equ 24" to assemble a 24-hour
clock instead.

Pressing and holding the Elf INPUT button will activate the "fast" set
mode, which counts at 60 times normal speed (one minute per second),
in order to allow setting the current time. Unfortunately that's still
quite slow, so I recommend setting the clock not too long after
midnight, or for the 12-hour clock, after noon.

As provided, the timing assumes that the Elf clock is provided by a
3.579545 MHz crystal (NTSC color burst) divided by two, which is a
common configuration for an Elf with a CDP1861 PIXIE graphics chip,
resulting in a field rate of 60.9928 Hz. The program divides this by
61 to get seconds, so the error is fairly small. A trimmer capacitor
could be added to the crystal oscillator circuit to allow fine
adjustment.

If you have an Elf with a 1.76064 MHz clock, the field rate is 60.0000
Hz, so you can change the byte at address 00B5 in the program from 3D
to 3C to divide by 60 rather than 61.

If you have an Elf with some other clock frequency, there will be
greater error in the timekeeping. C'est la vie.

The program occupies 254 bytes out of the 256 bytes of memory of an
unexpanded Elf, with the remaining 2 bytes used for the stack.

This has been tested on a Netronics ELF II, and on the EMMA 02
emulator.


## License information:

This program is free software: you can redistribute it and/or modify
it under the terms of version 3 of the GNU General Public License
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
