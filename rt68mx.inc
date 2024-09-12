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

LOWRAM  EQU     $0000
RAM     EQU     $A000
ROM     EQU     $E000
IO      EQU     $F000           ;* MP02 & sim6800 (I think)
INTVECT EQU     $FFF8

;* DEFINE PERIPHERIAL REGISTERS
        ORG  IO      ;* 
;* ACIA $F000
ACIACS  RMB  1          ;* 0
ACIADB  RMB  1          ;* 1
        RMB  2          ;* filler
;* PIA  $F004
PIADA   RMB  1          ;* 4
PIACA   RMB  1          ;* 5
PIADB   RMB  1          ;* 6
PIACB   RMB  1          ;* 7

MFILL   macro
            ;; Fill up to FFD0 with FF
            dc.b [(*+(INTVECT-*))&INTVECT-*]$ff
            ORG  INTVECT
        endm
;* -----------------------------------------------------------------------------
    else                ;* -----------------------------------------------------
;* -----------------------------------------------------------------------------
    ifdef       EXP
        ;*
        ;* Original locations except for Interrupt verstion @FFF8
        ;*
      if mompass = 2
        message "###"
        message "### Built for MP-2 with IO @$F000 EXP" 
        message "###"
      endif

LOWRAM  EQU     $0000
RAM     EQU     $A000
ROM     EQU     $E000
IO      EQU     $F000           ;* MP02 & sim6800 (I think)
INTVECT EQU     $FFF8

;* DEFINE PERIPHERIAL REGISTERS
        ORG  IO      ;* 
;* ACIA $F000
ACIACS  RMB  1          ;* 0
ACIADB  RMB  1          ;* 1
        RMB  2          ;* filler
;* PIA  $F004
PIADA   RMB  1          ;* 4
PIACA   RMB  1          ;* 5
PIADB   RMB  1          ;* 6
PIACB   RMB  1          ;* 7

MFILL   macro
            ;; Fill up to FFD0 with FF
            dc.b [(*+(INTVECT-*))&INTVECT-*]$ff
            ORG  INTVECT
        endm
;* -----------------------------------------------------------------------------
    else                ;* -[ Default ]-----------------------------------------
;* -----------------------------------------------------------------------------
      if mompass = 2
        message "###"
        message "### Built for MP-2 with IO @$E000 @FIXME" 
        message "###"
      endif

LOWRAM  EQU     $0000
RAM     EQU     $A000
IO      EQU     $E000
    IFDEF       NOMIKBUG
        ;; Move ROM up and replace MIKBUG
ROM     EQU     $E000+$1C00     ; $FC00
    ELSE
        ;; Keep funky ROM layout
;ROM    EQU     $E000
ROM     EQU     $E000+$0100     ;* IO at $E000, ROM at $E100
    ENDIF                       ;* NOMIKBUG
INTVECT EQU     "undefined"     ;*

MFILL   macro
            message "No Fill"
        endm

;* DEFINE PERIPHERIAL REGISTERS
;       ORG  $8004      ;* I don't know where $8004 comes from
;       ORG  $E000      ;* 
        ORG  IO         ;* 
PIADA   RMB  1          ;* 
PIACA   RMB  1          ;* 
PIADB   RMB  1          ;* 
PIACB   RMB  1          ;* 
ACIACS  RMB  1          ;* 
ACIADB  RMB  1          ;* 

    endif               ;* EXP (there is no elseifdef)
    endif               ;* ROMORG
;* -----------------------------------------------------------------------------

    if mompass = 2
        message "LOWRAM: $\{LOWRAM}"
        message "RAM:    $\{RAM}"
        message "ROM:    $\{ROM}"
        message "I/O:    $\{IO}"
        message "VCT:    $\{INTVECT}"
    endif               ;* mompass = 2

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
