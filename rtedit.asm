; ==============================================================================
; This is the disassembly of the Microware's Tap RTEDIT
; ==============================================================================
;
;	Disassembled by:
;           f9dasm: M6800/1/2/3/8/9/H6309 Binary/OS9/FLEX9 Disassembler V1.82
;           Loaded binary file rtedit.bin
;
	MACEXP  off
        CPU     6800            ; That's what asl has
;
;
; ==============================================================================
        ;;
	macexp  on
        include "motorola.inc"          ; Macros for things like fcc,db, etc.
        include "MC6800.inc"
;
        include "rtedit.s"      	; f9dasm doesn't provide an easy way to prepend asm cmds
; -[ Fini ]---------------------------------------------------------------------
