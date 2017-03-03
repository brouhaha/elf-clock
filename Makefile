all: clock.hex clock.lst

%.hex: %.p
	p2hex $< $@

%.p %.lst: %.asm
	asl -L +t 0xfc $<

%.pdf: %.lst
	mpage -2 -l $< | ps2pdf - $@

clean:
	rm -f *.p *.hex *.lst *.pdf
