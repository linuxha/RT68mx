# Makefile for the Motorola 6801/6803 lilbug monitor
# ncherry@linuxha.com 2023/01/04

all:	mikbug.s19 rt68mx.s19	

# ------------------------------------------------------------------------------
#
lilbug.s19: lilbug.p
	p2hex +5 -F Moto -r \$$-\$$ lilbug.p lilbug.s19
	ls
	srec_info lilbug.s19

lilbug.lst: lilbug.asm lilbug.inc ascii.inc
	asl -i . -D DEF9600 -L lilbug.asm

lilbug.p: lilbug.asm lilbug.inc ascii.inc
	asl -i . -D DEF9600 -L lilbug.asm

# ------------------------------------------------------------------------------
#
rt68mx.s19: rt68mx.p
	p2hex +5 -F Moto -r \$$-\$$ rt68mx.p rt68mx.s19
	ls
	srec_info rt68mx.s19

rt68mx.lst: rt68mx.asm rt68mx.inc
	asl -i . -L rt68mx.asm

rt68mx.p: rt68mx.asm rt68mx.inc asl.inc
	asl -i . -D NOMIKBUG -L rt68mx.asm

# ------------------------------------------------------------------------------
#
mikbug.s19: mikbug.p
	p2hex +5 -F Moto -r \$$-\$$ mikbug.p mikbug.s19
	ls
	srec_info mikbug.s19

mikbug.lst: mikbug.asm asl.inc
	asl -i .  -L mikbug.asm

mikbug.p: mikbug.asm ascii.inc
	asl -i . -D _E000 -L mikbug.asm

# ------------------------------------------------------------------------------
#
minibug.s19: minibug.p
	p2hex +5 -F Moto -r \$$-\$$ minibug.p minibug.s19
	ls
	srec_info minibug.s19

minibug.lst: minibug.asm asl.inc
	asl -i .  -L minibug.asm

minibug.p: minibug.asm ascii.inc
	asl -i . -L minibug.asm

# ------------------------------------------------------------------------------
#
rt68.s19: rt68.p
	p2hex +5 -F Moto -r \$$-\$$ rt68.p rt68.s19
	ls
	srec_info rt68.s19

rt68.lst: rt68.asm asl.inc
	asl -i .  -L rt68.asm

rt68.p: rt68.asm ascii.inc
	asl -i . -L rt68.asm

A:
	asl -i . -D NEW -L rt68.asm
	p2hex +5 -F Moto -r \$$-\$$ rt68.p rt68-NEW.s19

B:
	srec_cat rt68-NEW.s19 -o rt68.s19
	echo "rt68.s19"
	memsim2 rt68.s19

# ------------------------------------------------------------------------------
# 
clean:
	rm -f *.lst *.p foo bar *~ *.hex dstfile.srec *.srec
	echo Done

# # Assemble and convert to s19
# asl -i . -D DEF9600 -L lilbug.asm
# p2hex +5 -F Moto -r \$-\$ lilbug.p lilbug.s19
# # Not sure if the is the best way but it does work
# # Fill E000-F7FF with FF and append lilbug.s19
# srec_cat '(' -generate 0xE000 0xF800 --constant 0xFF ')' ~/lilbug.s19 -o dstfile.srec
# # convert the s19 to binary @ 0000
# srec_cat  dstfile.srec -offset -0xE000 -o lilbug.bin -binary
# # Use 2864A works for SEEQ and AT28C64-15 Note this automatically erases the chip
# minipro -p 28C64A -w lilbug.bin -y

burn: lilbug.s19
	srec_cat '(' -generate 0xE000 0xF800 --constant 0xFF ')' lilbug.s19 -o lilbug.srec
	srec_cat  lilbug.srec -offset -0xE000 -o lilbug.bin -binary
	@# We don't need sudo as we've fixed the device permission in the udev files
	minipro -p 28C64A -w lilbug.bin -y

# -[ Fini ]---------------------------------------------------------------------
