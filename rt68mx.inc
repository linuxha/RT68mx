	include "asl.inc"
;*
;* I'll clean this up later
;* For now I want RAM to $AFFF, IO at $E000, ROM start at $E100
;*
;*

RAM     EQU     $A000
IO      EQU     $E000

    IFDEF	NOMIKBUG
	;; Move ROM up and replace MIKBUG
ROM     EQU     $E000+$1C00     ; $FC00
    ELSE
	;; Keep funky ROM layout
ROM     EQU     $E000
    ENDIF

PROMPT  EQU     '$'

_8N1x16 EQU     $15             ;* 8-N-1 9600
_7E2x16 EQU     $11

ACIARST EQU     $03

USRDEF  EQU     $7000           ;*

;*[ Fini ]***********************************************************************

;/* Local Variables: */
;/* mode: asm        */
;/* End:             */
