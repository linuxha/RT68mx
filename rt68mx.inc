	include "asl.inc"
;*

RAM     EQU     $A000

    IFDEF	NOMIKBUG
	;; Move ROM up and replace MIKBUG
ROM     EQU     $E000+$1C00     ; $FC00
    ELSE
	;; Keep funky ROM layout
ROM     EQU     $E000
    ENDIF

;*[ Fini ]***********************************************************************

;/* Local Variables: */
;/* mode: asm        */
;/* End:             */
