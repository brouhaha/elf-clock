# Makefile for GNU make or other POSIX make (not nmake)
# COSMAC Elf program for clock using PIXIE display
# Copyright 2017 Eric Smith <spacewar@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of version 3 of the GNU General Public License
# as published by the Free Software Foundation.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

all: clock12.hex clock12.lst clock24.hex clock24.lst

%.hex: %.p
	p2hex $< $@

clock12.p clock12.lst: clock.asm
	asl -cpu 1802 -D clkhrs=12 -o clock12.p -L -OLIST clock12.lst +t 0xfc $<

clock24.p clock24.lst: clock.asm
	asl -cpu 1802 -D clkhrs=24 -o clock24.p -L -OLIST clock24.lst +t 0xfc $<

%.dump: %.hex
	./i2hd.py $< -o $@

%.pdf: %.lst
	mpage -2 -l $< | ps2pdf - $@

clean:
	rm -f *.p *.hex *.lst *.pdf
