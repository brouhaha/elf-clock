; COSMAC Elf program for clock using PIXIE display
; Copyright 2017 Eric Smith <spacewar@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of version 3 of the GNU General Public License
; as published by the Free Software Foundation.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; This source file is intended to assemble with the
; Macro Assembler AS:
;   http://john.ccac.rwth-aachen.de:8000/as/

; The program can be assembled to provide either a 12-hour or 24-hour
; digital clock, by defining clkhrs as either 12 or 24. If clkhrs is not
; defined by a command-line argument to the assembler, define it here:
	ifndef	clkhrs
clkhrs	equ	12
	endif

; ----------------------------------------------------------------------
; register definitions

; display DMA and interrupt
dmaptr	equ	0	; r0:  DMA pointer
intpc	equ	1	; r1:  interrupt program counter
sp	equ	2	; r2:  stack pointer

; main
mainpc	equ	3	; r3:  main program counter

; time counter update
digptr	equ	4	; r4:    pointer to digit being updated
limptr	equ	5	; r5:    pointer to increment limit

; time to bitmap decode
dptr2	equ	6	; r6:    digit pointer
prowc	equ	7	; r7.0:  count of pixel rows, used in decoder
pixcnt	equ	8	; r8.0:  count of pixel columns, used in decoder
bits	equ	9	; r9:    bitmap of character
bitmap	equ	10	; r10:   working bitmap pointer
tptr	equ	11	; r11:   die pattern table pointer

; display interrupt
rowcnt	equ	15	; r15.0: pixel row counter, used in interrupt

; ----------------------------------------------------------------------

; initialization

reset:

; Enable interrupts. This is not required if running directly from
; CDP1802 RESET/CLEAR, which leave interrupt enabled, but may be
; necessary if loading from a monitor program or operating system that
; disables interrupts. Note that this assumes that the X register is
; zero on entry, which is also true when running directly from CDP1802
; RESET/CLEAR.
	ret
	db	000h

	ghi	dmaptr

; for an Elf with only 256 bytes of RAM (undecoded), the following
; sequence of phi instructions could be omitted
	phi	intpc
	phi	mainpc
	phi	digptr
	phi	limptr
	phi	bitmap
	phi	tptr
	phi	dptr2

	plo	sp
	ldi	1
	phi	sp		; sp = 0x0100
				; interrupt will store T (X & P) at 0x00ff,
				; D at 0x00fe

	ldi	main		; main program
	plo	mainpc
	
	ldi	int		; interrupt program counter
	plo	intpc

	sep	3		; switch to main program counter,
				; to free R0 up for display DMA

main:	inp	1		; enable PIXIE

; main loop

main1:	ldi	hr10		; init display decode to leftmost
	plo	dptr2		; character

	ldi	dismem		; init bitmap pointer to top left
	plo	bitmap

mainlp:	idl			; wait for a display interrupt

; increment time by one frame

	ldi	frame
	plo	digptr

	ldi	limfrm
	plo	limptr
	sex	limptr

	bn4	incd1		; if not fast set mode, skip pointer decrements
				; to start with frame

incd:	dec	limptr
incd0:	dec	digptr

incd1:	ldn	digptr		; get digit
	shl			; is it a colon (negative)?
	bdf	incd0		; yes, skip to next byte

	ldn	digptr		; get digit
	adi	1
	str	digptr		; store updated digit

	sm			; compare with limit
	bnz	chkhr		; not at limit, done

	str	digptr		; hit limit, store zero

incd9:	glo	digptr		; incremented most significant digit?
	xri	hr10
	bnz	incd		; no, keep going

chkhr:	ldi	hr10
	plo	digptr

	lda	digptr		; compare hr1 = 1 for 12 hour, 2 for 24 hour
	sdi	clkhrs/12
	bnz	update

	ldn	digptr		; compare hr10 = 3 for 12 hour, 4 for 24 hour
	sdi	clkhrs/12+2
	bnz	update

	ldi	clkhrs=12	; hr1 = 1 for 12 hour, 0 for 24 hour
	str	digptr
	dec	digptr
	ghi	dmaptr		; hr10 = 0 for 12 hour, 0 for 24 hour
	str	digptr

; update one character of display bitmap
update:
	lda	dptr2
	shl			; double the digit value (two bytes in table per digit)
	adi	table
	plo	tptr
	lda	tptr
	phi	bits
	ldn	tptr
	plo	bits

	ldi	numl		; pixel row count
	plo	prowc

