        MACEXP  off
        CPU     6800            ; That's what asl has
        include "asl.inc"       ;

       NAM    MINIB
;* MINI-BUG
;* COPYWRITE 1973, MOTOROLA INC
;* REV 004 (USED WITH MIKBUG)
;
;ACIACS EQU    @176364   ACIA CONTROL/STATUS ($FCF4-F5)
ACIACS EQU    $FCF4   ACIA CONTROL/STATUS ($FCF$
ACIADA EQU    ACIACS+1
       ORG    $FE00             ;* FE00-FEFF
* MINIB
* INPUT ONE CHAR INTO A-REGISTER
INCH   LDA A  ACIACS
       ASR A
       BCC    INCH     RECEIVE NOT READY
       LDA A  ACIADA   INPUT CHARACTER
       AND A  #$7F     RESET PARITY BIT
       CMP A  #$7F
       BEQ    INCH     RUBOUT; IGNORE
       JMP    OUTCH    ECHO CHAR

* INPUT HEX CHAR
INHEX  BSR    INCH
       CMP A  #$30
       BMI    C1       NOT HEX
       CMP A  #$39
       BLE    IN1HG
       CMP A  #$41
       BMI    C1       NOT HEX
       CMP A  #$46
       BGT    C1       NOT HEX
       SUB A  #7
IN1HG  RTS

LOAD   LDA A  #$D1     TURN READER ON
       STA A  ACIACS
       LDA A  #@21
       BSR    OUTCH

LOAD3  BSR    INCH
       CMP A  #'S
       BNE    LOAD3    1ST CHAR NOT (S)
       BSR    INCH
       CMP A  #'9
       BEQ    LOAD21
       CMP A  #'1
       BNE    LOAD3    2ND CHAR NOT (1)
       CLR    CKSM     ZERO CHECKSUM
       BSR    BYTE     READ BYTE
       SUB A  #2
       STA A  BYTECT   BYTE COUNT
* BUILD ADDRESS
       BSR    BADDR
* STORE DATA
LOAD11 BSR    BYTE
       DEC    BYTECT
       BEQ    LOAD15   ZERO BYTE COUNT
       STA A  X        STORE DATA
       INX
       BRA    LOAD11

LOAD15 INC    CKSM
       BEQ    LOAD3
LOAD19 LDA A  #'?      PRINT QUESTION MARK
       BSR    OUTCH
LOAD21 LDA A  #$B1     TURN READER OFF
       STA A  ACIACS
       LDA A  #@23
       BSR    OUTCH
C1     JMP    CONTRL

* BUILD ADDRESS
BADDR  BSR    BYTE     READ 2 FRAMES
       STA A  XHI
       BSR    BYTE
       STA A  XLOW
       LDX    XHI      (X) ADDRESS WE BUILT
       RTS

* INPUT BYTE (TWO FRAMES)
BYTE   BSR    INHEX    GET HEX CHAR
       ASL A
       ASL A
       ASL A
       ASL A
       TAB
       BSR    INHEX
       AND A  #$0F     MASK TO 4 BITS
       ABA
       TAB
       ADD B  CKSM
       STA B  CKSM
       RTS

* CHANGE MEMORY (M AAAA DD NN)
CHANGE BSR    BADDR    BUILD ADDRESS
       BSR    OUTS     PRINT SPACE
       BSR    OUT2HS
       BSR    BYTE
       DEX
       STA A  X
       CMP A  X
       BNE    LOAD19   MEMORY DID NOT CHANGE
       BRA    CONTRL

OUTHL  LSR A           OUT HEX LEFT BCD DIGIT
       LSR A
       LSR A
       LSR A

OUTHR  AND A  #$F      OUT HEX RIGHT BCD DIGIT
       ADD A  #$30
       CMP A  #$39
       BLS    OUTCH
       ADD A  #$7

* OUTPUT ONE CHAR
OUTCH  PSH B           SAVE B-REG
OUTC1  LDA B  ACIACS
       ASR B
       ASR B
       BCC    OUTC1    XMIT NOT READY
       STA A  ACIADA   OUTPUT CHARACTER
       PUL B
       RTS

OUT2H  LDA A  0,X      OUTPUT 2 HEX CHAR
       BSR    OUTHL    OUT LEFT HEX CHAR
       LDA A  0,X
       BSR    OUTHR    OUT RIGHT HEX VHAR
       INX
       RTS

OUT2HS BSR    OUT2H    OUTPUT 2 HEX CHAR + SPACE
OUTS   LDA A  #$20     SPACE
       BRA    OUTCH    (BSR & RTS)

     
* PRINT CONTENTS OF STACK
PRINT  TSX
       STX    SP       SAVE STACK POINTER
       LDA B  #9
PRINT2 BSR    OUT2HS   OUT 2 HEX & SPCACE
       DEC B
       BNE    PRINT2

* ENTER POWER ON SEQUENCE
START  EQU    *
* INZ ACIA
       LDA A  #$B1     SET SYSTEM PARAMETERS
       STA A  ACIACS

CONTRL LDS    #STACK   SET STACK POINTER
       LDA A  #$D      CARRIAGE RETURN
       BSR    OUTCH
       LDA A  #$A      LINE FEED
       BSR    OUTCH

       JSR    INCH     READ CHARACTER
       TAB
       BSR    OUTS     PRINT SPACE
       CMP B  #'L
       BNE    *+5
       JMP    LOAD
       CMP B  #'M
       BEQ    CHANGE
       CMP B  #'P
       BEQ    PRINT    STACK
       CMP B  #'G
       BNE    CONTRL
       RTI             GO


       ORG    $FF00
       RMB    40
STACK  RMB    1        STACK POINTER
* REGISTERS FOR GO
       RMB    1        CONDITION CODES
       RMB    1        B ACCUMULATOR
       RMB    1        A
       RMB    1        X-HIGH
       RMB    1        X-LOW
       RMB    1        P-HIGH
       RMB    1        P-LOW
SP     RMB    1        S-HIGH
       RMB    1        S-LOW
* END REGISTERS FOR GO
CKSM   RMB    1        CHECKSUM
BYTECT RMB    1        BYTE COUNT
XHI    RMB    1        XREG HIGH
XLOW   RMB    1        XREG LOW
       END
