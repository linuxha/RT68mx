    ifndef      RT68MX_INC
RT68MX_INC      EQU     1

	include "asl.inc"
;*
;* I'll clean this up later
;* For now I want RAM to $AFFF, IO at $E000, ROM start at $E100
;*
;* -----------------------------------------------------------------------------
    ifdef       ROMORIG         
	;*
	;* Original locations except for Interrupt verstion @FFF8
	;*
      if mompass = 2
        message "###"
        message "### Built for MP-2 with IO @$F000" 
        message "###"
      endif

RAM     EQU     $A000
ROM     EQU     $E000
IO      EQU     $F000
INTVECT EQU     $FFF8

;* DEFINE PERIPHERIAL REGISTERS
	ORG  $F000	;* 
;* ACIA
ACIACS	RMB  1  	;*
ACIADB	RMB  1  	;*
;* PIA
PIADA	RMB  1  	;* 
PIACA	RMB  1  	;* 
PIADB	RMB  1  	;* 
PIACB	RMB  1  	;* 

MFILL   macro
            ;; Fill up to FFD0 with FF
            dc.b [(*+(INTVECT-*))&INTVECT-*]$ff
            ORG  INTVECT
        endm

    if mompass = 2
        message "RAM: $A000"
        message "ROM: $E000"
        message "I/O: $F000"
        message "VCT: $FFF8"
    endif

;* -----------------------------------------------------------------------------
    else                ;* -----------------------------------------------------
;* -----------------------------------------------------------------------------

      if mompass = 2
        message "###"
        message "### Built for MP-2 with IO @$E000 @FIXME" 
        message "###"
      endif

RAM     EQU     $A000
IO      EQU     $E000
    IFDEF	NOMIKBUG
	;; Move ROM up and replace MIKBUG
ROM     EQU     $E000+$1C00     ; $FC00
    ELSE
	;; Keep funky ROM layout
ROM     EQU     $E000
    ENDIF                       ;* NOMIKBUG
INTVECT EQU     ENDTBL          ;*

MFILL   macro
	    message "No Fill"
        endm

    if mompass = 2
        message "RAM: $A000"
        message "I/O: $E000"
        message "ROM: $E000"
        message "VCT: {ENTBL}"
    endif

;* DEFINE PERIPHERIAL REGISTERS
	ORG  $8004	;* 
PIADA	RMB  1  	;* 
PIACA	RMB  1  	;* 
PIADB	RMB  1  	;* 
PIACB	RMB  1  	;* 
ACIACS	RMB  1  	;* 
ACIADB	RMB  1  	;* 

    endif                       ;* ROMORG
;* -----------------------------------------------------------------------------

PROMPT  EQU     '$'

_8N1x16 EQU     $15             ;* 8-N-1 9600
_7E2x16 EQU     $11

ACIARST EQU     $03

USRDEF  EQU     $7000           ;*

    endif                       ;* if RT68MX_INC
;*[ Fini ]**********************************************************************

;/* Local Variables: */
;/* mode: asm        */
;/* End:             */