updrow:
	ghi	dmaptr		; always 0
	str	bitmap		; pixel bits = 0
	
	ldi	3		; horiz pixel counter
	plo	pixcnt

dpixel:	glo	bits
	shl
	plo	bits
	ghi	bits
	shlc
	phi	bits

	ldn	bitmap
	bnf	dpix0
	ori	0c0h		; set pixel bits
dpix0:	rshl			; rotate left two bits
	rshl
	str	bitmap

; advance pixel
dpix1:	dec	pixcnt
	glo	pixcnt
	bnz	dpixel

	glo	bitmap
	adi	8
	plo	bitmap

	dec	prowc		; last row of pixels?
	glo	prowc
	bnz	updrow		; no, decode next row

	glo	bitmap		; advance bitmap pointer for next char
	adi	1+256-(8*numl)
	plo	bitmap

	glo	dptr2		; finished rightmost digit?
	xri	sec1+1		; 
	bz	main1		; yes, go back to left

	glo	dptr2		; maybe do a second digit this time?
	shr
	bnf	update

	br	mainlp
	
; ----------------------------------------------------------------------

intret:
	ldxa		; restore D
	ret		; return, restoring X and P, and reenabling interrupt

; PIXIE display interrupt routine
; Note that this interrupt routine does not save and restore the DF flag,
; which works because the interrupt routine doesn't contain any add,
; subtract, or shift instructions.

int:	nop			;  0- 2  3 cyc instr for pgm sync

	dec	sp		;  3- 4  t -> stack
	sav			;  5- 6

	dec	sp		;  7- 8  d -> stack
	str	sp		;  9-10

	ldi	numl		; 11-12  set line counter
	plo	rowcnt		; 13-14

	sex	sp		; 15-16  no-op
	sex	sp		; 17-18  no-op

; setting high byte of dmaptr (R0) unnecessary, it's already 0
	ldi	dismem		; 19-20
	plo	dmaptr		; 21-22

disp:	glo	dmaptr		; 23-24  save pointer to start of this line
	dec	rowcnt		; 25-26
	sex	sp		; 27-28  no-op
; display 1st pixel scan line

	plo	dmaptr
	sex	sp		; no-op
	sex	sp		; no-op
; display 2nd pixel scan line

	plo	dmaptr
	glo	rowcnt
	bnz	disp
; display 3rd pixel scan line (even if the above bnz is taken)

; display blank rows until PIXIE drives EF1 high
	glo	dmaptr

blank1:	plo	dmaptr
	bn1	blank1

blank2:	plo	dmaptr
	b1	blank2

	br	intret

; ----------------------------------------------------------------------
; time counter

	if	clkhrs=12
hr10:	db	1
hr1:	db	2
	elseif	clkhrs=24
hr10:	db	0
hr1:	db	0
	endif

	db	0ffh	; colon

min10:	db	0
min1:	db	0

	db	0ffh	; colon

sec10:	db	0
sec1:	db	0

frame:	db	0

; ----------------------------------------------------------------------

limtab:	db	10	; 10 hr
	db	10	;  1 hr
	db	6	; 10 min
	db	10	;  1 min
	db	6	; 10 sec
	db	10	;  1 sec
limfrm:	db	61	; frame - 61 if Elf running from 3.579545 MHz / 2
			;         60 if Elf running from 1.76064 MHz

; ----------------------------------------------------------------------

; digit decode table
; five entries, each having 15 bits (LSB of second byte unused)
; three bits per pixel row, five rows

	db	008h,020h	; :  000 010 000 010 000   (char code 0ffh)
table:	db	0f6h,0deh	; 0  111 101 101 101 111
	db	059h,02eh	; 1  010 110 010 010 111
	db	0e7h,0ceh	; 2  111 001 111 100 111
	db	0e7h,09eh	; 3  111 001 111 001 111
	db	0b7h,092h	; 4  101 101 111 001 001
	db	0f3h,09eh	; 5  111 100 111 001 111
	db	0f3h,0deh	; 6  111 100 111 101 111
	db	0e4h,092h	; 7  111 001 001 001 001
	db	0f7h,0deh	; 8  111 101 111 101 111
	db	0f7h,09eh	; 9  111 101 111 001 111

; ----------------------------------------------------------------------

; display frame buffer
; eight bytes per display line (64 pixels)

dismem:	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
numl	equ	($-dismem)/8

; blank line used for remainder of display:
	db	000h,000h,000h,000h,000h,000h,000h,000h
