;
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

;/* Local Variables: */
;/* mode:asm         */
;/* End:             */
