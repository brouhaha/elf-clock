#!/usr/bin/env python3
# Intel hex file to human-readable hex dump converter
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

import argparse
import sys

from intelhex import IntelHex

parser = argparse.ArgumentParser(description = 'Convert Intel hex file to human-readable hex dump')

parser.add_argument('input',
                    type = argparse.FileType('r'),
                    help = 'input file in Intel hex format')

parser.add_argument('-o', '--output',
                    type = argparse.FileType('w'),
                    default = sys.stdout,
                    help = 'hex dump output file')

args = parser.parse_args()

data = IntelHex().read(args.input, max_size = 256)
l = len(data)
bpl = 16
for la in range(0, l, bpl):
    if la > 0 and la % (4 * bpl) == 0:
        print(file = args.output)
    print('%04x:' % la, file = args.output, end = '')
    for j in range(bpl):
        if la + j < l:
            if j > 0 and j % 4 == 0:
                print(' ', file = args.output, end='')
            print(' %02x' % data[la + j], file = args.output, end='')
    print(file = args.output)

