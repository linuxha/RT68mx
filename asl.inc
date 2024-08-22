    ifndef ASL_INC
ASL_INC EQU     1
;
pag             macro
        NEWPAGE
                endm

opt             macro
                endm

nam             macro
                endm

noopt           macro
                endm

; This works but you need ttl "xyz abc" 
ttl             macro a
                TITLE a
                endm

spc             macro
                endm

list            macro
                listing on
                endm

nolist          macro
                listing off
                endm

page            macro
                newpage
                endm

PULD            macro
                PULA	; Pull the last thing off the stack
                PULB
                endm

PSHD            macro
                PSHB
                PSHA	; Pus the last thing on the stack
                endm
; ------------------------------------------------------------------------------
;
NULL    EQU $00                 ;
CTRL_AT EQU $00
CTRL_A  EQU $01                 ;
CTRL_C  EQU $03                 ;
CTRL_D  EQU $04                 ;
BELL    EQU $07                 ; Bell
GTRL_G  EQU $07                 ; Bell
CTRL_Q  EQU $11                 ; XOFF
CTRL_S  EQU $13                 ; XON
CTRL_U  EQU $15                 ; NAK
;
STX     EQU     $02             ; ^B
ETX     EQU     $03             ; ^C

CTRLK   EQU     $0B
CTRLO   EQU     $0F
DC1     EQU     $11             ;* Device control 1 ^Q Reader Start
DC2     EQU     $12             ;* Device control 2 ^R Punch Start
DC3     EQU     $13             ;* Device control 3 ^S Reader Stop
DC4     EQU     $14             ;* Device control 4 ^T Punch Stop
CTRLX   EQU     $18
CTRLZ   EQU     $1A
;
LF      EQU $0A                 ; ASL allows \n
CR      EQU $0D                 ; ASL allows \r
SPC     EQU $20                 ;

; upper byte of a 16 bit word:

hi              function x,(x>>8)&255

; the same for the lower byte:

lo              function x,x&255

    endif                       ;* if ASL_INC
;/* Local Variables: */
;/* mode:asm         */
;/* End:             */
