;* -----------------------------------------------------------------------------
;*
;* RTEDIT, part of Microware's RT68/MX development package
;*
;* RTEDIT is a A/BASIC compiled BASIC program, source which is included with the
;* A/BASIC compiler manuals.

;* -----------------------------------------------------------------------------
; f9dasm: M6800/1/2/3/8/9 / H6309 Binary/OS9/FLEX9 Disassembler V1.83
; Loaded binary file rtedit.bin
	include "asl.inc"

NL      EQU     $0D

PROMPT  EQU     '?'

;; STX     EQU     $02
;; ETX     EQU     $03

;; CTRLK   EQU     $0B
;; CTRLO   EQU     $0F
;; DC1     EQU     $11             ;* Device control 1
;; DC2     EQU     $12             ;* Device control 2
;; DC3     EQU     $13             ;* Device control 3
;; DC4     EQU     $14             ;* Device control 4
;; CTRLX   EQU     $18
;; CTRLZ   EQU     $1A

COMMA   EQU     $2C

    IFNDEF      LINES
LINES   EQU     0
    ENDIF

    IFDEF       DEFAULT
PLINES  EQU     50
BUFSZ   EQU     100
    ELSE        LINES=100
PLINES  EQU     100
BUFSZ   EQU     200
    ELSE        LINES=127
PLINES  EQU     127
BUFSZ   EQU     254
    ENDIF
;* MEMORY DEFINITIONS
;
;* RT/68 EXECUTIVE USES 12 BYTES OF RAM
;* BEGINNING AT 0, THESE ARE NOT NEEDED
;* IN SINGLE TASK MODE AND MAY BE
;* USED FOR ANY OTHER PURPOSE.
	ORG  0 		;*
SYSMOD	RMB  1  	;* RT MODE 0=USER 1=EXEC        0000
CURTSK	RMB  1  	;* TASK CURRENTLY ACTIVE        0001
TIMREM	RMB  1  	;* TASK TIME REMAINING          0002
TSKTMR	RMB  2  	;* TIMED TASK COUNTER           0003
CLOCK	RMB  2  	;* RT CLOCK COUNTER             0005
INTREQ	RMB  1  	;* INTERRUPT REQUEST FLAG       0007
TSKTMP	RMB  1  	;* RT EXEC TEMP VAL             0008
PTYTMP	RMB  1  	;* RT EXEC TEMP VAL             0009
TIMTSK	RMB  1  	;* TIMED TASK INTR STATUS       000A
SYSPTY	RMB  1  	;* SYS PRIORITY LEVEL           000B

	ORG  $A000	;* 
;	ORG  RAM	;* 
IRQTSK	RMB  2  	;* A000 -IRQ TASK/VECTOR
BEGADR	RMB  2  	;* A002
ENDADR	RMB  2  	;* A004
NMITSK	RMB  2  	;* A006 - NMI TASK/VECTOR
SPTMP	RMB  2  	;* A008 - SP TMP VAL
RTMOD	RMB  1  	;* A009 - RT MODE FLAG
BKPOP	RMB  1  	;* A00A - BKPT OPCODE/FLAG
BKPADR	RMB  2  	;* A00C - BKPT ADDRESS
RELFLG	RMB  1  	;* A00D - SWI FLAG
ERRFLG	RMB  1  	;* A00E - ERROR FLAG/CODE
XTMP	RMB  2  	;* A00F
IOVECT	RMB  2  	;* A010 - ACIA ADDRESS VECTOR

	ORG  $A042	;* 
STACK	EQU  *  	;* MONITOR STACK

;* TASK STATUS TABLE
;*
;* CONSISTS OF 16 3-BYTE TASK STATUS WORDS, ONE FOR
;* EACH POSSIBLE TASK. EACH TASK STATUS WORD CONTAINS
;* A TASK STATUS BYTE (TSB) AND A 2-BYTE TASK STACK
;* POINTER (TSP)
;*
;* THE TSB IS DEFINED AS FOLLOWS:
;*
;*	BIT 7	1=TASK ON	0=TASK OFF
;*	BIT 6-3	TIME LIMIT IN TICKS (0-15)
;*	BIT 2-0	TASK PRIORITY (0-7)
;*
;* THE TSP IS THE VALUE OF THE TASK'S STACK
;* POINTER FOLLOWING THE LAST INTERRUPT, AND
;* THEREFORE POINTS TO THE COMPLETE MPU
;* REGISTER CONTENTS AT THE TIME THE TASK WAS
;* INTERRUPTED. TO RESTART A TASK THE EXEC
;* INITIALIZES THE SP FROM THE TSP AND
;* EXECUTES AN RTI INSTRUCTION
;*
	ORG  $A050	;* 
TSKTBL	RMB  48  	;* 

;* DEFINE PERIPHERIAL REGISTERS
;*
;* Pin 40 - CA1 - external Clock, interrupt source (<=100Hz)
;* Pin 39 - CA2 - Abort switch
;*
    IFDEF    DEFAULT
	ORG  $8004	;* 
PIADA	RMB  1  	;* 8004
PIACA	RMB  1  	;* 8005
PIADB	RMB  1  	;* 8006
PIACB	RMB  1  	;* 8007

ACIACS	RMB  1  	;* 8000 Why is this here, after the PIA?
ACIADB	RMB  1  	;* 8001
    ELSE
        ORG  $F000
ACIACS	RMB  1  	;* F000
ACIADB	RMB  1  	;* F001
ACIAC2  RMB  1          ;* F002 Dummy ACIA
ACIAD2  RMB  1          ;* F003 Dummy ACIA

PIADA	RMB  1  	;* F004
PIACA	RMB  1  	;* F005
PIADB	RMB  1  	;* F006
PIACB	RMB  1  	;* F007
    ENDIF
;****************************************************
;* Used Labels                                      *
;****************************************************

        ORG     $0020           ;* $0020 - $0071

;* 
;* $20 = Xreg tmp, for strings, I/O  (a038)
;* $22 = I/O Buffer position pointer (1 1000)
;* $24 = I/O Buffer begin address    (1000)
;* $26 = Char count                  ($01 ?)
;* $27 = string buffer pointer       (1081)
;* $29 = string operation Xreg tmp
;* $2B = Multiplication overflow word, overflow word, string scratch storage (1374)
;* $2b -
;* $2F = string misc scratch         (01ff 1000)
;* 
XSAVE   RMB     2               ;* EQU     $0020    ;* Appears to be the stack
BUFPTR  RMB     2               ;* EQU     $0022    ;* B$ , 1000
BUFBEG  RMB     2               ;* EQU     $0024    ;* B$ , 1000
CHRCNT  RMB     1               ;* EQU     $0026    ;* 10
;
;M0027
    IFDEF       DEFAULT
STRPTR  RMB     1               ;* EQU     $0027 Hi
M0028   RMB     1               ;* EQU     $0028 Lo
    ELSE
STRPTR  RMB     2               ;* EQU     $0027 Hi ;* 1081 (some kind of buffer)
;0028   RMB     1               ;* EQU     $0028 Lo
    ENDIF
;*
;* Variables
;*
;* Starts at 0029 ends at ~0071
;*
;* BUF$(128) = &1000
;* B$(100) &1081 appears to be a duplicate
;*
;* OPT S
;* ORG=$0100    <- Code starts at 0100
;* BASE=$1300   <- Data starts at 1300
;* N(50)        =  50 = $32 (base 16)
;* B$(100)      = 100 = $64 (base 16) ($1081-$10E5 ?)
;* BASE=$30     <- Data starts at 0030
;* A1
;* BUF$         <- Global variable, 128 byte buffer (builtin)
;* C1
;* H            <- Something to do with lines of BASIC
;* J *
;* K *
;* L
;* P1
;* Q *
;* S
;* S1
;* T *
;* V *
;* X *
;* X1
;* Z
;* Z$
;*
;* >md 0020
;* 0020    a0 38 10 00 10 00 01 10 81 13 77 01 ff 10 00 ff  .8........w.....
;* 0030    00 32 00 01 00 32 31 30 00 ff ff ff ff ff ff ff  .2...210........
;* 0040    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 0050    ff ff ff ff ff ff 00 0a 00 11 ff ff ff ff ff ff  ................
;* 0060    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 0070    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;*
MSAVEX
STRSAV  RMB     1               ;* EQU     $0029 ;* 1377 ?
M002A   RMB     1               ;* EQU     $002A ;* 
M002B   RMB     1               ;* EQU     $002B ;* 01FF ?
M002C   RMB     1               ;* EQU     $002C ;*
M002D   RMB     2               ;* EQU     $002D ;* 1000
M002F   RMB     1               ;* EQU     $002F ;* FF

        ;;
        ;;  BASE=$30 Date pointer here
        ;; 
MEMTOP                          ;*
V
M0030   RMB     1               ;* EQU     $0030 ;* 0032 ? 
M0031   RMB     1               ;* EQU     $0031
DTMP                            ;* A:B/Dreg Temp
K
M0032   RMB     1               ;* EQU     $0032 ;* 
M0033   RMB     1               ;* EQU     $0033
AST1
M0034   RMB     1               ;* EQU     $0034
M0035   RMB     1               ;* EQU     $0035
; ???
_Z                              ;* Z$
M0036   RMB     $20             ;* EQU     $0036
Z
M0056   RMB     1               ;* EQU     $0056
M0057   RMB     1               ;* EQU     $0057
;*
;* LINPTR = Memory location of the next line? (char maybe?)
;*
X
M0058   RMB     1               ;* EQU     $0058
M0059   RMB     1               ;* EQU     $0059
L
M005A   RMB     1               ;* EQU     $005A
M005B   RMB     1               ;* EQU     $005B
T
M005C   RMB     1               ;* EQU     $005C
M005D   RMB     1               ;* EQU     $005D
H
M005E   RMB     1               ;* EQU     $005E
M005F   RMB     1               ;* EQU     $005F
A1
M0060   RMB     1               ;* EQU     $0060
M0061   RMB     1               ;* EQU     $0061
S1
M0062   RMB     1               ;* EQU     $0062
M0063   RMB     1               ;* EQU     $0063
S
M0064   RMB     1               ;* EQU     $0064
M0065   RMB     1               ;* EQU     $0065
P1
M0066   RMB     1               ;* EQU     $0066
M0067   RMB     1               ;* EQU     $0067
X1
M0068   RMB     1               ;* EQU     $0068
M0069   RMB     1               ;* EQU     $0069
AST2
M006A   RMB     1               ;* EQU     $006A
M006B   RMB     1               ;* EQU     $006B
J
M006C   RMB     1               ;* EQU     $006C
M006D   RMB     1               ;* EQU     $006D
Q
M006E   RMB     1               ;* EQU     $006E
M006F   RMB     1               ;* EQU     $006F
;* Matched pair M0070 & M0071
C1
M0070   RMB     1               ;* EQU     $0070
M0071   RMB     1               ;* EQU     $0071

;*         RTS                              ;0FDB: 39             '9'
;*; ----------------------------------------------------------------------------
;*;Z0FE2
;*; Not really sure what this is
;*; Is this not the end?
;*;0FDC   JSR     Z031A                    ;0FDC: BD 03 1A       '...'
;*X0FDC   JSR     LDFROM                   ;0FDC: BD 03 1A       '...'
;*	  ;;
;*        ;; This is past the end of the code
;*        ;; 
;*        FCB     $24                      ;0FDF: 24             '$'
;*
;*        END
;*; END @ 0FDB but also $0FE0
;* -----------------------------------------------------------------------------
;* Memory usage
;* | 0000 | 000B | RT68MX multitask exec |
;* | 000C | 001F | Unused ?              |
;* | 0020 | 0071 | RTEDIT variables      |
;* | 0072 | 00FF | Unused ?              |
;* | 0100 | 0FF0 | Code (0FDB End?)      |
;* | 0FF0 | 0FFF | ???                   |
;* | 1000 | 1301 | ???                   |
;* | 1000 | 1081 | ???                   |
;* | 1082 | 1301 | ???                   |
;* 
;* 
;* -----------------------------------------------------------------------------
Z0DF4   equ     $0DF4

	ORG     $0FE2
;* VAR LEN $0EA8
;* PGM LEN $0EDC
;* PBM END $0FDB
Z0FE2   RMB     1               ;* EQU     $0FE2 ???

; END @ 0FDB but also $0FF0
MEND    equ     $0FF0

IO      EQU     $1000
BUF     EQU     $1000
M1000   EQU     $1000           ;* 128 bytes
;1081   EQU     $1081
ST
SBFPTR  EQU     $1081
BASE    EQU     $1300           ;* BASIC cmd BASE=
ZZ      EQU     $1300
N       EQU     $1302           ;* N $64 100 = N(50) stored as INTs
;*
;* $1346 means something, don't know what yet
;*
M1346   EQU     $1346
_B      EQU     $1366           ;* B$(100) = 32 * 100 = 3200 ($0C80 $1366 - $1FE6)

;* 1366
;* >md 1360
;* 1360    00 00 00 00 00 00 31 30 20 52 45 4d 20 43 6f 6d  ......10 REM Com
;* 1370    6d 65 6e 74 00 ff ff ff ff ff ff ff ff ff ff ff  ment............
;* 
;* Probably the code buffer
;* >md 1300
;* 1300    13 02 00 0a 00 00 00 00 00 00 00 00 00 00 00 00  ................
;* 1310    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
;* 1320    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
;* 1330    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
;* 1340    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
;* 1350    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
;* 1360    00 00 00 00 00 00 31 30 20 52 45 4d 20 43 6f 6d  ......10 REM Com 1366
;* 1370    6d 65 6e 74 00 ff ff ff ff ff ff ff ff ff ff ff  ment............
;* 1380    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1390    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 
;* Probably a line buffer
;* >md FD0
;* 0fd0    01 b7 13 00 fe 13 00 a6 00 e6 01 39 bd 03 1a 24  ...........9...$
;* 0fe0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 0ff0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1000    31 30 20 52 45 4d 20 43 6f 6d 6d 65 6e 74 00 ff  10 REM Comment.. 1000
;* 1010    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1020    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1030    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1040    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1050    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1060    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* >md 1070
;* 1070    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1080    ff 31 30 20 52 45 4d 20 43 6f 6d 6d 65 6e 74 00  .10 REM Comment. 1081
;* 1090    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 10a0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 10b0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 10c0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 10d0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 10e0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 10f0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1100    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 
;* >md 1110
;* 1110    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1120    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1130    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1140    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1150    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1160    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1170    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1180    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 1190    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 11a0    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 
;* Stack (started at A049)
;* 
;* >R
;* PC=e1a0 A:B=f781 X=a03d SP=a035 CCR=d9(11hINzvC)        [0]
;* e1a0    00              ---
;* 
;* >md a020
;* a020    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a030    ff e3 a9 00 0c e1 d8 81 ef a0 3d 04 98 00 33 19  ..........=...3.
;* a040    a6 e1 8f ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a050    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 
;*  Internal variables
;* 
;* >md 0
;* 0000    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 0010    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 0020    a0 38 10 00 10 00 01 10 81 13 74 01 ff 10 00 ff  .8........t.....
;* 0030    00 32 00 01 00 32 31 30 00 ff ff ff ff ff ff ff  .2...210........
;* 0040    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 0050    ff ff ff ff ff ff 00 0a 00 0e ff ff ff ff ff ff  ................
;* 0060    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 
;* >md a000
;* a000    ff ff 00 ff 01 00 ff ff a0 42 00 00 ff ff ff 00  .........B......
;* a010    e3 d4 f0 00 ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a020    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a030    ff e3 a9 00 0c e1 d8 81 ef a0 3d 04 98 00 33 19  ..........=...3.
;* a040    a6 e1 8f ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a050    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a060    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a070    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a080    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* a090    ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff  ................
;* 
;* 
;* 
MCF10   EQU     $CF10           ;* ???

;
; RT68 equates ?
;
;PDATA1 EQU     $E07E           ;* PDATA ? YES
PRSTR   EQU     $E07E           ;* PDATA ? YES
OUTS    EQU     $E0CC           ;* OUTS - Print SPC OUTS
PRSPC   EQU     $E0CC           ;* OUTS - Print SPC OUTS
CRLF    EQU     $E141           ;* CRLF - Print CRLF
PCRLF   EQU     $E141           ;* CRLF - Print CRLF
CONENT  EQU     $E16A           ;* Console (return to console?)
CONSLE  EQU     $E16A           ;* Console (return to console?)
;* Same
IN1CHR  EQU     $E350           ;* INEEE ? Yes
;* Same
OUT1CH  EQU     $E3A6           ;* OUTEEE ? Yes

;****************************************************
;* Program Code / Data Areas                        *
;****************************************************

        ORG     $0100
;
; Not sure how the stack gets setup but there are lots of TSX
;
; ------------------------------------------------------------------------------
        ;;
        ;; V=$0032 (50)
START   CLRA                             ;0100: 4F             'O'
        LDAB    #$32                     ;0101: C6 32          '.2'
;       STAB    M0031                    ;0103: D7 31          '.1'
;       STAA    M0030                    ;0105: 97 30          '.0'
        STAB    lo(V)                    ;0103: D7 31          '.1'
        STAA    hi(V)                    ;0105: 97 30          '.0'
        ;;
        ;; K=$0001
        ;; 
        CLRA                             ;0107: 4F             'O'
        LDAB    #$01                     ;0108: C6 01          '..'
;       STAB    M0033                    ;010A: D7 33          '.3'
;       STAA    M0032                    ;010C: 97 32          '.2'
        STAB    lo(K)                    ;010A: D7 33          '.3'
        STAA    hi(K)                    ;010C: 97 32          '.2'
 ;      LDAB    M0031                    ;010E: D6 31          '.1'
 ;      LDAA    M0030                    ;0110: 96 30          '.0'
        LDAB    lo(V)                    ;010E: D6 31          '.1'
        LDAA    hi(V)                    ;0110: 96 30          '.0'
        STAB    M0035                    ;0112: D7 35          '.5'
        STAA    M0034                    ;0114: 97 34          '.4'
; ------------------------------------------------------------------------------
; WTFrell? D6 33 is LDAB M0033
;0116   LDAB    M0033                    ;0116: D6 33          '.3'
;       LDAA    M0032                    ;0118: 96 32          '.2'
Z0116   LDAB    lo(K)                    ;0116: D6 33          '.3'
        LDAA    hi(k)                    ;0118: 96 32          '.2'
        ASLB                             ;011A: 58             'X'
        ROLA                             ;011B: 49             'I'
        ADDB    #$00                     ;011C: CB 00          '..'
        ADCA    #$13                     ;011E: 89 13          '..'
        PSHB                             ;0120: 37             '7'
        PSHA                             ;0121: 36             '6'
        CLRA                             ;0122: 4F             'O'
        CLRB                             ;0123: 5F             '_'
        TSX                              ;0124: 30             '0'
        LDX     ,X                       ;0125: EE 00          '..'
        INS                              ;0127: 31             '1'
        INS                              ;0128: 31             '1'
        STAA    $00,X                    ;0129: A7 00          '..'
        STAB    $01,X                    ;012B: E7 01          '..'
;       LDAB    M0033                    ;012D: D6 33          '.3'
;       LDAA    M0032                    ;012F: 96 32          '.2'
        LDAB    lo(K)                    ;012D: D6 33          '.3'
        LDAA    hi(K)                    ;012F: 96 32          '.2'
        ;;
        ;;  K=K+1 (NEXT K in FOR loop)
        ADDB    #$01                     ;0131: CB 01          '..'
        ADCA    #$00                     ;0133: 89 00          '..'
;       STAB    M0033                    ;0135: D7 33          '.3'
;       STAA    M0032                    ;0137: 97 32          '.2'
        STAB    lo(K)                    ;0135: D7 33          '.3'
        STAA    hi(K)                    ;0137: 97 32          '.2'
        SUBB    M0035                    ;0139: D0 35          '.5'
        SBCA    M0034                    ;013B: 92 34          '.4'
        ;;
        ;; Convoluted way to get back to Z0116
        ;; 
        BLT     Z0144                    ;013D: 2D 05          '-.'
WARMST
;       BNE     Z0147                    ;013F: 26 06          '&.'
        BNE     MENU                     ;013F: 26 06          '&.'
; ------------------------------------------------------------------------------
; WTFrell
WTF001  TSTB                             ;0141: 5D             ']'
;       BNE     Z0147                    ;0142: 26 03          '&.'
        BNE     MENU                     ;0142: 26 03          '&.'
Z0144   JMP     Z0116                    ;0144: 7E 01 16       '~..'
; ------------------------------------------------------------------------------
;* Probably main loop
;* Line 100 (ie GOTO 100)
;*
LN0100
MENU                                     ; LN0100
;0147   LDX     #M1000                   ;0147: CE 10 00       '...'
Z0147   LDX     #BUF                     ;0147: CE 10 00       '...'
        JSR     Z0D7F                    ;014A: BD 0D 7F       '...'
        JSR     Z0DD3                    ;014D: BD 0D D3       '...'
;       LDX     #M1000                   ;0150: CE 10 00       '...'
        LDX     #BUF                     ;0150: CE 10 00       '...'
;       JSR     Z0D14                    ;0153: BD 0D 14       '...'
        ;;
        ;; INPUT BUF$ - Get command line buffer
        ;; 
        JSR     INPUT                    ;0153: BD 0D 14       '...'
        LDAA    #hi(SBFPTR)              ;0156: 86 10          '..'
        LDAB    #lo(SBFPTR)              ;0158: C6 81          '..'
        STAB    STRPTR+1                 ;015A: D7 28          '.('
        STAA    STRPTR                   ;015C: 97 27          '.''
        ;;
        ;; Save space on the stack?
        ;; 
        DES                              ;015E: 34             '4'
        DES                              ;015F: 34             '4'
        JSR     Z0E68                    ;0160: BD 0E 68       '..h'
;       LDX     #M1000                   ;0163: CE 10 00       '...'
        LDX     #BUF                     ;0163: CE 10 00       '...'
        JSR     Z0F00                    ;0166: BD 0F 00       '...'
        CLRA                             ;0169: 4F             'O'
        LDAB    #$02                     ;016A: C6 02          '..'njc

        JSR     Z0EE5                    ;016C: BD 0E E5       '...'
        LDX     #SBFPTR                  ;016F: CE 10 81       '...'
        STX     STRPTR                   ;0172: DF 27          '.''
        ;;
        ;; Z$ ?
        ;; 
        LDX     #M0036                   ;0174: CE 00 36       '..6'
        JSR     Z0EA0                    ;0177: BD 0E A0       '...'
        LDX     #M0036                   ;017A: CE 00 36       '..6'
        LDAA    #hi(SBFPTR)              ;017D: 86 10          '..'
        LDAB    #lo(SBFPTR)              ;017F: C6 81          '..'
        STAB    STRPTR+1                 ;0181: D7 28          '.('
        STAA    STRPTR                   ;0183: 97 27          '.''
        JSR     Z0F09                    ;0185: BD 0F 09       '...'
        JSR     Z0F2A                    ;0188: BD 0F 2A       '..*'
        LDX     STRPTR                   ;018B: DE 27          '.''
        STX     XSAVE                    ;018D: DF 20          '. '
        ;;
        ;; Is the Command RT?
        ;; 
        BRA     CHKRT                    ;018F: 20 03          ' .'
; ------------------------------------------------------------------------------
RT68MX  FCC     "RT"                     ;0191: 52 54          'RT'
        FCB     $00                      ;0193: 00             '.'
; ------------------------------------------------------------------------------
CHKRT
Z0194   LDX     #RT68MX                  ;0194: CE 01 91       '...'
        JSR     Z0F00                    ;0197: BD 0F 00       '...'
        LDX     #SBFPTR                  ;019A: CE 10 81       '...'
        JSR     Z0F76                    ;019D: BD 0F 76       '..v'
        ;;
        ;;
        ;; 
;       BCS     Z01A5                    ;01A0: 25 03          '%.'
        ;;
        ;;  Yep, RT, go to Return to RT68MX
        ;; 
        BCS     RTNRTMX                  ;01A0: 25 03          '%.'
        ;;
        ;; Nope, is it 
        JMP     Z01A8                    ;01A2: 7E 01 A8       '~..'
; ------------------------------------------------------------------------------
; Return to RT68MX
;*
;* STOP
;*
RTNRTMX
Z01A5   JMP     CONSLE                   ;01A5: 7E E1 6A       '~.j'
; ------------------------------------------------------------------------------
Z01A8   LDX     #M0036                   ;01A8: CE 00 36       '..6'
        LDAA    #$10                     ;01AB: 86 10          '..'
        LDAB    #$81                     ;01AD: C6 81          '..'
        STAB    STRPTR+1                 ;01AF: D7 28          '.('
        STAA    STRPTR                   ;01B1: 97 27          '.''
        JSR     Z0F09                    ;01B3: BD 0F 09       '...'
        JSR     Z0F2A                    ;01B6: BD 0F 2A       '..*'
        LDX     STRPTR                   ;01B9: DE 27          '.''
        STX     XSAVE                    ;01BB: DF 20          '. '
        BRA     Z01C2                    ;01BD: 20 03          ' .'
; ------------------------------------------------------------------------------
MEM     FCC     "ME"                     ;01BF: 4D 45          'ME'
        FCB     $00                      ;01C1: 00             '.'
; ------------------------------------------------------------------------------
CHKME
Z01C2   LDX     #MEM                     ;01C2: CE 01 BF       '...'
        JSR     Z0F00                    ;01C5: BD 0F 00       '...'
        LDX     #SBFPTR                   ;01C8: CE 10 81       '...'
        JSR     Z0F76                    ;01CB: BD 0F 76       '..v'
        BCC     Z01D3                    ;01CE: 24 03          '$.'
        JMP     Z0987                    ;01D0: 7E 09 87       '~..'
; ------------------------------------------------------------------------------

Z01D3   LDX     #M0036                   ;01D3: CE 00 36       '..6'
        LDAA    #$10                     ;01D6: 86 10          '..'
        LDAB    #$81                     ;01D8: C6 81          '..'
        STAB    STRPTR+1                    ;01DA: D7 28          '.('
        STAA    STRPTR                    ;01DC: 97 27          '.''
        JSR     Z0F09                    ;01DE: BD 0F 09       '...'
        JSR     Z0F2A                    ;01E1: BD 0F 2A       '..*'
        LDX     STRPTR                    ;01E4: DE 27          '.''
        STX     XSAVE                    ;01E6: DF 20          '. '
        BRA     Z01ED                    ;01E8: 20 03          ' .'
; ------------------------------------------------------------------------------
LIST    FCC     "LI"                     ;01EA: 4C 49          'LI'
        FCB     $00                      ;01EC: 00             '.'
; ------------------------------------------------------------------------------
CHKLI
Z01ED   LDX     #LIST                    ;01ED: CE 01 EA       '...'
        JSR     Z0F00                    ;01F0: BD 0F 00       '...'
        LDX     #SBFPTR                   ;01F3: CE 10 81       '...'
        JSR     Z0F76                    ;01F6: BD 0F 76       '..v'
        BCC     Z01FE                    ;01F9: 24 03          '$.'
        JMP     Z04B6                    ;01FB: 7E 04 B6       '~..'
; ------------------------------------------------------------------------------

Z01FE   LDX     #M0036                   ;01FE: CE 00 36       '..6'
        LDAA    #$10                     ;0201: 86 10          '..'
        LDAB    #$81                     ;0203: C6 81          '..'
        STAB    STRPTR+1                    ;0205: D7 28          '.('
        STAA    STRPTR                    ;0207: 97 27          '.''
        JSR     Z0F09                    ;0209: BD 0F 09       '...'
        JSR     Z0F2A                    ;020C: BD 0F 2A       '..*'
        LDX     STRPTR                    ;020F: DE 27          '.''
        STX     XSAVE                    ;0211: DF 20          '. '
        BRA     Z0218                    ;0213: 20 03          ' .'
; ------------------------------------------------------------------------------
FIND    FCC     "F/"                     ;0215: 46 2F          'F/'
        FCB     $00                      ;0217: 00             '.'
; ------------------------------------------------------------------------------
CHKFI
Z0218   LDX     #FIND                    ;0218: CE 02 15       '...'
        JSR     Z0F00                    ;021B: BD 0F 00       '...'
        LDX     #SBFPTR                   ;021E: CE 10 81       '...'
        JSR     Z0F76                    ;0221: BD 0F 76       '..v'
        BCC     Z0229                    ;0224: 24 03          '$.'
        JMP     Z0890                    ;0226: 7E 08 90       '~..'
; ------------------------------------------------------------------------------

Z0229   LDX     #M0036                   ;0229: CE 00 36       '..6'
        LDAA    #$10                     ;022C: 86 10          '..'
        LDAB    #$81                     ;022E: C6 81          '..'
        STAB    STRPTR+1                    ;0230: D7 28          '.('
        STAA    STRPTR                    ;0232: 97 27          '.''
        JSR     Z0F09                    ;0234: BD 0F 09       '...'
        JSR     Z0F2A                    ;0237: BD 0F 2A       '..*'
        LDX     STRPTR                    ;023A: DE 27          '.''
        STX     XSAVE                    ;023C: DF 20          '. '
        BRA     Z0243                    ;023E: 20 03          ' .'
; ------------------------------------------------------------------------------
LOAD    FCC     "LO"                     ;0240: 4C 4F          'LO'
        FCB     $00                      ;0242: 00             '.'
; ------------------------------------------------------------------------------
CHKLO
Z0243   LDX     #LOAD                    ;0243: CE 02 40       '..@'
        JSR     Z0F00                    ;0246: BD 0F 00       '...'
        LDX     #SBFPTR                   ;0249: CE 10 81       '...'
        JSR     Z0F76                    ;024C: BD 0F 76       '..v'
        BCC     Z0254                    ;024F: 24 03          '$.'
        JMP     Z06CA                    ;0251: 7E 06 CA       '~..'
; ------------------------------------------------------------------------------

Z0254   LDX     #M0036                   ;0254: CE 00 36       '..6'
        LDAA    #$10                     ;0257: 86 10          '..'
        LDAB    #$81                     ;0259: C6 81          '..'
        STAB    STRPTR+1                 ;025B: D7 28          '.('
        STAA    STRPTR                   ;025D: 97 27          '.''
        JSR     Z0F09                    ;025F: BD 0F 09       '...'
        JSR     Z0F2A                    ;0262: BD 0F 2A       '..*'
        LDX     STRPTR                   ;0265: DE 27          '.''
        STX     XSAVE                    ;0267: DF 20          '. '
        BRA     Z026E                    ;0269: 20 03          ' .'
; ------------------------------------------------------------------------------
SEARCH  FCC     "S,"                     ;026B: 53 2C          'S,'
        FCB     $00                      ;026D: 00             '.'
; ------------------------------------------------------------------------------
CHKS1
Z026E   LDX     #SEARCH                  ;026E: CE 02 6B       '..k'
        JSR     Z0F00                    ;0271: BD 0F 00       '...'
        LDX     #SBFPTR                  ;0274: CE 10 81       '...'
        JSR     Z0F76                    ;0277: BD 0F 76       '..v'
        BCC     Z027F                    ;027A: 24 03          '$.'
        JMP     Z04E8                    ;027C: 7E 04 E8       '~..'
; ------------------------------------------------------------------------------

Z027F   LDX     #M0036                   ;027F: CE 00 36       '..6'
        LDAA    #$10                     ;0282: 86 10          '..'
        LDAB    #$81                     ;0284: C6 81          '..'
        STAB    STRPTR+1                 ;0286: D7 28          '.('
        STAA    STRPTR                   ;0288: 97 27          '.''
        JSR     Z0F09                    ;028A: BD 0F 09       '...'
        JSR     Z0F2A                    ;028D: BD 0F 2A       '..*'
        LDX     STRPTR                   ;0290: DE 27          '.''
        STX     XSAVE                    ;0292: DF 20          '. '
        BRA     Z0299                    ;0294: 20 03          ' .'
; ------------------------------------------------------------------------------
SAVE    FCC     "SA"                     ;0296: 53 41          'SA'
        FCB     $00                      ;0298: 00             '.'
; ------------------------------------------------------------------------------
CHKSA
Z0299   LDX     #SAVE                    ;0299: CE 02 96       '...'
        JSR     Z0F00                    ;029C: BD 0F 00       '...'
        LDX     #SBFPTR                  ;029F: CE 10 81       '...'
        JSR     Z0F76                    ;02A2: BD 0F 76       '..v'
        BCC     Z02AA                    ;02A5: 24 03          '$.'
        JMP     Z04D6                    ;02A7: 7E 04 D6       '~..'
; ------------------------------------------------------------------------------

Z02AA   LDX     #M0036                   ;02AA: CE 00 36       '..6'
        LDAA    #$10                     ;02AD: 86 10          '..'
        LDAB    #$81                     ;02AF: C6 81          '..'
        STAB    STRPTR+1                 ;02B1: D7 28          '.('
        STAA    STRPTR                   ;02B3: 97 27          '.''
        JSR     Z0F09                    ;02B5: BD 0F 09       '...'
        JSR     Z0F2A                    ;02B8: BD 0F 2A       '..*'
        LDX     STRPTR                   ;02BB: DE 27          '.''
        STX     XSAVE                    ;02BD: DF 20          '. '
        BRA     Z02C4                    ;02BF: 20 03          ' .'
; -[ EXIT/END ]-----------------------------------------------------------------
EXIT    FCC     "EN"                     ;02C1: 45 4E          'EN'
        FCB     $00                      ;02C3: 00             '.'
; ------------------------------------------------------------------------------
CHKEN
Z02C4   LDX     #EXIT                    ;02C4: CE 02 C1       '...'
        JSR     Z0F00                    ;02C7: BD 0F 00       '...'
        LDX     #SBFPTR                  ;02CA: CE 10 81       '...'
        JSR     Z0F76                    ;02CD: BD 0F 76       '..v'
        BCC     Z02D5                    ;02D0: 24 03          '$.'
        JMP     Z04F4                    ;02D2: 7E 04 F4       '~..'
; ------------------------------------------------------------------------------

Z02D5   LDX     #M0036                   ;02D5: CE 00 36       '..6'
        LDAA    #$10                     ;02D8: 86 10          '..'
        LDAB    #$81                     ;02DA: C6 81          '..'
        STAB    STRPTR+1                 ;02DC: D7 28          '.('
        STAA    STRPTR                   ;02DE: 97 27          '.''
        JSR     Z0F09                    ;02E0: BD 0F 09       '...'
        JSR     Z0F2A                    ;02E3: BD 0F 2A       '..*'
        LDX     STRPTR                   ;02E6: DE 27          '.''
        STX     XSAVE                    ;02E8: DF 20          '. '
        BRA     Z02EF                    ;02EA: 20 03          ' .'
; ------------------------------------------------------------------------------
NEW     FCC     "NE"                     ;02EC: 4E 45          'NE'
        FCB     $00                      ;02EE: 00             '.'
; ------------------------------------------------------------------------------
CHKNE
Z02EF   LDX     #NEW                     ;02EF: CE 02 EC       '...'
        JSR     Z0F00                    ;02F2: BD 0F 00       '...'
        LDX     #SBFPTR                  ;02F5: CE 10 81       '...'
        JSR     Z0F76                    ;02F8: BD 0F 76       '..v'
        BCC     Z0300                    ;02FB: 24 03          '$.'
        JMP     START                    ;02FD: 7E 01 00       '~..'
; ------------------------------------------------------------------------------

Z0300   LDX     #M0036                   ;0300: CE 00 36       '..6'
        LDAA    #$10                     ;0303: 86 10          '..'
        LDAB    #$81                     ;0305: C6 81          '..'
        STAB    STRPTR+1                 ;0307: D7 28          '.('
        STAA    STRPTR                   ;0309: 97 27          '.''
        JSR     Z0F09                    ;030B: BD 0F 09       '...'
        JSR     Z0F2A                    ;030E: BD 0F 2A       '..*'
        LDX     STRPTR                   ;0311: DE 27          '.''
        STX     XSAVE                    ;0313: DF 20          '. '
;       BRA     Z031A                    ;0315: 20 03          ' .'
        BRA     LDFROM                   ;0315: 20 03          ' .'
; ------------------------------------------------------------------------------
LFROM   FCC     "L,"                     ;0317: 4C 2C          'L,'
        FCB     $00                      ;0319: 00             '.'
; ------------------------------------------------------------------------------
LDFROM
CHKL1
Z031A   LDX     #LFROM                   ;031A: CE 03 17       '...'
        JSR     Z0F00                    ;031D: BD 0F 00       '...'
        LDX     #SBFPTR                   ;0320: CE 10 81       '...'
        JSR     Z0F76                    ;0323: BD 0F 76       '..v'
        ;;
        ;; Check line length?
        ;; 
;       BCC     Z032B                    ;0326: 24 03          '$.'
        BCC     LINERR                   ;0326: 24 03          '$.'
        JMP     Z068B                    ;0328: 7E 06 8B       '~..'
; ------------------------------------------------------------------------------
;*
LINERR
;032B   LDX     #M1000                   ;032B: CE 10 00       '...'
Z032B   LDX     #BUF                     ;032B: CE 10 00       '...'
        LDAA    #$10                     ;032E: 86 10          '..'
        LDAB    #$81                     ;0330: C6 81          '..'
        STAB    STRPTR+1                 ;0332: D7 28          '.('
        STAA    STRPTR                   ;0334: 97 27          '.''
        JSR     Z0F00                    ;0336: BD 0F 00       '...'
        LDX     #SBFPTR                  ;0339: CE 10 81       '...'
        JSR     Z0FA7                    ;033C: BD 0F A7       '...'
        ;; 
        STAB    M0057                    ;033F: D7 57          '.W'
        STAA    M0056                    ;0341: 97 56          '.V'
        ;; 
        LDAB    M0057                    ;0343: D6 57          '.W'
        LDAA    M0056                    ;0345: 96 56          '.V'
        ;; 
        SUBB    #$00                     ;0347: C0 00          '..'
        SBCA    #$00                     ;0349: 82 00          '..'
        ;;
        ;; BLT or BEQ QUE
        ;; BNE or anything else TOOLNG
        ;; 
;       BLT     Z0355                    ;034B: 2D 08          '-.'
        BLT     QUE                      ;034B: 2D 08          '-.'
        BNE     Z0352                    ;034D: 26 03          '&.'
        TSTB                             ;034F: 5D             ']'
;       BEQ     Z0355                    ;0350: 27 03          ''.'
        BEQ     QUE                      ;0350: 27 03          ''.'
        ;;
        ;;  Line too long
        ;; 
Z0352   JMP     TOOLNG                   ;0352: 7E 03 6E       '~.n'
;0352   JMP     Z036E                    ;0352: 7E 03 6E       '~.n'
; ------------------------------------------------------------------------------
;*
;* Say What?
;*
QUE
;0355   LDX     #M1000                   ;0355: CE 10 00       '...'
Z0355   LDX     #BUF                     ;0355: CE 10 00       '...'
        JSR     Z0D7F                    ;0358: BD 0D 7F       '...'
        BRA     Z0362                    ;035B: 20 05          ' .'
; ------------------------------------------------------------------------------   
WHAT    FCC     "WHAT"                   ;035D: 57 48 41 54    'WHAT'
        FCB     $00                      ;0361: 00             '.'
; ------------------------------------------------------------------------------
Z0362   LDX     #WHAT                    ;0362: CE 03 5D       '..]'
        JSR     XPRNT                    ;0365: BD 0D EF       '...'
        JSR     Z0DD1                    ;0368: BD 0D D1       '...'
;       JMP     Z0147                    ;036B: 7E 01 47       '~.G'
        JMP     MENU                     ;036B: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* Check the line length
;*
;* 145 GOSUB 7000: IF X<64 THEN 150: PRINT "LINE TOO LONG"
;*
TOOLNG  ;;
        ;; Get the len(buf$)
        ;; 
Z036E   JSR     Z0C40                    ;036E: BD 0C 40       '..@'
        ;; 
;       LDAB    M0059                    ;0371: D6 59          '.Y'
;       LDAA    M0058                    ;0373: 96 58          '.X'
        LDAB    lo(X)                    ;0371: D6 59          '.Y'
        LDAA    hi(X)                    ;0373: 96 58          '.X'
        ;;
        ;;  $40 = 64, line length
        ;;
        SUBB    #$40                     ;0375: C0 40          '.@'
        SBCA    #$00                     ;0377: 82 00          '..'
        ;;
        ;;  IF X<64 THEN 150
        ;; 
        BLT     Z0380                    ;0379: 2D 05          '-.'
        BNE     Z0383                    ;037B: 26 06          '&.'
        TSTB                             ;037D: 5D             ']'
        BNE     Z0383                    ;037E: 26 03          '&.'
Z0380   JMP     Z03A5                    ;0380: 7E 03 A5       '~..'
; ------------------------------------------------------------------------------
;* 
;* Called from:
;*   Z036E
;* 
;0383   LDX     #M1000                   ;0383: CE 10 00       '...'
Z0383   LDX     #BUF                     ;0383: CE 10 00       '...'
        JSR     Z0D7F                    ;0386: BD 0D 7F       '...'
        BRA     Z0399                    ;0389: 20 0E          ' .'
; ------------------------------------------------------------------------------
ST2LNG  FCC     "LINE TOO LONG"          ;038B: 4C 49 4E 45 20 54 4F 4F 20 4C 4F 4E 47 'LINE TOO LONG'
        FCB     $00                      ;0398: 00             '.'
; ------------------------------------------------------------------------------
Z0399   LDX     #ST2LNG                  ;0399: CE 03 8B       '...'
        JSR     XPRNT                    ;039C: BD 0D EF       '...'
        JSR     Z0DD1                    ;039F: BD 0D D1       '...'
        ;;
        ;; 146 GOTO 100
        ;; 
;       JMP     Z0147                    ;03A2: 7E 01 47       '~.G'
        JMP     MENU                     ;03A2: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* 150 GOSUB 4000: IF K>V THEN 160
;*
LN0150
Z03A5   JSR     Z0AC8                    ;03A5: BD 0A C8       '...'
;       LDAB    M0033                    ;03A8: D6 33          '.3'
;       LDAA    M0032                    ;03AA: 96 32          '.2'
        LDAB    lo(K)                    ;03A8: D6 33          '.3'
        LDAA    hi(K)                    ;03AA: 96 32          '.2'
;       SUBB    M0031                    ;03AC: D0 31          '.1'
;       SBCA    M0030                    ;03AE: 92 30          '.0'
        SUBB    lo(V)                    ;03AC: D0 31          '.1'
        SBCA    hi(V)                    ;03AE: 92 30          '.0'
        BLT     Z03BA                    ;03B0: 2D 08          '-.'
        BNE     Z03B7                    ;03B2: 26 03          '&.'
        TSTB                             ;03B4: 5D             ']'
        BEQ     Z03BA                    ;03B5: 27 03          ''.'
        ;;
        ;;  THEN 160
        ;; 
Z03B7   JMP     Z03E6                    ;03B7: 7E 03 E6       '~..'
; ------------------------------------------------------------------------------

;03BA   LDAB    M0033                    ;03BA: D6 33          '.3'
;       LDAA    M0032                    ;03BC: 96 32          '.2'
Z03BA   LDAB    lo(K)                    ;03BA: D6 33          '.3'
        LDAA    hi(K)                    ;03BC: 96 32          '.2'
        ASLB                             ;03BE: 58             'X'
        ROLA                             ;03BF: 49             'I'
        ;;
        ;;  N(50)
        ;; 
        ADDB    #$00                     ;03C0: CB 00          '..'
        ADCA    #$13                     ;03C2: 89 13          '..'
        PSHB                             ;03C4: 37             '7'
        PSHA                             ;03C5: 36             '6'
        CLRA                             ;03C6: 4F             'O'
        CLRB                             ;03C7: 5F             '_'
        TSX                              ;03C8: 30             '0'
        LDX     $00,X                    ;03C9: EE 00          '..'
        INS                              ;03CB: 31             '1'
        INS                              ;03CC: 31             '1'
        STAA    $00,X                    ;03CD: A7 00          '..'
        STAB    $01,X                    ;03CF: E7 01          '..'
;       LDAB    M0059                    ;03D1: D6 59          '.Y'
;       LDAA    M0058                    ;03D3: 96 58          '.X'
        LDAB    lo(X)                    ;03D1: D6 59          '.Y'
        LDAA    hi(X)                    ;03D3: 96 58          '.X'
        SUBB    #$04                     ;03D5: C0 04          '..'
        SBCA    #$00                     ;03D7: 82 00          '..'
        BLT     Z03E3                    ;03D9: 2D 08          '-.'
        BNE     Z03E0                    ;03DB: 26 03          '&.'
        TSTB                             ;03DD: 5D             ']'
        BEQ     Z03E3                    ;03DE: 27 03          ''.'
Z03E0   JMP     Z03E6                    ;03E0: 7E 03 E6       '~..'
; ------------------------------------------------------------------------------
;03E3   JMP     Z0147                    ;03E3: 7E 01 47       '~.G'
Z03E3   JMP     MENU                     ;03E3: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* 160 GOSUB 5000 : IF K<V+1 THEN 175
;*
LN0160
Z03E6   JSR     Z0B18                    ;03E6: BD 0B 18       '...'
;       LDAB    M0033                    ;03E9: D6 33          '.3'
;       LDAA    M0032                    ;03EB: 96 32          '.2'
        LDAB    lo(K)                    ;03E9: D6 33          '.3'
        LDAA    hi(K)                    ;03EB: 96 32          '.2'
        PSHB                             ;03ED: 37             '7'
        PSHA                             ;03EE: 36             '6'
;       LDAB    M0031                    ;03EF: D6 31          '.1'
;       LDAA    M0030                    ;03F1: 96 30          '.0'
        LDAB    lo(V)                    ;03EF: D6 31          '.1'
        LDAA    hi(V)                    ;03F1: 96 30          '.0'
        ADDB    #$01                     ;03F3: CB 01          '..'
        ADCA    #$00                     ;03F5: 89 00          '..'
        NEGA                             ;03F7: 40             '@'
        NEGB                             ;03F8: 50             'P'
        SBCA    #$00                     ;03F9: 82 00          '..'
        TSX                              ;03FB: 30             '0'
        ADDB    $01,X                    ;03FC: EB 01          '..'
        ADCA    $00,X                    ;03FE: A9 00          '..'
        INS                              ;0400: 31             '1'
        INS                              ;0401: 31             '1'
        ;;
        ;;
        ;; 
;       BGE     Z0407                    ;0402: 2C 03          ',.'
        BGE     MEMFLL                   ;0402: 2C 03          ',.'
        ;;
        ;; THEN 175 - Going straight to hell, code broken and BOOM!
        ;; 
        JMP     Z0427                    ;0404: 7E 04 27       '~.''
; ------------------------------------------------------------------------------
MEMFLL
;0407   LDX     #M1000                   ;0407: CE 10 00       '...'
Z0407   LDX     #BUF                     ;0407: CE 10 00       '...'
        JSR     Z0D7F                    ;040A: BD 0D 7F       '...'
        BRA     Z041B                    ;040D: 20 0C          ' .'
; ------------------------------------------------------------------------------
MFULL   FCC     "MEMORY FULL"            ;040F: 4D 45 4D 4F 52 59 20 46 55 4C 4C 'MEMORY FULL'
        FCB     $00                      ;041A: 00             '.'
; ------------------------------------------------------------------------------
Z041B   LDX     #MFULL                   ;041B: CE 04 0F       '...'
        JSR     XPRNT                    ;041E: BD 0D EF       '...'
        JSR     Z0DD1                    ;0421: BD 0D D1       '...'
;       JMP     Z0147                    ;0424: 7E 01 47       '~.G'
        JMP     MENU                     ;0424: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* Road to hell (BOOM!)
;*
;* 175 N(K)=Z
;* 180 B$(K)=LEFT$(BUF$,32) : B$(K+V)=MID$(BUF$,33,32)
;* 185 GOTO 100
;*
LN0175
;0427   LDAB    M0033                    ;0427: D6 33          '.3'
;       LDAA    M0032                    ;0429: 96 32          '.2'
Z0427   LDAB    lo(K)                    ;0427: D6 33          '.3'
        LDAA    hi(K)                    ;0429: 96 32          '.2'
        ASLB                             ;042B: 58             'X'
        ROLA                             ;042C: 49             'I'
        ADDB    #$00                     ;042D: CB 00          '..'
        ADCA    #$13                     ;042F: 89 13          '..'
        PSHB                             ;0431: 37             '7'
        PSHA                             ;0432: 36             '6'
        LDAB    M0057                    ;0433: D6 57          '.W'
        LDAA    M0056                    ;0435: 96 56          '.V'
        TSX                              ;0437: 30             '0'
        LDX     $00,X                    ;0438: EE 00          '..'
        INS                              ;043A: 31             '1'
        INS                              ;043B: 31             '1'
        STAA    $00,X                    ;043C: A7 00          '..'
        STAB    $01,X                    ;043E: E7 01          '..'
;       LDAB    M0033                    ;0440: D6 33          '.3'
;       LDAA    M0032                    ;0442: 96 32          '.2'
        LDAB    lo(K)                    ;0440: D6 33          '.3'
        LDAA    hi(K)                    ;0442: 96 32          '.2'
        LDAA    #$20                     ;0444: 86 20          '. '
        JSR     Z0E53                    ;0446: BD 0E 53       '..S'
        ADDB    #$46                     ;0449: CB 46          '.F'
        ADCA    #$13                     ;044B: 89 13          '..'
        PSHB                             ;044D: 37             '7'
        PSHA                             ;044E: 36             '6'
        LDAA    #$10                     ;044F: 86 10          '..'
        LDAB    #$81                     ;0451: C6 81          '..'
        STAB    STRPTR+1                 ;0453: D7 28          '.('
        STAA    STRPTR                   ;0455: 97 27          '.''
        DES                              ;0457: 34             '4'
        DES                              ;0458: 34             '4'
        JSR     Z0E68                    ;0459: BD 0E 68       '..h'
;       LDX     #M1000                   ;045C: CE 10 00       '...'
        LDX     #BUF                     ;045C: CE 10 00       '...'
        JSR     Z0F00                    ;045F: BD 0F 00       '...'
        CLRA                             ;0462: 4F             'O'
        ;;*
        ;;* Probably
        ;;*
        ;;* 180 B$(K)=LEFT$(BUF$,32) : B$(K+V)=MID$(BUF$,33,32)
        ;;* 180 B$(K)=LEFT$(BUF$,32) : ...
        ;;*  
        LDAB    #$20                     ;0463: C6 20          '. 'njc

        JSR     Z0EE5                    ;0465: BD 0E E5       '...'
        LDX     #SBFPTR                  ;0468: CE 10 81       '...'
        STX     STRPTR                   ;046B: DF 27          '.''
        TSX                              ;046D: 30             '0'
        LDX     $00,X                    ;046E: EE 00          '..'
        INS                              ;0470: 31             '1'
        INS                              ;0471: 31             '1'
        JSR     Z0EA0                    ;0472: BD 0E A0       '...'
;       LDAB    M0033                    ;0475: D6 33          '.3'
;       LDAA    M0032                    ;0477: 96 32          '.2'
        LDAB    lo(K)                    ;0475: D6 33          '.3'
        LDAA    hi(K)                    ;0477: 96 32          '.2'
;       ADDB    M0031                    ;0479: DB 31          '.1'
;       ADCA    M0030                    ;047B: 99 30          '.0'
        ADDB    lo(V)                    ;0479: DB 31          '.1'
        ADCA    hi(V)                    ;047B: 99 30          '.0'
        LDAA    #$20                     ;047D: 86 20          '. '
        JSR     Z0E53                    ;047F: BD 0E 53       '..S'
        ADDB    #$46                     ;0482: CB 46          '.F'
        ADCA    #$13                     ;0484: 89 13          '..'
        PSHB                             ;0486: 37             '7'
        PSHA                             ;0487: 36             '6'
        LDAA    #$10                     ;0488: 86 10          '..'
        LDAB    #$81                     ;048A: C6 81          '..'
        STAB    STRPTR+1                 ;048C: D7 28          '.('
        STAA    STRPTR                   ;048E: 97 27          '.''
        DES                              ;0490: 34             '4'
        DES                              ;0491: 34             '4'
        TST     $0E,X                    ;0492: 6D 0E          'm.'  ??? 60
        ;;
        ;; This is orig, but looks broken
        ;; 
;       EORA    MCF10                    ;0494: B8 CF 10       '...' ??? 68 CE 10
        ;;
        ;;  This is a guess
        ;; 
;       LDX     #M1000                   ;0494: CE 10 00       '...' ??? 68 CE 10
        LDX     #BUF                     ;0494: CE 10 00       '...' ??? 68 CE 10
        ;;
        ;; Boom?  BOOM! This is messed up
        ;; 
; ------------------------------------------------------------------------------
;* 180 B$(K)=LEFT$(BUF$,32) : B$(K+V)=MID$(BUF$,33,32) 33==$21 32==$20
; ------------------------------------------------------------------------------
; WTFrell
;TF002  FCB     $00                      ;0497: 00             '.'
WTF002  FCB     $01                      ;0497: 00             '.'
        JSR     Z0F00                    ;0498: BD 0F 00       '...'
; ------------------------------------------------------------------------------
; WTFrell
WTF003  FCB     $4E                      ;049B: 4E             'N'
        ;;
        ;; Part of
        ;; 180 B$(K)=LEFT$(BUF$,32) : B$(K+V)=MID$(BUF$,33,32)
        ;; 
Z049C   LDAB    #$21                     ;049C: C6 21          '.!'
        PSHB                             ;049E: 37             '7'
        CLRA                             ;049F: 4F             'O'
        LDAB    #$20                     ;04A0: C6 20          '. '
        PULA                             ;04A2: 32             '2'
        JSR     Z0ECA                    ;04A3: BD 0E CA       '...'
        LDX     #SBFPTR                  ;04A6: CE 10 81       '...'
        STX     STRPTR                   ;04A9: DF 27          '.''
        TSX                              ;04AB: 30             '0'
        LDX     ,X                       ;04AC: EE 00          '..'
        INS                              ;04AE: 31             '1'
        INS                              ;04AF: 31             '1'
        JSR     Z0EA0                    ;04B0: BD 0E A0       '...'
;       JMP     Z0147                    ;04B3: 7E 01 47       '~.G'
        JMP     MENU                     ;04B3: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------

Z04B6   CLRA                             ;04B6: 4F             'O'
        LDAB    #$01                     ;04B7: C6 01          '..'
        STAB    M005B                    ;04B9: D7 5B          '.['
        STAA    M005A                    ;04BB: 97 5A          '.Z'
Z04BD   JSR     Z09B7                    ;04BD: BD 09 B7       '...'
        LDAB    M005D                    ;04C0: D6 5D          '.]'
        LDAA    M005C                    ;04C2: 96 5C          '.\'
        ;;
        ;; $2710 = 10000
        ;; 
        SUBB    #$10                     ;04C4: C0 10          '..'
        SBCA    #$27                     ;04C6: 82 27          '.''
        BNE     Z04D0                    ;04C8: 26 06          '&.'
        TSTB                             ;04CA: 5D             ']'
        BNE     Z04D0                    ;04CB: 26 03          '&.'
;       JMP     Z0147                    ;04CD: 7E 01 47       '~.G'
        ;;
        ;;  IF T=1000 THEN 100 (line 220 or 530)
        JMP     MENU                     ;04CD: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------

Z04D0   JSR     Z0A86                    ;04D0: BD 0A 86       '...'
        JMP     Z04BD                    ;04D3: 7E 04 BD       '~..'
; ------------------------------------------------------------------------------

Z04D6   CLRA                             ;04D6: 4F             'O'
        LDAB    #$01                     ;04D7: C6 01          '..'
        STAB    M005B                    ;04D9: D7 5B          '.['
        STAA    M005A                    ;04DB: 97 5A          '.Z'
        ;;
        ;; $270F = 9999
        ;; 
        LDAA    #$27                     ;04DD: 86 27          '.''
        LDAB    #$0F                     ;04DF: C6 0F          '..'
        STAB    M005F                    ;04E1: D7 5F          '._'
        STAA    M005E                    ;04E3: 97 5E          '.^'
        JMP     Z04EB                    ;04E5: 7E 04 EB       '~..'
; ------------------------------------------------------------------------------

Z04E8   JSR     Z0B5B                    ;04E8: BD 0B 5B       '..['
Z04EB   CLRA                             ;04EB: 4F             'O'
        CLRB                             ;04EC: 5F             '_'
        STAB    M0061                    ;04ED: D7 61          '.a'
        STAA    M0030                    ;04EF: 97 30          '.0'
        JMP     Z050A                    ;04F1: 7E 05 0A       '~..'
; ------------------------------------------------------------------------------

Z04F4   CLRA                             ;04F4: 4F             'O'
        LDAB    #$01                     ;04F5: C6 01          '..'
        TPA                              ;04F7: 07             '.'
; ------------------------------------------------------------------------------
; WTFrell
; ------------------------------------------------------------------------------
; WTFrell
WTF008  FCB     $61                      ;04F8: 61             'a'
        STAA    M0060                    ;04F9: 97 60          '.`'
        CLRA                             ;04FB: 4F             'O'
        LDAB    #$01                     ;04FC: C6 01          '..'
        STAB    M005B                    ;04FE: D7 5B          '.['
        STAA    M005A                    ;0500: 97 5A          '.Z'
        ;;
        ;; $270F = 9999
        ;; 
        LDAA    #$27                     ;0502: 86 27          '.''
        LDAB    #$0F                     ;0504: C6 0F          '..'
        STAB    M005F                    ;0506: D7 5F          '._'
        STAA    M005E                    ;0508: 97 5E          '.^'
Z050A   JSR     Z0670                    ;050A: BD 06 70       '..p'
Z050D   JSR     Z09B7                    ;050D: BD 09 B7       '...'
        LDAB    M005B                    ;0510: D6 5B          '.['
        LDAA    M005A                    ;0512: 96 5A          '.Z'
        PSHB                             ;0514: 37             '7'
        PSHA                             ;0515: 36             '6'
        LDAB    M005F                    ;0516: D6 5F          '._'
        LDAA    M005E                    ;0518: 96 5E          '.^'
        ADDB    #$01                     ;051A: CB 01          '..'
        ADCA    #$00                     ;051C: 89 00          '..'
        NEGA                             ;051E: 40             '@'
        NEGB                             ;051F: 50             'P'
        SBCA    #$00                     ;0520: 82 00          '..'
        TSX                              ;0522: 30             '0'
        ADDB    $01,X                    ;0523: EB 01          '..'
        ADCA    ,X                       ;0525: A9 00          '..'
        INS                              ;0527: 31             '1'
        INS                              ;0528: 31             '1'
        BLT     Z0533                    ;0529: 2D 08          '-.'
        BNE     Z0530                    ;052B: 26 03          '&.'
        TSTB                             ;052D: 5D             ']'
        BEQ     Z0533                    ;052E: 27 03          ''.'
; ------------------------------------------------------------------------------
Z0530   JMP     Z0540                    ;0530: 7E 05 40       '~.@'

Z0533   LDAB    M005D                    ;0533: D6 5D          '.]'
        LDAA    M005C                    ;0535: 96 5C          '.\'
        ;;
        ;; $2710 = 10000
        ;; 
        SUBB    #$10                     ;0537: C0 10          '..'
        SBCA    #$27                     ;0539: 82 27          '.''
        BGE     Z0540                    ;053B: 2C 03          ',.'
        JMP     Z0597                    ;053D: 7E 05 97       '~..'
; ------------------------------------------------------------------------------
;* First part of 440 IF A1=0 THEN 450 : BUF$=BUF$+CHR($1A) : X=X+1
Z0540   LDAB    M0061                    ;0540: D6 61          '.a'
        LDAA    M0060                    ;0542: 96 60          '.`'
        SUBB    #$00                     ;0544: C0 00          '..'
        SBCA    #$00                     ;0546: 82 00          '..'
        BNE     Z0550                    ;0548: 26 06          '&.'
        TSTB                             ;054A: 5D             ']'
        BNE     Z0550                    ;054B: 26 03          '&.'
;       JMP     Z057B                    ;054D: 7E 05 7B       '~.{'
        JMP     LN0450                   ;054D: 7E 05 7B       '~.{'
; ------------------------------------------------------------------------------
;* Second part of 440 IF A1=0 THEN 450 : BUF$=BUF$+CHR($1A) : X=X+1
;0550   LDX     #M1000                   ;0550: CE 10 00       '...'
Z0550   LDX     #BUF                     ;0550: CE 10 00       '...'
        LDAA    #$10                     ;0553: 86 10          '..'
        LDAB    #$81                     ;0555: C6 81          '..'
        STAB    STRPTR+1                 ;0557: D7 28          '.('
        STAA    STRPTR                   ;0559: 97 27          '.''
        JSR     Z0F00                    ;055B: BD 0F 00       '...'
        CLRA                             ;055E: 4F             'O'
        LDAB    #CTRLZ                   ;055F: C6 1A          '..'
        JSR     Z0F25                    ;0561: BD 0F 25       '..%'
        LDX     #SBFPTR                  ;0564: CE 10 81       '...'
        STX     STRPTR                   ;0567: DF 27          '.''
;       LDX     #M1000                   ;0569: CE 10 00       '...'
        LDX     #BUF                     ;0569: CE 10 00       '...'
        JSR     Z0E99                    ;056C: BD 0E 99       '...'
;       LDAB    M0059                    ;056F: D6 59          '.Y'
;       LDAA    M0058                    ;0571: 96 58          '.X'
        LDAB    lo(X)                    ;056F: D6 59          '.Y'
        LDAA    hi(X)                    ;0571: 96 58          '.X'
        ADDB    #$01                     ;0573: CB 01          '..'
        ADCA    #$00                     ;0575: 89 00          '..'
;       STAB    M0059                    ;0577: D7 59          '.Y'
;       STAA    M0058                    ;0579: 97 58          '.X'
        STAB    lo(X)                    ;0577: D7 59          '.Y'
        STAA    hi(X)                    ;0579: 97 58          '.X'
        ;;
        ;; 450 IF X=0 THEN 100
        ;; 
;057B   LDAB    M0059                    ;057B: D6 59          '.Y'
;       LDAA    M0058                    ;057D: 96 58          '.X'
LN0450
Z057B   LDAB    lo(X)                    ;057B: D6 59          '.Y'
        LDAA    hi(X)                    ;057D: 96 58          '.X'
        SUBB    #$00                     ;057F: C0 00          '..'
        SBCA    #$00                     ;0581: 82 00          '..'
        BNE     Z058B                    ;0583: 26 06          '&.'
        TSTB                             ;0585: 5D             ']'
        BNE     Z058B                    ;0586: 26 03          '&.'
;       JMP     Z0147                    ;0588: 7E 01 47       '~.G'
        JMP     MENU                     ;0588: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* 460 TWRITE BUF$ : GOTO 100
;*
;058B   LDX     #M1000                   ;058B: CE 10 00       '...'
Z058B   LDX     #BUF                     ;058B: CE 10 00       '...'
        ;;
        ;; X->BUFBEG
        ;; X->BUFPTR
        ;;
        JSR     Z0D7F                    ;058E: BD 0D 7F       '...'
;       JSR     Z0DAB                    ;0591: BD 0D AB       '...'
        JSR     TWRITE                   ;0591: BD 0D AB       '...'
;       JMP     Z0147                    ;0594: 7E 01 47       '~.G'
        JMP     MENU                     ;0594: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* 470 S1=LEN(B$(S)+B$(S+V))
;* 480 IF P1+S1+1>128 GOSUB 494
;* 490 BUF$=BUF$+B$(S)+B$(S=V)+CHR$($D)
;* 492 P1=P1+S1+1 : Z=X+1 : IF X>3 GOSUB 494 : GOTO 430
;*
LN0470
Z0597   LDAB    M0065                    ;0597: D6 65          '.e'
        LDAA    M0064                    ;0599: 96 64          '.d'
        LDAA    #$20                     ;059B: 86 20          '. '
        JSR     Z0E53                    ;059D: BD 0E 53       '..S'
        ADDB    #$46                     ;05A0: CB 46          '.F'
        ADCA    #$13                     ;05A2: 89 13          '..'
        JSR     Z0FCE                    ;05A4: BD 0F CE       '...'
        ;;
        ;; B$ = &1081
        ;; 
        LDAA    #$10                     ;05A7: 86 10          '..'
        LDAB    #$81                     ;05A9: C6 81          '..'
        STAB    STRPTR+1                 ;05AB: D7 28          '.('
        STAA    STRPTR                   ;05AD: 97 27          '.''
        JSR     Z0F09                    ;05AF: BD 0F 09       '...'
        LDAB    M0065                    ;05B2: D6 65          '.e'
        LDAA    M0064                    ;05B4: 96 64          '.d'
;       ADDB    M0031                    ;05B6: DB 31          '.1'
;       ADCA    M0030                    ;05B8: 99 30          '.0'
        ADDB    lo(V)                    ;05B6: DB 31          '.1'
        ADCA    hi(V)                    ;05B8: 99 30          '.0'
        LDAA    #$20                     ;05BA: 86 20          '. '
        JSR     Z0E53                    ;05BC: BD 0E 53       '..S'
        ADDB    #$46                     ;05BF: CB 46          '.F'
        ADCA    #$13                     ;05C1: 89 13          '..'
        JSR     Z0FCE                    ;05C3: BD 0F CE       '...'
        JSR     Z0F09                    ;05C6: BD 0F 09       '...'
        LDX     #SBFPTR                  ;05C9: CE 10 81       '...'
        JSR     Z0E7A                    ;05CC: BD 0E 7A       '..z'
        STAB    M0063                    ;05CF: D7 63          '.c'
        STAA    M0062                    ;05D1: 97 62          '.b'
        LDAB    M0067                    ;05D3: D6 67          '.g'
        LDAA    M0066                    ;05D5: 96 66          '.f'
        ADDB    M0063                    ;05D7: DB 63          '.c'
        ADCA    M0062                    ;05D9: 99 62          '.b'
        ADDB    #$01                     ;05DB: CB 01          '..'
        ADCA    #$00                     ;05DD: 89 00          '..'
        SUBB    #$80                     ;05DF: C0 80          '..'
        SBCA    #$00                     ;05E1: 82 00          '..'
        BLT     Z05ED                    ;05E3: 2D 08          '-.'
        BNE     Z05EA                    ;05E5: 26 03          '&.'
        TSTB                             ;05E7: 5D             ']'
        BEQ     Z05ED                    ;05E8: 27 03          ''.'
Z05EA   JSR     Z0667                    ;05EA: BD 06 67       '..g'
;05ED   LDX     #M1000                   ;05ED: CE 10 00       '...'
Z05ED   LDX     #BUF                     ;05ED: CE 10 00       '...'
        LDAA    #$10                     ;05F0: 86 10          '..'
        LDAB    #$81                     ;05F2: C6 81          '..'
        STAB    STRPTR+1                 ;05F4: D7 28          '.('
        STAA    STRPTR                   ;05F6: 97 27          '.''
        JSR     Z0F00                    ;05F8: BD 0F 00       '...'
        LDAB    M0065                    ;05FB: D6 65          '.e'
        LDAA    M0064                    ;05FD: 96 64          '.d'
        LDAA    #$20                     ;05FF: 86 20          '. '
        JSR     Z0E53                    ;0601: BD 0E 53       '..S'
        ADDB    #$46                     ;0604: CB 46          '.F'
        ADCA    #$13                     ;0606: 89 13          '..'
        JSR     Z0FCE                    ;0608: BD 0F CE       '...'
        JSR     Z0F09                    ;060B: BD 0F 09       '...'
        LDAB    M0065                    ;060E: D6 65          '.e'
        LDAA    M0064                    ;0610: 96 64          '.d'
;       ADDB    M0031                    ;0612: DB 31          '.1'
;       ADCA    M0030                    ;0614: 99 30          '.0'
        ADDB    lo(V)                    ;0612: DB 31          '.1'
        ADCA    hi(V)                    ;0614: 99 30          '.0'
        LDAA    #$20                     ;0616: 86 20          '. '
        JSR     Z0E53                    ;0618: BD 0E 53       '..S'
        ADDB    #$46                     ;061B: CB 46          '.F'
        ADCA    #$13                     ;061D: 89 13          '..'
        JSR     Z0FCE                    ;061F: BD 0F CE       '...'
        JSR     Z0F09                    ;0622: BD 0F 09       '...'
        CLRA                             ;0625: 4F             'O'
        ;;
        ;; Looks like $0D is getting added to the BUF (getting ready to print?)
        ;; 
        LDAB    #$0D                     ;0626: C6 0D          '..'
        JSR     Z0F25                    ;0628: BD 0F 25       '..%'
        LDX     #SBFPTR                  ;062B: CE 10 81       '...'
        STX     STRPTR                   ;062E: DF 27          '.''
;       LDX     #M1000                   ;0630: CE 10 00       '...'
        LDX     #BUF                     ;0630: CE 10 00       '...'
        JSR     Z0E99                    ;0633: BD 0E 99       '...'
        LDAB    M0067                    ;0636: D6 67          '.g'
        LDAA    M0066                    ;0638: 96 66          '.f'
        ADDB    M0063                    ;063A: DB 63          '.c'
        ADCA    M0062                    ;063C: 99 62          '.b'
        ADDB    #$01                     ;063E: CB 01          '..'
        ADCA    #$00                     ;0640: 89 00          '..'
        STAB    M0067                    ;0642: D7 67          '.g'
        STAA    M0066                    ;0644: 97 66          '.f'
;       LDAB    M0059                    ;0646: D6 59          '.Y'
;       LDAA    M0058                    ;0648: 96 58          '.X'
        LDAB    lo(X)                    ;0646: D6 59          '.Y'
        LDAA    hi(X)                    ;0648: 96 58          '.X'
        ADDB    #$01                     ;064A: CB 01          '..'
        ADCA    #$00                     ;064C: 89 00          '..'
;       STAB    M0059                    ;064E: D7 59          '.Y'
;       STAA    M0058                    ;0650: 97 58          '.X'
        STAB    lo(X)                    ;064E: D7 59          '.Y'
        STAA    hi(X)                    ;0650: 97 58          '.X'
;       LDAB    M0059                    ;0652: D6 59          '.Y'
;       LDAA    M0058                    ;0654: 96 58          '.X'
        LDAB    lo(X)                    ;0652: D6 59          '.Y'
        LDAA    hi(X)                    ;0654: 96 58          '.X'
        SUBB    #$03                     ;0656: C0 03          '..'
        SBCA    #$00                     ;0658: 82 00          '..'
        BLT     Z0664                    ;065A: 2D 08          '-.'
        BNE     Z0661                    ;065C: 26 03          '&.'
        TSTB                             ;065E: 5D             ']'
        BEQ     Z0664                    ;065F: 27 03          ''.'
Z0661   JSR     Z0667                    ;0661: BD 06 67       '..g'
Z0664   JMP     Z050D                    ;0664: 7E 05 0D       '~..'
; ------------------------------------------------------------------------------
;*
;* 494 TWRITE BUF$ ?
;*
LN0494
;0667   LDX     #M1000                   ;0667: CE 10 00       '...'
Z0667   LDX     #BUF                     ;0667: CE 10 00       '...'
        JSR     Z0D7F                    ;066A: BD 0D 7F       '...'
;       JSR     Z0DAB                    ;066D: BD 0D AB       '...'
        JSR     TWRITE                   ;066D: BD 0D AB       '...'
LN0496
Z0670   CLRA                             ;0670: 4F             'O'
        CLRB                             ;0671: 5F             '_'
;       STAB    M0067                    ;0672: D7 67          '.g'
;       STAA    M0066                    ;0674: 97 66          '.f'
        STAB    lo(P1)                   ;0672: D7 67          '.g'
        STAA    hi(P1)                   ;0674: 97 66          '.f'
        CLRA                             ;0676: 4F             'O'
        CLRB                             ;0677: 5F             '_'
;       STAB    M0059                    ;0678: D7 59          '.Y'
;       STAA    M0058                    ;067A: 97 58          '.X'
        STAB    lo(X)                    ;0678: D7 59          '.Y'
        STAA    hi(X)                    ;067A: 97 58          '.X'
        BRA     Z067F                    ;067C: 20 01          ' .'
; ------------------------------------------------------------------------------
; WTFrell
        ;;
        ;; Weird
        ;; 
WTF005  FCB     $00                      ;067E: 00             '.'
Z067F   LDX     #WTF005                  ;067F: CE 06 7E       '..~'
        STX     STRPTR                   ;0682: DF 27          '.''
;       LDX     #M1000                   ;0684: CE 10 00       '...'
        LDX     #BUF                     ;0684: CE 10 00       '...'
        JSR     Z0E99                    ;0687: BD 0E 99       '...'
        RTS                              ;068A: 39             '9'
; ------------------------------------------------------------------------------

Z068B   JSR     Z0B5B                    ;068B: BD 0B 5B       '..['
Z068E   JSR     Z09B7                    ;068E: BD 09 B7       '...'
        LDAB    M005D                    ;0691: D6 5D          '.]'
        LDAA    M005C                    ;0693: 96 5C          '.\'
        ;;
        ;; $2710 = 10000
        ;; 
        SUBB    #$10                     ;0695: C0 10          '..'
        SBCA    #$27                     ;0697: 82 27          '.''
        BNE     Z06A1                    ;0699: 26 06          '&.'
        TSTB                             ;069B: 5D             ']'
        BNE     Z06A1                    ;069C: 26 03          '&.'
;       JMP     Z0147                    ;069E: 7E 01 47       '~.G'
        JMP     MENU                     ;069E: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------

Z06A1   LDAB    M005B                    ;06A1: D6 5B          '.['
        LDAA    M005A                    ;06A3: 96 5A          '.Z'
        PSHB                             ;06A5: 37             '7'
        PSHA                             ;06A6: 36             '6'
        LDAB    M005F                    ;06A7: D6 5F          '._'
        LDAA    M005E                    ;06A9: 96 5E          '.^'
        ADDB    #$01                     ;06AB: CB 01          '..'
        ADCA    #$00                     ;06AD: 89 00          '..'
        NEGA                             ;06AF: 40             '@'
        NEGB                             ;06B0: 50             'P'
        SBCA    #$00                     ;06B1: 82 00          '..'
        TSX                              ;06B3: 30             '0'
        ADDB    $01,X                    ;06B4: EB 01          '..'
        ADCA    ,X                       ;06B6: A9 00          '..'
        INS                              ;06B8: 31             '1'
        INS                              ;06B9: 31             '1'
        BLT     Z06C4                    ;06BA: 2D 08          '-.'
        BNE     Z06C1                    ;06BC: 26 03          '&.'
        TSTB                             ;06BE: 5D             ']'
        BEQ     Z06C4                    ;06BF: 27 03          ''.'
;06C1   JMP     Z0147                    ;06C1: 7E 01 47       '~.G'
Z06C1   JMP     MENU                     ;06C1: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------

Z06C4   JSR     Z0A86                    ;06C4: BD 0A 86       '...'
        JMP     Z068E                    ;06C7: 7E 06 8E       '~..'
; ------------------------------------------------------------------------------

LN0600
LN0630                          ;?
Z06CA   JSR     Z0BEA                    ;06CA: BD 0B EA       '...'
;       LDAB    M0059                    ;06CD: D6 59          '.Y'
;       LDAA    M0058                    ;06CF: 96 58          '.X'
        LDAB    lo(X)                    ;06CD: D6 59          '.Y'
        LDAA    hi(X)                    ;06CF: 96 58          '.X'
        SUBB    #$04                     ;06D1: C0 04          '..'
        SBCA    #$00                     ;06D3: 82 00          '..'
        BGE     Z06DA                    ;06D5: 2C 03          ',.'
;       JMP     Z0147                    ;06D7: 7E 01 47       '~.G'
        JMP     MENU                     ;06D7: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------

;06DA   LDX     #M1000                   ;06DA: CE 10 00       '...'
Z06DA   LDX     #BUF                     ;06DA: CE 10 00       '...'
;       JSR     Z0CEA                    ;06DD: BD 0C EA       '...'
        JSR     TREAD                    ;06DD: BD 0C EA       '...'
Z06E0   LDAA    #$10                     ;06E0: 86 10          '..'
        LDAB    #$81                     ;06E2: C6 81          '..'
        STAB    STRPTR+1                 ;06E4: D7 28          '.('
        STAA    STRPTR                   ;06E6: 97 27          '.''
        CLRA                             ;06E8: 4F             'O'
        ;;
        ;; Looks like $0D is getting added to the BUF (getting ready to print?)
        ;; 
        LDAB    #$0D                     ;06E9: C6 0D          '..'
        JSR     Z0F25                    ;06EB: BD 0F 25       '..%'
        ;;
        ;; Looks like NULL in a similar location (different buf) ???
        ;; 
        JSR     Z0F2A                    ;06EE: BD 0F 2A       '..*'
        LDX     STRPTR                   ;06F1: DE 27          '.''
        STX     XSAVE                    ;06F3: DF 20          '. '
;       LDX     #M1000                   ;06F5: CE 10 00       '...'
        LDX     #BUF                     ;06F5: CE 10 00       '...'
        JSR     Z0F00                    ;06F8: BD 0F 00       '...'
        LDX     #SBFPTR                  ;06FB: CE 10 81       '...'
        JSR     Z0F30                    ;06FE: BD 0F 30       '..0'
;       STAB    M0059                    ;0701: D7 59          '.Y'
;       STAA    M0058                    ;0703: 97 58          '.X'
        STAB    lo(X)                    ;0701: D7 59          '.Y'
        STAA    hi(X)                    ;0703: 97 58          '.X'
;       LDAB    M0059                    ;0705: D6 59          '.Y'
;       LDAA    M0058                    ;0707: 96 58          '.X'
        LDAB    lo(X)                    ;0705: D6 59          '.Y'
        LDAA    hi(X)                    ;0707: 96 58          '.X'
        SUBB    #$00                     ;0709: C0 00          '..'
        SBCA    #$00                     ;070B: 82 00          '..'
        BNE     Z0712                    ;070D: 26 03          '&.'
        TSTB                             ;070F: 5D             ']'
        BEQ     Z0715                    ;0710: 27 03          ''.'
Z0712   JMP     Z0764                    ;0712: 7E 07 64       '~.d'
; ------------------------------------------------------------------------------

Z0715   LDAA    #$10                     ;0715: 86 10          '..'
        LDAB    #$81                     ;0717: C6 81          '..'
        STAB    STRPTR+1                    ;0719: D7 28          '.('
        STAA    STRPTR                    ;071B: 97 27          '.''
        CLRA                             ;071D: 4F             'O'
        LDAB    #$1A                     ;071E: C6 1A          '..'
        JSR     Z0F25                    ;0720: BD 0F 25       '..%'
        JSR     Z0F2A                    ;0723: BD 0F 2A       '..*'
        LDX     STRPTR                    ;0726: DE 27          '.''
        STX     XSAVE                    ;0728: DF 20          '. '
;       LDX     #M1000                   ;072A: CE 10 00       '...'
        LDX     #BUF                     ;072A: CE 10 00       '...'
        JSR     Z0F00                    ;072D: BD 0F 00       '...'
        LDX     #SBFPTR                   ;0730: CE 10 81       '...'
        JSR     Z0F30                    ;0733: BD 0F 30       '..0'
;       STAB    M0059                    ;0736: D7 59          '.Y'
;       STAA    M0058                    ;0738: 97 58          '.X'
        STAB    lo(X)                    ;0736: D7 59          '.Y'
        STAA    hi(X)                    ;0738: 97 58          '.X'
;       LDAB    M0059                    ;073A: D6 59          '.Y'
;       LDAA    M0058                    ;073C: 96 58          '.X'
        LDAB    lo(X)                    ;073A: D6 59          '.Y'
        LDAA    hi(X)                    ;073C: 96 58          '.X'
        SUBB    #$00                     ;073E: C0 00          '..'
        SBCA    #$00                     ;0740: 82 00          '..'
        BNE     Z074A                    ;0742: 26 06          '&.'
        TSTB                             ;0744: 5D             ']'
        BNE     Z074A                    ;0745: 26 03          '&.'
        ;;
        ;; LN0600 or LN0630? same place for now
        ;; 
;       JMP     Z06CA                    ;0747: 7E 06 CA       '~..'
        JMP     LN0600                   ;0747: 7E 06 CA       '~..'
; ------------------------------------------------------------------------------

;074A   LDX     #M1000                   ;074A: CE 10 00       '...'
Z074A   LDX     #BUF                     ;074A: CE 10 00       '...'
        JSR     Z0D7F                    ;074D: BD 0D 7F       '...'
        BRA     Z0758                    ;0750: 20 06          ' .'
; ------------------------------------------------------------------------------
EOFSTR  fcc    '*EOF*\0'
;M0752   BPL     Z0799                    ;0752: 2A 45          '*E'
;        CLRA                             ;0754: 4F             'O'
;        RORA                             ;0755: 46             'F'
;        BPL     Z0758                    ;0756: 2A 00          '*.'
; ------------------------------------------------------------------------------
Z0758   LDX     #EOFSTR                  ;0758: CE 07 52       '..R'
        JSR     XPRNT                    ;075B: BD 0D EF       '...'
        JSR     Z0DD1                    ;075E: BD 0D D1       '...'
;       JMP     Z0147                    ;0761: 7E 01 47       '~.G'
        JMP     MENU                     ;0761: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------

Z0764   JSR     Z0B18                    ;0764: BD 0B 18       '...'
;       LDAB    M0033                    ;0767: D6 33          '.3'
;       LDAA    M0032                    ;0769: 96 32          '.2'
        LDAB    lo(K)                    ;0767: D6 33          '.3'
        LDAA    hi(K)                    ;0769: 96 32          '.2'
;       ADDB    M0031                    ;076B: DB 31          '.1'
;       ADCA    M0030                    ;076D: 99 30          '.0'
        ADDB    lo(V)                    ;076B: DB 31          '.1'
        ADCA    hi(V)                    ;076D: 99 30          '.0'
        LDAA    #$20                     ;076F: 86 20          '. '
        JSR     Z0E53                    ;0771: BD 0E 53       '..S'
        ADDB    #$46                     ;0774: CB 46          '.F'
        ADCA    #$13                     ;0776: 89 13          '..'
        PSHB                             ;0778: 37             '7'
        PSHA                             ;0779: 36             '6'
        BRA     Z077D                    ;077A: 20 01          ' .'
; ------------------------------------------------------------------------------
; WTFrell
WTF006  FCB     $00                      ;077C: 00             '.'
Z077D   LDX     #WTF006                  ;077D: CE 07 7C       '..|'
        STX     STRPTR                    ;0780: DF 27          '.''
        TSX                              ;0782: 30             '0'
        LDX     ,X                       ;0783: EE 00          '..'
        INS                              ;0785: 31             '1'
        INS                              ;0786: 31             '1'
        JSR     Z0EA0                    ;0787: BD 0E A0       '...'
;       LDAB    M0033                    ;078A: D6 33          '.3'
;       LDAA    M0032                    ;078C: 96 32          '.2'
        LDAB    lo(K)                    ;078A: D6 33          '.3'
        LDAA    hi(K)                    ;078C: 96 32          '.2'
        ASLB                             ;078E: 58             'X'
        ROLA                             ;078F: 49             'I'
        ADDB    #$00                     ;0790: CB 00          '..'
        ADCA    #$13                     ;0792: 89 13          '..'
        PSHB                             ;0794: 37             '7'
        PSHA                             ;0795: 36             '6'
;       LDX     #M1000                   ;0796: CE 10 00       '...'
        LDX     #BUF                     ;0796: CE 10 00       '...'
Z0799   LDAA    #$10                     ;0799: 86 10          '..'
        LDAB    #$81                     ;079B: C6 81          '..'
        STAB    STRPTR+1                    ;079D: D7 28          '.('
        STAA    STRPTR                    ;079F: 97 27          '.''
        JSR     Z0F00                    ;07A1: BD 0F 00       '...'
        LDX     #SBFPTR                   ;07A4: CE 10 81       '...'
        JSR     Z0FA7                    ;07A7: BD 0F A7       '...'
        TSX                              ;07AA: 30             '0'
        LDX     ,X                       ;07AB: EE 00          '..'
        INS                              ;07AD: 31             '1'
        INS                              ;07AE: 31             '1'
        STAA    ,X                       ;07AF: A7 00          '..'
        STAB    $01,X                    ;07B1: E7 01          '..'
;       LDAB    M0059                    ;07B3: D6 59          '.Y'
;       LDAA    M0058                    ;07B5: 96 58          '.X'
        LDAB    lo(X)                    ;07B3: D6 59          '.Y'
        LDAA    hi(X)                    ;07B5: 96 58          '.X'
        SUBB    #$21                     ;07B7: C0 21          '.!'
        SBCA    #$00                     ;07B9: 82 00          '..'
        BLT     Z07C2                    ;07BB: 2D 05          '-.'
        BNE     Z07C5                    ;07BD: 26 06          '&.'
        TSTB                             ;07BF: 5D             ']'
        BNE     Z07C5                    ;07C0: 26 03          '&.'
; ------------------------------------------------------------------------------
Z07C2   JMP     Z0808                    ;07C2: 7E 08 08       '~..'

;07C5   LDAB    M0033                    ;07C5: D6 33          '.3'
;       LDAA    M0032                    ;07C7: 96 32          '.2'
Z07C5   LDAB    lo(K)                    ;07C5: D6 33          '.3'
        LDAA    hi(K)                    ;07C7: 96 32          '.2'
;       ADDB    M0031                    ;07C9: DB 31          '.1'
;       ADCA    M0030                    ;07CB: 99 30          '.0'
        ADDB    lo(V)                    ;07C9: DB 31          '.1'
        ADCA    hi(V)                    ;07CB: 99 30          '.0'
        LDAA    #$20                     ;07CD: 86 20          '. '
        JSR     Z0E53                    ;07CF: BD 0E 53       '..S'
        ADDB    #$46                     ;07D2: CB 46          '.F'
        ADCA    #$13                     ;07D4: 89 13          '..'
        PSHB                             ;07D6: 37             '7'
        PSHA                             ;07D7: 36             '6'
        LDAA    #$10                     ;07D8: 86 10          '..'
        LDAB    #$81                     ;07DA: C6 81          '..'
        STAB    STRPTR+1                    ;07DC: D7 28          '.('
        STAA    STRPTR                    ;07DE: 97 27          '.''
        DES                              ;07E0: 34             '4'
        DES                              ;07E1: 34             '4'
        JSR     Z0E68                    ;07E2: BD 0E 68       '..h'
;       LDX     #M1000                   ;07E5: CE 10 00       '...'
        LDX     #BUF                     ;07E5: CE 10 00       '...'
        JSR     Z0F00                    ;07E8: BD 0F 00       '...'
        CLRA                             ;07EB: 4F             'O'
        LDAB    #$21                     ;07EC: C6 21          '.!'
        PSHB                             ;07EE: 37             '7'
;       LDAB    M0059                    ;07EF: D6 59          '.Y'
;       LDAA    M0058                    ;07F1: 96 58          '.X'
        LDAB    lo(X)                    ;07EF: D6 59          '.Y'
        LDAA    hi(X)                    ;07F1: 96 58          '.X'
        SUBB    #$21                     ;07F3: C0 21          '.!'
        SBCA    #$00                     ;07F5: 82 00          '..'
        PULA                             ;07F7: 32             '2'
        JSR     Z0ECA                    ;07F8: BD 0E CA       '...'
        LDX     #SBFPTR                   ;07FB: CE 10 81       '...'
        STX     STRPTR                    ;07FE: DF 27          '.''
        TSX                              ;0800: 30             '0'
        LDX     ,X                       ;0801: EE 00          '..'
        INS                              ;0803: 31             '1'
        INS                              ;0804: 31             '1'
        JSR     Z0EA0                    ;0805: BD 0E A0       '...'
;0808   LDAB    M0033                    ;0808: D6 33          '.3'
;       LDAA    M0032                    ;080A: 96 32          '.2'
Z0808   LDAB    lo(K)                    ;0808: D6 33          '.3'
        LDAA    hi(K)                    ;080A: 96 32          '.2'
        LDAA    #$20                     ;080C: 86 20          '. '
        JSR     Z0E53                    ;080E: BD 0E 53       '..S'
        ADDB    #$46                     ;0811: CB 46          '.F'
        ADCA    #$13                     ;0813: 89 13          '..'
        PSHB                             ;0815: 37             '7'
        PSHA                             ;0816: 36             '6'
        LDAA    #$10                     ;0817: 86 10          '..'
        LDAB    #$81                     ;0819: C6 81          '..'
        STAB    STRPTR+1                    ;081B: D7 28          '.('
        STAA    STRPTR                    ;081D: 97 27          '.''
        DES                              ;081F: 34             '4'
        DES                              ;0820: 34             '4'
        JSR     Z0E68                    ;0821: BD 0E 68       '..h'
;       LDX     #M1000                   ;0824: CE 10 00       '...'
        LDX     #BUF                     ;0824: CE 10 00       '...'
        JSR     Z0F00                    ;0827: BD 0F 00       '...'
;       LDAB    M0059                    ;082A: D6 59          '.Y'
;       LDAA    M0058                    ;082C: 96 58          '.X'
        LDAB    lo(X)                    ;082A: D6 59          '.Y'
        LDAA    hi(X)                    ;082C: 96 58          '.X'
        SUBB    #$01                     ;082E: C0 01          '..'
        SBCA    #$00                     ;0830: 82 00          '..'njc

        JSR     Z0EE5                    ;0832: BD 0E E5       '...'
        LDX     #SBFPTR                   ;0835: CE 10 81       '...'
        STX     STRPTR                    ;0838: DF 27          '.''
        TSX                              ;083A: 30             '0'
        LDX     ,X                       ;083B: EE 00          '..'
        INS                              ;083D: 31             '1'
        INS                              ;083E: 31             '1'
        JSR     Z0EA0                    ;083F: BD 0E A0       '...'
;       LDX     #M1000                   ;0842: CE 10 00       '...'
        LDX     #BUF                     ;0842: CE 10 00       '...'
        LDAA    #$10                     ;0845: 86 10          '..'
        LDAB    #$81                     ;0847: C6 81          '..'
        STAB    STRPTR+1                    ;0849: D7 28          '.('
        STAA    STRPTR                    ;084B: 97 27          '.''
        JSR     Z0F00                    ;084D: BD 0F 00       '...'
        LDX     #SBFPTR                   ;0850: CE 10 81       '...'
        JSR     Z0E7A                    ;0853: BD 0E 7A       '..z'
;       SUBB    M0059                    ;0856: D0 59          '.Y'
;       SBCA    M0058                    ;0858: 92 58          '.X'
        SUBB    lo(X)                    ;0856: D0 59          '.Y'
        SBCA    hi(X)                    ;0858: 92 58          '.X'
        STAB    M0069                    ;085A: D7 69          '.i'
        STAA    M0068                    ;085C: 97 68          '.h'
        LDAA    #$10                     ;085E: 86 10          '..'
        LDAB    #$81                     ;0860: C6 81          '..'
        STAB    STRPTR+1                    ;0862: D7 28          '.('
        STAA    STRPTR                    ;0864: 97 27          '.''
        DES                              ;0866: 34             '4'
        DES                              ;0867: 34             '4'
        JSR     Z0E68                    ;0868: BD 0E 68       '..h'
;       LDX     #M1000                   ;086B: CE 10 00       '...'
        LDX     #BUF                     ;086B: CE 10 00       '...'
        JSR     Z0F00                    ;086E: BD 0F 00       '...'
;       LDAB    M0059                    ;0871: D6 59          '.Y'
;       LDAA    M0058                    ;0873: 96 58          '.X'
        LDAB    lo(X)                    ;0871: D6 59          '.Y'
        LDAA    hi(X)                    ;0873: 96 58          '.X'
        ADDB    #$01                     ;0875: CB 01          '..'
        ADCA    #$00                     ;0877: 89 00          '..'
        PSHB                             ;0879: 37             '7'
        LDAB    M0069                    ;087A: D6 69          '.i'
        LDAA    M0068                    ;087C: 96 68          '.h'
        PULA                             ;087E: 32             '2'
        JSR     Z0ECA                    ;087F: BD 0E CA       '...'
        LDX     #SBFPTR                   ;0882: CE 10 81       '...'
        STX     STRPTR                    ;0885: DF 27          '.''
;       LDX     #M1000                   ;0887: CE 10 00       '...'
        LDX     #BUF                     ;0887: CE 10 00       '...'
        JSR     Z0E99                    ;088A: BD 0E 99       '...'
        JMP     Z06E0                    ;088D: 7E 06 E0       '~..'
; ------------------------------------------------------------------------------

Z0890   LDAA    #$10                     ;0890: 86 10          '..'
        LDAB    #$81                     ;0892: C6 81          '..'
        STAB    STRPTR+1                    ;0894: D7 28          '.('
        STAA    STRPTR                    ;0896: 97 27          '.''
        DES                              ;0898: 34             '4'
        DES                              ;0899: 34             '4'
        JSR     Z0E68                    ;089A: BD 0E 68       '..h'
; ------------------------------------------------------------------------------
; WTFrell
;TF007  LDX     #M1000                   ;089D: CE 10 00       '...'
WTF007  LDX     #BUF                     ;089D: CE 10 00       '...'
        JSR     Z0F00                    ;08A0: BD 0F 00       '...'
        CLRA                             ;08A3: 4F             'O'
        LDAB    #$03                     ;08A4: C6 03          '..'
        PSHB                             ;08A6: 37             '7'
        CLRA                             ;08A7: 4F             'O'
        LDAB    #$20                     ;08A8: C6 20          '. '
        PULA                             ;08AA: 32             '2'
        JSR     Z0ECA                    ;08AB: BD 0E CA       '...'
        LDX     #SBFPTR                   ;08AE: CE 10 81       '...'
        STX     STRPTR                    ;08B1: DF 27          '.''
        LDX     #M0036                   ;08B3: CE 00 36       '..6'
        JSR     Z0EA0                    ;08B6: BD 0E A0       '...'
        CLRA                             ;08B9: 4F             'O'
        LDAB    #$01                     ;08BA: C6 01          '..'
        STAB    M0065                    ;08BC: D7 65          '.e'
        STAA    M0064                    ;08BE: 97 64          '.d'
;       LDAB    M0031                    ;08C0: D6 31          '.1'
;       LDAA    M0030                    ;08C2: 96 30          '.0'
        LDAB    lo(V)                    ;08C0: D6 31          '.1'
        LDAA    hi(V)                    ;08C2: 96 30          '.0'
        STAB    M006B                    ;08C4: D7 6B          '.k'
        STAA    M006A                    ;08C6: 97 6A          '.j'
Z08C8   LDAB    M0065                    ;08C8: D6 65          '.e'
        LDAA    M0064                    ;08CA: 96 64          '.d'
        ASLB                             ;08CC: 58             'X'
        ROLA                             ;08CD: 49             'I'
        ADDB    #$00                     ;08CE: CB 00          '..'
        ADCA    #$13                     ;08D0: 89 13          '..'
        JSR     Z0FCE                    ;08D2: BD 0F CE       '...'
        SUBB    #$00                     ;08D5: C0 00          '..'
        SBCA    #$00                     ;08D7: 82 00          '..'
        BNE     Z08E1                    ;08D9: 26 06          '&.'
        TSTB                             ;08DB: 5D             ']'
        BNE     Z08E1                    ;08DC: 26 03          '&.'
        JMP     Z0932                    ;08DE: 7E 09 32       '~.2'
; ------------------------------------------------------------------------------

Z08E1   LDX     #M0036                   ;08E1: CE 00 36       '..6'
        LDAA    #$10                     ;08E4: 86 10          '..'
        LDAB    #$81                     ;08E6: C6 81          '..'
        STAB    STRPTR+1                    ;08E8: D7 28          '.('
        STAA    STRPTR                    ;08EA: 97 27          '.''
        JSR     Z0F09                    ;08EC: BD 0F 09       '...'
        JSR     Z0F2A                    ;08EF: BD 0F 2A       '..*'
        LDX     STRPTR                    ;08F2: DE 27          '.''
        STX     XSAVE                    ;08F4: DF 20          '. '
        LDAB    M0065                    ;08F6: D6 65          '.e'
        LDAA    M0064                    ;08F8: 96 64          '.d'
        LDAA    #$20                     ;08FA: 86 20          '. '
        JSR     Z0E53                    ;08FC: BD 0E 53       '..S'
        ADDB    #$46                     ;08FF: CB 46          '.F'
        ADCA    #$13                     ;0901: 89 13          '..'
        JSR     Z0FCE                    ;0903: BD 0F CE       '...'
        JSR     Z0F09                    ;0906: BD 0F 09       '...'
        LDAB    M0065                    ;0909: D6 65          '.e'
        LDAA    M0064                    ;090B: 96 64          '.d'
;       ADDB    M0031                    ;090D: DB 31          '.1'
;       ADCA    M0030                    ;090F: 99 30          '.0'
        ADDB    lo(V)                    ;090D: DB 31          '.1'
        ADCA    hi(V)                    ;090F: 99 30          '.0'
        LDAA    #$20                     ;0911: 86 20          '. '
        JSR     Z0E53                    ;0913: BD 0E 53       '..S'
        ADDB    #$46                     ;0916: CB 46          '.F'
        ADCA    #$13                     ;0918: 89 13          '..'
        JSR     Z0FCE                    ;091A: BD 0F CE       '...'
        JSR     Z0F09                    ;091D: BD 0F 09       '...'
        LDX     #SBFPTR                   ;0920: CE 10 81       '...'
        JSR     Z0F30                    ;0923: BD 0F 30       '..0'
        SUBB    #$00                     ;0926: C0 00          '..'
        SBCA    #$00                     ;0928: 82 00          '..'
        BNE     Z092F                    ;092A: 26 03          '&.'
        TSTB                             ;092C: 5D             ']'
        BEQ     Z0932                    ;092D: 27 03          ''.'
; ------------------------------------------------------------------------------
Z092F   JMP     Z0981                    ;092F: 7E 09 81       '~..'

Z0932   LDAB    M0065                    ;0932: D6 65          '.e'
        LDAA    M0064                    ;0934: 96 64          '.d'
        ADDB    #$01                     ;0936: CB 01          '..'
        ADCA    #$00                     ;0938: 89 00          '..'
        STAB    M0065                    ;093A: D7 65          '.e'
        STAA    M0064                    ;093C: 97 64          '.d'
        SUBB    M006B                    ;093E: D0 6B          '.k'
        SBCA    M006A                    ;0940: 92 6A          '.j'
        BLT     Z0949                    ;0942: 2D 05          '-.'
        BNE     Z094C                    ;0944: 26 06          '&.'
        TSTB                             ;0946: 5D             ']'
        BNE     Z094C                    ;0947: 26 03          '&.'
; ------------------------------------------------------------------------------
Z0949   JMP     Z08C8                    ;0949: 7E 08 C8       '~..'

;094C   LDX     #M1000                   ;094C: CE 10 00       '...'
Z094C   LDX     #BUF                     ;094C: CE 10 00       '...'
        JSR     Z0D7F                    ;094F: BD 0D 7F       '...'
        LDX     #M0036                   ;0952: CE 00 36       '..6'
        LDAA    #$10                     ;0955: 86 10          '..'
        LDAB    #$81                     ;0957: C6 81          '..'
        STAB    STRPTR+1                 ;0959: D7 28          '.('
        STAA    STRPTR                   ;095B: 97 27          '.''
        JSR     Z0F09                    ;095D: BD 0F 09       '...'
        BRA     Z096F                    ;0960: 20 0D          ' .'
; ------------------------------------------------------------------------------
;* Part of Find string
;0962   BRA     Z0984                    ;0962: 20 20          '  '
NFOUND  FCC     "   NOT FOUND"           ;0964: 20 4E 4F 54 20 46 4F 55 4E 44 ' NOT FOUND'
        FCB     $00                      ;096E: 00             '.'
; ------------------------------------------------------------------------------
;096F   LDX     #M0962                   ;096F: CE 09 62       '..b'
Z096F   LDX     #NFOUND                  ;096F: CE 09 62       '..b'
        JSR     Z0F00                    ;0972: BD 0F 00       '...'
        LDX     #SBFPTR                  ;0975: CE 10 81       '...'
        JSR     XPRNT                    ;0978: BD 0D EF       '...'
        JSR     Z0DD1                    ;097B: BD 0D D1       '...'
;       JMP     Z0147                    ;097E: 7E 01 47       '~.G'
        JMP     MENU                     ;097E: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------

Z0981   JSR     Z0A86                    ;0981: BD 0A 86       '...'
;0984   JMP     Z0147                    ;0984: 7E 01 47       '~.G'
Z0984   JMP     MENU                     ;0984: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* Calculate lines available
;* M1000 -
;* BUF   -
;* M0058 -
;*
LN0900
Z0987   JSR     Z0BEA                    ;0987: BD 0B EA       '...'
;       LDX     #M1000                   ;098A: CE 10 00       '...'
        LDX     #BUF                     ;098A: CE 10 00       '...'
        ;;
        ;; Calulating the # of lines here?
        ;; 
        JSR     Z0D7F                    ;098D: BD 0D 7F       '...'
;       LDAB    M0059                    ;0990: D6 59          '.Y'
;       LDAA    M0058                    ;0992: 96 58          '.X'
        LDAB    lo(X)                    ;0990: D6 59          '.Y'
        LDAA    hi(X)                    ;0992: 96 58          '.X'
	;;
        ;; Gota print the #of lines and space here
        ;; 
        JSR     Z0DFC                    ;0994: BD 0D FC       '...'
        BRA     Z09AB                    ;0997: 20 12          ' .'
; ------------------------------------------------------------------------------
AVAIL   FCC     "  LINES AVAILABLE"      ;0999: 20 20 4C 49 4E 45 53 20 41 56 41 49 4C 41 42 4C 45 '  LINES AVAILABLE'
        FCB     $00                      ;09AA: 00             '.'
; ------------------------------------------------------------------------------
Z09AB   LDX     #AVAIL                   ;09AB: CE 09 99       '...'
        JSR     XPRNT                    ;09AE: BD 0D EF       '...'
        JSR     Z0DD1                    ;09B1: BD 0D D1       '...'
;       JMP     Z0147                    ;09B4: 7E 01 47       '~.G'
        JMP     MENU                     ;09B4: 7E 01 47       '~.G'
; ------------------------------------------------------------------------------
;*
;* 2000 J=1 : T=10000
;*
Z09B7   CLRA                             ;09B7: 4F             'O'
        LDAB    #$01                     ;09B8: C6 01          '..'
        ;;
        ;; J = 1
        ;; 
        STAB    M006D                    ;09BA: D7 6D          '.m'
        STAA    M006C                    ;09BC: 97 6C          '.l'
        ;;
        ;; $2710 = 10000
        ;; 
        LDAA    #$27                     ;09BE: 86 27          '.''
        LDAB    #$10                     ;09C0: C6 10          '..'
        ;;
        ;;  T = 10000
        STAB    M005D                    ;09C2: D7 5D          '.]'
        STAA    M005C                    ;09C4: 97 5C          '.\'
Z09C6   LDAB    M006D                    ;09C6: D6 6D          '.m'
        LDAA    M006C                    ;09C8: 96 6C          '.l'
        ASLB                             ;09CA: 58             'X'
        ROLA                             ;09CB: 49             'I'
        ;;
        ;;  Q = N(J)
        ;; 
        ADDB    #$00                     ;09CC: CB 00          '..'
        ADCA    #$13                     ;09CE: 89 13          '..'
        JSR     Z0FCE                    ;09D0: BD 0F CE       '...'
        ;;
        ;; Q
        ;; 
        STAB    M006F                    ;09D3: D7 6F          '.o'
        STAA    M006E                    ;09D5: 97 6E          '.n'
        LDAB    M006F                    ;09D7: D6 6F          '.o'
        LDAA    M006E                    ;09D9: 96 6E          '.n'
        SUBB    #$00                     ;09DB: C0 00          '..'
        SBCA    #$00                     ;09DD: 82 00          '..'
        BNE     Z09E7                    ;09DF: 26 06          '&.'
        TSTB                             ;09E1: 5D             ']'
        BNE     Z09E7                    ;09E2: 26 03          '&.'
        JMP     Z0A2B                    ;09E4: 7E 0A 2B       '~.+'
; ------------------------------------------------------------------------------

Z09E7   LDAB    M005B                    ;09E7: D6 5B          '.['
        LDAA    M005A                    ;09E9: 96 5A          '.Z'
        SUBB    M006F                    ;09EB: D0 6F          '.o'
        SBCA    M006E                    ;09ED: 92 6E          '.n'
        BLT     Z09F9                    ;09EF: 2D 08          '-.'
        BNE     Z09F6                    ;09F1: 26 03          '&.'
        TSTB                             ;09F3: 5D             ']'
        BEQ     Z09F9                    ;09F4: 27 03          ''.'
Z09F6   JMP     Z0A2B                    ;09F6: 7E 0A 2B       '~.+'
; ------------------------------------------------------------------------------

Z09F9   LDAB    M006F                    ;09F9: D6 6F          '.o'
        LDAA    M006E                    ;09FB: 96 6E          '.n'
        SUBB    M005B                    ;09FD: D0 5B          '.['
        SBCA    M005A                    ;09FF: 92 5A          '.Z'
        BNE     Z0A09                    ;0A01: 26 06          '&.'
        TSTB                             ;0A03: 5D             ']'
        BNE     Z0A09                    ;0A04: 26 03          '&.'
        JMP     Z0A69                    ;0A06: 7E 0A 69       '~.i'
; ------------------------------------------------------------------------------

Z0A09   LDAB    M006F                    ;0A09: D6 6F          '.o'
        LDAA    M006E                    ;0A0B: 96 6E          '.n'
        SUBB    M005D                    ;0A0D: D0 5D          '.]'
        SBCA    M005C                    ;0A0F: 92 5C          '.\'
        BLT     Z0A1B                    ;0A11: 2D 08          '-.'
        BNE     Z0A18                    ;0A13: 26 03          '&.'
        TSTB                             ;0A15: 5D             ']'
        BEQ     Z0A1B                    ;0A16: 27 03          ''.'
Z0A18   JMP     Z0A2B                    ;0A18: 7E 0A 2B       '~.+'
; ------------------------------------------------------------------------------

Z0A1B   LDAB    M006F                    ;0A1B: D6 6F          '.o'
        LDAA    M006E                    ;0A1D: 96 6E          '.n'
        STAB    M005D                    ;0A1F: D7 5D          '.]'
        STAA    M005C                    ;0A21: 97 5C          '.\'
        LDAB    M006D                    ;0A23: D6 6D          '.m'
        LDAA    M006C                    ;0A25: 96 6C          '.l'
        STAB    M0065                    ;0A27: D7 65          '.e'
        STAA    M0064                    ;0A29: 97 64          '.d'
Z0A2B   LDAB    M006D                    ;0A2B: D6 6D          '.m'
        LDAA    M006C                    ;0A2D: 96 6C          '.l'
        ADDB    #$01                     ;0A2F: CB 01          '..'
        ADCA    #$00                     ;0A31: 89 00          '..'
        STAB    M006D                    ;0A33: D7 6D          '.m'
        STAA    M006C                    ;0A35: 97 6C          '.l'
        LDAB    M006D                    ;0A37: D6 6D          '.m'
        LDAA    M006C                    ;0A39: 96 6C          '.l'
        PSHB                             ;0A3B: 37             '7'
        PSHA                             ;0A3C: 36             '6'
;       LDAB    M0031                    ;0A3D: D6 31          '.1'
;       LDAA    M0030                    ;0A3F: 96 30          '.0'
        LDAB    lo(V)                    ;0A3D: D6 31          '.1'
        LDAA    hi(V)                    ;0A3F: 96 30          '.0'
        ADDB    #$01                     ;0A41: CB 01          '..'
        ADCA    #$00                     ;0A43: 89 00          '..'
        NEGA                             ;0A45: 40             '@'
        NEGB                             ;0A46: 50             'P'
        SBCA    #$00                     ;0A47: 82 00          '..'
        TSX                              ;0A49: 30             '0'
        ADDB    $01,X                    ;0A4A: EB 01          '..'
        ADCA    ,X                       ;0A4C: A9 00          '..'
        INS                              ;0A4E: 31             '1'
        INS                              ;0A4F: 31             '1'
        BNE     Z0A55                    ;0A50: 26 03          '&.'
        TSTB                             ;0A52: 5D             ']'
        BEQ     Z0A58                    ;0A53: 27 03          ''.'
Z0A55   JMP     Z09C6                    ;0A55: 7E 09 C6       '~..'
; ------------------------------------------------------------------------------

Z0A58   LDAB    M005D                    ;0A58: D6 5D          '.]'
        LDAA    M005C                    ;0A5A: 96 5C          '.\'
        SUBB    #$10                     ;0A5C: C0 10          '..'
        SBCA    #$27                     ;0A5E: 82 27          '.''
        BNE     Z0A65                    ;0A60: 26 03          '&.'
        TSTB                             ;0A62: 5D             ']'
        BEQ     Z0A68                    ;0A63: 27 03          ''.'
Z0A65   JMP     Z0A79                    ;0A65: 7E 0A 79       '~.y'
; ------------------------------------------------------------------------------

Z0A68   RTS                              ;0A68: 39             '9'
; ------------------------------------------------------------------------------

Z0A69   LDAB    M005B                    ;0A69: D6 5B          '.['
        LDAA    M005A                    ;0A6B: 96 5A          '.Z'
        STAB    M005D                    ;0A6D: D7 5D          '.]'
        STAA    M005C                    ;0A6F: 97 5C          '.\'
        LDAB    M006D                    ;0A71: D6 6D          '.m'
        LDAA    M006C                    ;0A73: 96 6C          '.l'
        STAB    M0065                    ;0A75: D7 65          '.e'
        STAA    M0064                    ;0A77: 97 64          '.d'
Z0A79   LDAB    M005D                    ;0A79: D6 5D          '.]'
        LDAA    M005C                    ;0A7B: 96 5C          '.\'
        ADDB    #$01                     ;0A7D: CB 01          '..'
        ADCA    #$00                     ;0A7F: 89 00          '..'
        STAB    M005B                    ;0A81: D7 5B          '.['
        STAA    M005A                    ;0A83: 97 5A          '.Z'
        RTS                              ;0A85: 39             '9'
; ------------------------------------------------------------------------------

;0A86   LDX     #M1000                   ;0A86: CE 10 00       '...'
Z0A86   LDX     #BUF                     ;0A86: CE 10 00       '...'
        JSR     Z0D7F                    ;0A89: BD 0D 7F       '...'
        LDAB    M0065                    ;0A8C: D6 65          '.e'
        LDAA    M0064                    ;0A8E: 96 64          '.d'
        LDAA    #$20                     ;0A90: 86 20          '. '
        JSR     Z0E53                    ;0A92: BD 0E 53       '..S'
        ADDB    #$46                     ;0A95: CB 46          '.F'
        ADCA    #$13                     ;0A97: 89 13          '..'
        JSR     Z0FCE                    ;0A99: BD 0F CE       '...'
        LDAA    #$10                     ;0A9C: 86 10          '..'
        LDAB    #$81                     ;0A9E: C6 81          '..'
        STAB    STRPTR+1                    ;0AA0: D7 28          '.('
        STAA    STRPTR                    ;0AA2: 97 27          '.''
        JSR     Z0F09                    ;0AA4: BD 0F 09       '...'
        LDAB    M0065                    ;0AA7: D6 65          '.e'
        LDAA    M0064                    ;0AA9: 96 64          '.d'
;       ADDB    M0031                    ;0AAB: DB 31          '.1'
;       ADCA    M0030                    ;0AAD: 99 30          '.0'
        ADDB    lo(V)                    ;0AAB: DB 31          '.1'
        ADCA    hi(V)                    ;0AAD: 99 30          '.0'
        LDAA    #$20                     ;0AAF: 86 20          '. '
        JSR     Z0E53                    ;0AB1: BD 0E 53       '..S'
        ADDB    #$46                     ;0AB4: CB 46          '.F'
        ADCA    #$13                     ;0AB6: 89 13          '..'
        JSR     Z0FCE                    ;0AB8: BD 0F CE       '...'
        JSR     Z0F09                    ;0ABB: BD 0F 09       '...'
        LDX     #SBFPTR                   ;0ABE: CE 10 81       '...'
        JSR     XPRNT                    ;0AC1: BD 0D EF       '...'
        JSR     Z0DD1                    ;0AC4: BD 0D D1       '...'
        RTS                              ;0AC7: 39             '9'
; ------------------------------------------------------------------------------

Z0AC8   CLRA                             ;0AC8: 4F             'O'
        LDAB    #$01                     ;0AC9: C6 01          '..'
;       STAB    M0033                    ;0ACB: D7 33          '.3'
;       STAA    M0032                    ;0ACD: 97 32          '.2'
        STAB    lo(K)                    ;0ACB: D7 33          '.3'
        STAA    hi(K)                    ;0ACD: 97 32          '.2'
;       LDAB    M0031                    ;0ACF: D6 31          '.1'
;       LDAA    M0030                    ;0AD1: 96 30          '.0'
        LDAB    lo(V)                    ;0ACF: D6 31          '.1'
        LDAA    hi(V)                    ;0AD1: 96 30          '.0'
        STAB    M0035                    ;0AD3: D7 35          '.5'
        STAA    M0034                    ;0AD5: 97 34          '.4'
Z0AD7   LDAB    M0057                    ;0AD7: D6 57          '.W'
        LDAA    M0056                    ;0AD9: 96 56          '.V'
        PSHB                             ;0ADB: 37             '7'
        PSHA                             ;0ADC: 36             '6'
;       LDAB    M0033                    ;0ADD: D6 33          '.3'
;       LDAA    M0032                    ;0ADF: 96 32          '.2'
        LDAB    lo(K)                    ;0ADD: D6 33          '.3'
        LDAA    hi(K)                    ;0ADF: 96 32          '.2'
        ASLB                             ;0AE1: 58             'X'
        ROLA                             ;0AE2: 49             'I'
        ADDB    #$00                     ;0AE3: CB 00          '..'
        ADCA    #$13                     ;0AE5: 89 13          '..'
        JSR     Z0FCE                    ;0AE7: BD 0F CE       '...'
        NEGA                             ;0AEA: 40             '@'
        NEGB                             ;0AEB: 50             'P'
        SBCA    #$00                     ;0AEC: 82 00          '..'
        TSX                              ;0AEE: 30             '0'
        ADDB    $01,X                    ;0AEF: EB 01          '..'
        ADCA    ,X                       ;0AF1: A9 00          '..'
        INS                              ;0AF3: 31             '1'
        INS                              ;0AF4: 31             '1'
        BNE     Z0AFD                    ;0AF5: 26 06          '&.'
        TSTB                             ;0AF7: 5D             ']'
        BNE     Z0AFD                    ;0AF8: 26 03          '&.'
        JMP     Z0B17                    ;0AFA: 7E 0B 17       '~..'
; ------------------------------------------------------------------------------

;0AFD   LDAB    M0033                    ;0AFD: D6 33          '.3'
;       LDAA    M0032                    ;0AFF: 96 32          '.2'
Z0AFD   LDAB    lo(K)                    ;0AFD: D6 33          '.3'
        LDAA    hi(K)                    ;0AFF: 96 32          '.2'
        ADDB    #$01                     ;0B01: CB 01          '..'
        ADCA    #$00                     ;0B03: 89 00          '..'
;       STAB    M0033                    ;0B05: D7 33          '.3'
;       STAA    M0032                    ;0B07: 97 32          '.2'
        STAB    lo(K)                    ;0B05: D7 33          '.3'
        STAA    hi(K)                    ;0B07: 97 32          '.2'
        SUBB    M0035                    ;0B09: D0 35          '.5'
        SBCA    M0034                    ;0B0B: 92 34          '.4'
        BLT     Z0B14                    ;0B0D: 2D 05          '-.'
        BNE     Z0B17                    ;0B0F: 26 06          '&.'
        TSTB                             ;0B11: 5D             ']'
        BNE     Z0B17                    ;0B12: 26 03          '&.'
Z0B14   JMP     Z0AD7                    ;0B14: 7E 0A D7       '~..'
; ------------------------------------------------------------------------------

Z0B17   RTS                              ;0B17: 39             '9'
; ------------------------------------------------------------------------------

Z0B18   CLRA                             ;0B18: 4F             'O'
        LDAB    #$01                     ;0B19: C6 01          '..'
;       STAB    M0033                    ;0B1B: D7 33          '.3'
;       STAA    M0032                    ;0B1D: 97 32          '.2'
        STAB    lo(K)                    ;0B1B: D7 33          '.3'
        STAA    hi(K)                    ;0B1D: 97 32          '.2'
;       LDAB    M0031                    ;0B1F: D6 31          '.1'
;       LDAA    M0030                    ;0B21: 96 30          '.0'
        LDAB    lo(V)                    ;0B1F: D6 31          '.1'
        LDAA    hi(V)                    ;0B21: 96 30          '.0'
        STAB    M0035                    ;0B23: D7 35          '.5'
        STAA    M0034                    ;0B25: 97 34          '.4'
;0B27   LDAB    M0033                    ;0B27: D6 33          '.3'
;       LDAA    M0032                    ;0B29: 96 32          '.2'
Z0B27   LDAB    lo(K)                    ;0B27: D6 33          '.3'
        LDAA    hi(K)                    ;0B29: 96 32          '.2'
        ASLB                             ;0B2B: 58             'X'
        ROLA                             ;0B2C: 49             'I'
        ADDB    #$00                     ;0B2D: CB 00          '..'
        ADCA    #$13                     ;0B2F: 89 13          '..'
        JSR     Z0FCE                    ;0B31: BD 0F CE       '...'
        SUBB    #$00                     ;0B34: C0 00          '..'
        SBCA    #$00                     ;0B36: 82 00          '..'
        BNE     Z0B40                    ;0B38: 26 06          '&.'
        TSTB                             ;0B3A: 5D             ']'
        BNE     Z0B40                    ;0B3B: 26 03          '&.'
; ------------------------------------------------------------------------------
        JMP     Z0B5A                    ;0B3D: 7E 0B 5A       '~.Z'

;0B40   LDAB    M0033                    ;0B40: D6 33          '.3'
;       LDAA    M0032                    ;0B42: 96 32          '.2'
Z0B40   LDAB    lo(K)                    ;0B40: D6 33          '.3'
        LDAA    hi(K)                    ;0B42: 96 32          '.2'
        ADDB    #$01                     ;0B44: CB 01          '..'
        ADCA    #$00                     ;0B46: 89 00          '..'
;       STAB    M0033                    ;0B48: D7 33          '.3'
;       STAA    M0032                    ;0B4A: 97 32          '.2'
        STAB    lo(K)                    ;0B48: D7 33          '.3'
        STAA    hi(K)                    ;0B4A: 97 32          '.2'
        SUBB    M0035                    ;0B4C: D0 35          '.5'
        SBCA    M0034                    ;0B4E: 92 34          '.4'
        BLT     Z0B57                    ;0B50: 2D 05          '-.'
        BNE     Z0B5A                    ;0B52: 26 06          '&.'
        TSTB                             ;0B54: 5D             ']'
        BNE     Z0B5A                    ;0B55: 26 03          '&.'
Z0B57   JMP     Z0B27                    ;0B57: 7E 0B 27       '~.''
; ------------------------------------------------------------------------------

Z0B5A   RTS                              ;0B5A: 39             '9'
; ------------------------------------------------------------------------------

Z0B5B   BRA     Z0B5F                    ;0B5B: 20 02          ' .'
M0B5D   BGE     Z0B5F                    ;0B5D: 2C 00          ',.'
Z0B5F   LDX     #M0B5D                   ;0B5F: CE 0B 5D       '..]'
        LDAA    #hi(SBFPTR)              ;0B62: 86 10          '..'
        LDAB    #lo(SBFPTR)              ;0B64: C6 81          '..'
        STAB    STRPTR+1                 ;0B66: D7 28          '.('
        STAA    STRPTR                   ;0B68: 97 27          '.''
        JSR     Z0F00                    ;0B6A: BD 0F 00       '...'
        JSR     Z0F2A                    ;0B6D: BD 0F 2A       '..*'
        LDX     STRPTR                   ;0B70: DE 27          '.''
        STX     XSAVE                    ;0B72: DF 20          '. '
        ;;
        ;; L (16b, on the stack)
        ;; 
        DES                              ;0B74: 34             '4'
        DES                              ;0B75: 34             '4'
        JSR     Z0E68                    ;0B76: BD 0E 68       '..h'
;       LDX     #M1000                   ;0B79: CE 10 00       '...'
        LDX     #BUF                     ;0B79: CE 10 00       '...'
        JSR     Z0F00                    ;0B7C: BD 0F 00       '...'
        CLRA                             ;0B7F: 4F             'O'
        LDAB    #$03                     ;0B80: C6 03          '..'
        PSHB                             ;0B82: 37             '7'
        CLRA                             ;0B83: 4F             'O'
        LDAB    #$05                     ;0B84: C6 05          '..'
        PULA                             ;0B86: 32             '2'
        JSR     Z0ECA                    ;0B87: BD 0E CA       '...' njc
        LDX     #SBFPTR                  ;0B8A: CE 10 81       '...'
        JSR     Z0F30                    ;0B8D: BD 0F 30       '..0'
        STAB    M0071                    ;0B90: D7 71          '.q'
        STAA    M0070                    ;0B92: 97 70          '.p'
        LDAA    #$10                     ;0B94: 86 10          '..'
        LDAB    #$81                     ;0B96: C6 81          '..'
        STAB    STRPTR+1                 ;0B98: D7 28          '.('
        STAA    STRPTR                   ;0B9A: 97 27          '.''
        DES                              ;0B9C: 34             '4'
        DES                              ;0B9D: 34             '4'
        JSR     Z0E68                    ;0B9E: BD 0E 68       '..h'
;       LDX     #M1000                   ;0BA1: CE 10 00       '...'
        LDX     #BUF                     ;0BA1: CE 10 00       '...'
        JSR     Z0F00                    ;0BA4: BD 0F 00       '...'
        CLRA                             ;0BA7: 4F             'O'
        LDAB    #$03                     ;0BA8: C6 03          '..'
        PSHB                             ;0BAA: 37             '7'
        CLRA                             ;0BAB: 4F             'O'
        LDAB    #$04                     ;0BAC: C6 04          '..'
        PULA                             ;0BAE: 32             '2'
        JSR     Z0ECA                    ;0BAF: BD 0E CA       '...'
        LDX     #SBFPTR                  ;0BB2: CE 10 81       '...'
        JSR     Z0FA7                    ;0BB5: BD 0F A7       '...'
        STAB    M005B                    ;0BB8: D7 5B          '.['
        STAA    M005A                    ;0BBA: 97 5A          '.Z'
        LDAA    #$10                     ;0BBC: 86 10          '..'
        LDAB    #$81                     ;0BBE: C6 81          '..'
        STAB    STRPTR+1                    ;0BC0: D7 28          '.('
        STAA    STRPTR                    ;0BC2: 97 27          '.''
        DES                              ;0BC4: 34             '4'
        DES                              ;0BC5: 34             '4'
        JSR     Z0E68                    ;0BC6: BD 0E 68       '..h'
;       LDX     #M1000                   ;0BC9: CE 10 00       '...'
        LDX     #BUF                     ;0BC9: CE 10 00       '...'
        JSR     Z0F00                    ;0BCC: BD 0F 00       '...'
        LDAB    M0071                    ;0BCF: D6 71          '.q'
        LDAA    M0070                    ;0BD1: 96 70          '.p'
        ADDB    #$03                     ;0BD3: CB 03          '..'
        ADCA    #$00                     ;0BD5: 89 00          '..'
        PSHB                             ;0BD7: 37             '7'
        CLRA                             ;0BD8: 4F             'O'
        LDAB    #$04                     ;0BD9: C6 04          '..'
        PULA                             ;0BDB: 32             '2'
        JSR     Z0ECA                    ;0BDC: BD 0E CA       '...'
        LDX     #SBFPTR                   ;0BDF: CE 10 81       '...'
        JSR     Z0FA7                    ;0BE2: BD 0F A7       '...'
        STAB    M005F                    ;0BE5: D7 5F          '._'
        STAA    M005E                    ;0BE7: 97 5E          '.^'
        RTS                              ;0BE9: 39             '9'
; ------------------------------------------------------------------------------
;*
;* How much room in the line?
;*
LN6500
Z0BEA   CLRA                             ;0BEA: 4F             'O'
        CLRB                             ;0BEB: 5F             '_'
;       STAB    M0059                    ;0BEC: D7 59          '.Y'
;       STAA    M0058                    ;0BEE: 97 58          '.X'
        STAB    lo(X)                    ;0BEC: D7 59          '.Y'
        STAA    hi(X)                    ;0BEE: 97 58          '.X'
        CLRA                             ;0BF0: 4F             'O'
        LDAB    #$01                     ;0BF1: C6 01          '..'
;       STAB    M0033                    ;0BF3: D7 33          '.3'
;       STAA    M0032                    ;0BF5: 97 32          '.2'
        STAB    lo(K)                    ;0BF3: D7 33          '.3'
        STAA    hi(K)                    ;0BF5: 97 32          '.2'
;       LDAB    M0031                    ;0BF7: D6 31          '.1'
;       LDAA    M0030                    ;0BF9: 96 30          '.0'
        LDAB    lo(V)                    ;0BF7: D6 31          '.1'
        LDAA    hi(V)                    ;0BF9: 96 30          '.0'
        STAB    M0035                    ;0BFB: D7 35          '.5'
        STAA    M0034                    ;0BFD: 97 34          '.4'
;0BFF   LDAB    M0033                    ;0BFF: D6 33          '.3'
;       LDAA    M0032                    ;0C01: 96 32          '.2'
Z0BFF   LDAB    lo(K)                    ;0BFF: D6 33          '.3'
        LDAA    hi(K)                    ;0C01: 96 32          '.2'
        ;;
        ;; ???
        ;; 
        ASLB                             ;0C03: 58             'X'
        ROLA                             ;0C04: 49             'I'
        ;;
        ;; $1300 = ??? N(50)? Probably
        ;; 
        ADDB    #$00                     ;0C05: CB 00          '..'
        ADCA    #$13                     ;0C07: 89 13          '..'
        JSR     Z0FCE                    ;0C09: BD 0F CE       '...'
        SUBB    #$00                     ;0C0C: C0 00          '..'
        SBCA    #$00                     ;0C0E: 82 00          '..'
        BNE     Z0C18                    ;0C10: 26 06          '&.'
        TSTB                             ;0C12: 5D             ']'
        BNE     Z0C18                    ;0C13: 26 03          '&.'
        JSR     Z0C33                    ;0C15: BD 0C 33       '..3'
        ;;
        ;;  N(K) = something
        ;; 
;0C18   LDAB    M0033                    ;0C18: D6 33          '.3'
;       LDAA    M0032                    ;0C1A: 96 32          '.2'
Z0C18   LDAB    lo(K)                    ;0C18: D6 33          '.3'
        LDAA    hi(K)                    ;0C1A: 96 32          '.2'
        ADDB    #$01                     ;0C1C: CB 01          '..'
        ADCA    #$00                     ;0C1E: 89 00          '..'
;       STAB    M0033                    ;0C20: D7 33          '.3'
;       STAA    M0032                    ;0C22: 97 32          '.2'
        STAB    lo(K)                    ;0C20: D7 33          '.3'
        STAA    hi(K)                    ;0C22: 97 32          '.2'
        SUBB    M0035                    ;0C24: D0 35          '.5'
        SBCA    M0034                    ;0C26: 92 34          '.4'
;       BLT     Z0C2F                    ;0C28: 2D 05          '-.'
        BLT     NXT_K                    ;0C28: 2D 05          '-.'
        ;;
        ;; Return
        ;; 
        BNE     Z0C32                    ;0C2A: 26 06          '&.'
        TSTB                             ;0C2C: 5D             ']'
        ;;
        ;;  Return
        ;; 
        BNE     Z0C32                    ;0C2D: 26 03          '&.'
        ;;
        ;;  Next K, don't which line yet
        ;;
NXT_K
Z0C2F   JMP     Z0BFF                    ;0C2F: 7E 0B FF       '~..'
; ------------------------------------------------------------------------------
        ;;
        ;; Return
        ;; 
Z0C32   RTS                              ;0C32: 39             '9'
; ------------------------------------------------------------------------------

;0C33   LDAB    M0059                    ;0C33: D6 59          '.Y'
;       LDAA    M0058                    ;0C35: 96 58          '.X'
Z0C33   LDAB    lo(X)                    ;0C33: D6 59          '.Y'
        LDAA    hi(X)                    ;0C35: 96 58          '.X'
        ADDB    #$01                     ;0C37: CB 01          '..'
        ADCA    #$00                     ;0C39: 89 00          '..'
;       STAB    M0059                    ;0C3B: D7 59          '.Y'
;       STAA    M0058                    ;0C3D: 97 58          '.X'
        STAB    lo(X)                    ;0C3B: D7 59          '.Y'
        STAA    hi(X)                    ;0C3D: 97 58          '.X'
        RTS                              ;0C3F: 39             '9'
; ------------------------------------------------------------------------------
;* X=LEN(BUF$): RETURN
LN7000
;0C40   LDX     #M1000                   ;0C40: CE 10 00       '...'
Z0C40   LDX     #BUF                     ;0C40: CE 10 00       '...'
;       LDAA    #$10                     ;0C43: 86 10          '..'
;       LDAB    #$81                     ;0C45: C6 81          '..'
        LDAA    #hi(SBFPTR)              ;0C43: 86 10          '..'
        LDAB    #lo(SBFPTR)              ;0C45: C6 81          '..'
        STAB    STRPTR+1                 ;0C47: D7 28          '.('
        STAA    STRPTR                   ;0C49: 97 27          '.''
        JSR     Z0F00                    ;0C4B: BD 0F 00       '...'
        LDX     #SBFPTR                  ;0C4E: CE 10 81       '...'
        JSR     Z0E7A                    ;0C51: BD 0E 7A       '..z'
;       STAB    M0059                    ;0C54: D7 59          '.Y'
;       STAA    M0058                    ;0C56: 97 58          '.X'
        STAB    lo(X)                    ;0C54: D7 59          '.Y'
        STAA    hi(X)                    ;0C56: 97 58          '.X'
        RTS                              ;0C58: 39             '9'
; ------------------------------------------------------------------------------

Z0C59   CLRA                             ;0C59: 4F             'O'
        PSHA                             ;0C5A: 36             '6'
        PSHA                             ;0C5B: 36             '6'
        PSHA                             ;0C5C: 36             '6'
        PSHA                             ;0C5D: 36             '6'
        LDAA    #$05                     ;0C5E: 86 05          '..'
        PSHA                             ;0C60: 36             '6'
        TSX                              ;0C61: 30             '0'
Z0C62   BSR     Z0CD3                    ;0C62: 8D 6F          '.o'
        CMPA    #$20                     ;0C64: 81 20          '. ' SPACE?
        BEQ     Z0C62                    ;0C66: 27 FA          ''.'
        CMPA    #$2D                     ;0C68: 81 2D          '.-' DASH? '-'
        BNE     Z0C7A                    ;0C6A: 26 0E          '&.'
        INC     $04,X                    ;0C6C: 6C 04          'l.'
Z0C6E   BSR     Z0CD3                    ;0C6E: 8D 63          '.c'
        BCC     Z0CA8                    ;0C70: 24 36          '$6'
        CMPA    #$20                     ;0C72: 81 20          '. ' SPACE?
        BEQ     Z0CA8                    ;0C74: 27 32          ''2'
        TST     ,X                       ;0C76: 6D 00          'm.'
        BEQ     Z0CBB                    ;0C78: 27 41          ''A'
Z0C7A   SUBA    #$30                     ;0C7A: 80 30          '.0'
        BCS     Z0CBB                    ;0C7C: 25 3D          '%='
        CMPA    #$09                     ;0C7E: 81 09          '..'
        BHI     Z0CBB                    ;0C80: 22 39          '"9'
        STAA    $01,X                    ;0C82: A7 01          '..'
        LDAA    $02,X                    ;0C84: A6 02          '..'
        LDAB    $03,X                    ;0C86: E6 03          '..'
        ASLB                             ;0C88: 58             'X'
        ROLA                             ;0C89: 49             'I'
        STAA    $02,X                    ;0C8A: A7 02          '..'
        STAB    $03,X                    ;0C8C: E7 03          '..'
        ASLB                             ;0C8E: 58             'X'
        ROLA                             ;0C8F: 49             'I'
        ASLB                             ;0C90: 58             'X'
        ROLA                             ;0C91: 49             'I'
        BCS     Z0CBB                    ;0C92: 25 27          '%''
        ADDB    $03,X                    ;0C94: EB 03          '..'
        ADCA    $02,X                    ;0C96: A9 02          '..'
        BCS     Z0CBB                    ;0C98: 25 21          '%!'
        ADDB    $01,X                    ;0C9A: EB 01          '..'
        ADCA    #$00                     ;0C9C: 89 00          '..'
        BCS     Z0CBB                    ;0C9E: 25 1B          '%.'
        STAA    $02,X                    ;0CA0: A7 02          '..'
        STAB    $03,X                    ;0CA2: E7 03          '..'
        DEC     ,X                       ;0CA4: 6A 00          'j.'
        BRA     Z0C6E                    ;0CA6: 20 C6          ' .'
Z0CA8   PULA                             ;0CA8: 32             '2'
        CMPA    #$05                     ;0CA9: 81 05          '..'
        BEQ     Z0CBC                    ;0CAB: 27 0F          ''.'
        INS                              ;0CAD: 31             '1'
        PULA                             ;0CAE: 32             '2'
        PULB                             ;0CAF: 33             '3'
        TST     $04,X                    ;0CB0: 6D 04          'm.'
        BEQ     Z0CB8                    ;0CB2: 27 04          ''.'
        NEGA                             ;0CB4: 40             '@'
        NEGB                             ;0CB5: 50             'P'
        SBCA    #$00                     ;0CB6: 82 00          '..'
Z0CB8   INS                              ;0CB8: 31             '1'
        CLC                              ;0CB9: 0C             '.'
        RTS                              ;0CBA: 39             '9'
; ------------------------------------------------------------------------------

Z0CBB   INS                              ;0CBB: 31             '1'
Z0CBC   INS                              ;0CBC: 31             '1'
        INS                              ;0CBD: 31             '1'
        INS                              ;0CBE: 31             '1'
        INS                              ;0CBF: 31             '1'
        CLRA                             ;0CC0: 4F             'O'
        CLRB                             ;0CC1: 5F             '_'
        SEC                              ;0CC2: 0D             '.'
        RTS                              ;0CC3: 39             '9'
; ------------------------------------------------------------------------------
;* Unreachable code
        LDAB    #$20                     ;0CC4: C6 20          '. '
; ------------------------------------------------------------------------------

Z0CC6   BSR     Z0CD3                    ;0CC6: 8D 0B          '..'
        BCC     Z0CD0                    ;0CC8: 24 06          '$.'
        STAA    ,X                       ;0CCA: A7 00          '..'
        INX                              ;0CCC: 08             '.'
        DECB                             ;0CCD: 5A             'Z'
        BNE     Z0CC6                    ;0CCE: 26 F6          '&.'
Z0CD0   CLR     ,X                       ;0CD0: 6F 00          'o.'
        RTS                              ;0CD2: 39             '9'
; ------------------------------------------------------------------------------

Z0CD3   STX     XSAVE                    ;0CD3: DF 20          '. '
        LDX     BUFPTR                   ;0CD5: DE 22          '."'
        LDAA    ,X                       ;0CD7: A6 00          '..'
        BEQ     Z0CE4                    ;0CD9: 27 09          ''.'
        CMPA    #COMMA                   ;0CDB: 81 2C          '.,'
        BEQ     Z0CE3                    ;0CDD: 27 04          ''.'
        BSR     Z0CE3                    ;0CDF: 8D 02          '..'
        SEC                              ;0CE1: 0D             '.'
        RTS                              ;0CE2: 39             '9'
; ------------------------------------------------------------------------------

Z0CE3   INX                              ;0CE3: 08             '.'
Z0CE4   STX     BUFPTR                   ;0CE4: DF 22          '."'
        LDX     XSAVE                    ;0CE6: DE 20          '. '
        CLC                              ;0CE8: 0C             '.'
        RTS                              ;0CE9: 39             '9'
; ------------------------------------------------------------------------------
;* BUF$ is in X
;*
;* TREAD doesn't care about how many NULLs, it waits for STX (^B)
;* then reads until it gets a ETX (^C)
;*
TREAD
Z0CEA   LDAA    #DC1                     ;0CEA: 86 11          '..'
        LDAB    #$3C                     ;0CEC: C6 3C          '.<'
        BSR     Z0D0D                    ;0CEE: 8D 1D          '..'
Z0CF0   JSR     IN1CHR                   ;0CF0: BD E3 50       '..P'
	;;
        ;;  Wait for an STX ($02)
        ;; 
        CMPA    #STX                     ;0CF3: 81 02          '..'
        BNE     Z0CF0                    ;0CF5: 26 F9          '&.'
        CLRB                             ;0CF7: 5F             '_'
Z0CF8   JSR     IN1CHR                   ;0CF8: BD E3 50       '..P'
        ;;
        ;; ETX ends the line($02)
        ;; 
        CMPA    #ETX                     ;0CFB: 81 03          '..'
        BEQ     Z0D07                    ;0CFD: 27 08          ''.'
        STAA    ,X                       ;0CFF: A7 00          '..'
        INX                              ;0D01: 08             '.'
        INCB                             ;0D02: 5C             '\'
        ;;
        ;;  RECLEN = $80 (128)
        ;; 
        CMPB    #$80                     ;0D03: C1 80          '..'
        BCS     Z0CF8                    ;0D05: 25 F1          '%.'
        ;;
        ;; 
Z0D07   CLR     ,X                       ;0D07: 6F 00          'o.'
        LDAA    #DC3                     ;0D09: 86 13          '..'
        LDAB    #$34                     ;0D0B: C6 34          '.4'
Z0D0D   JSR     OUT1CH                   ;0D0D: BD E3 A6       '...'
        STAB    PIACB                    ;0D10: F7 80 07       '...'
        RTS                              ;0D13: 39             '9'
; ------------------------------------------------------------------------------
;*
;* INPUT - Prints a '?' and a space reads characters until 128 bytes have been
;* read or a <CR> is read. (128 bytes doesn't seem to work). Entry of a CTRL-X
;* will print ' *DEL*' & a CR/LF and reset the buffer. Entry of a CTRL-O will
;* backspace the buffer and echo the delted characters.
;*
INPUT
PRPRMT
Z0D14   LDAA    #PROMPT                  ;0D14: 86 3F          '.?'
        JSR     OUT1CH                   ;0D16: BD E3 A6       '...'
        JSR     PRSPC                    ;0D19: BD E0 CC       '...'
Z0D1C   STX     BUFPTR                   ;0D1C: DF 22          '."'
        STX     BUFBEG                   ;0D1E: DF 24          '.$'
        LDAB    #$80                     ;0D20: C6 80          '..'
;*
;*
;* Line Editing?
;*
;* CTRL-X before the <CR> will delete the current input line
;* CTRL-O before the <CR> will delete character by chracter
;*
Z0D22   JSR     IN1CHR                   ;0D22: BD E3 50       '..P'
        CMPA    #CTRLO                   ;0D25: 81 0F          '..'
        BNE     Z0D35                    ;0D27: 26 0C          '&.'
        CPX     BUFBEG                   ;0D29: 9C 24          '.$'
        BEQ     Z0D39                    ;0D2B: 27 0C          ''.'
        DEX                              ;0D2D: 09             '.'
        LDAA    ,X                       ;0D2E: A6 00          '..'
        JSR     OUT1CH                   ;0D30: BD E3 A6       '...'
        BRA     Z0D22                    ;0D33: 20 ED          ' .'
; ------------------------------------------------------------------------------
;
Z0D35   CMPA    #CTRLX                   ;0D35: 81 18          '..'
        BNE     Z0D50                    ;0D37: 26 17          '&.'
Z0D39   ;CB     $8D,$07                  ;* 0D39: 8D 07          '..'
        BSR     Z0D42                    ;* NJC added ($8D = BSR)
; ------------------------------------------------------------------------------
;
; This is very messed up @FIXME:
;
; ------------------------------------------------------------------------------
;**
;** This BRA .+$2A jumps into the middle of a BRA inst @ $0D64
;**    BRA   Z0D22 ; 0D64 20 BC where BC =  CPX
;**    LDAA  #$20  ; 0D65                   CPX  8620
;**
;       BRA     .+$2A                    ;* 0D3B: 20 2A @FIXME (.+$2A ???)
;       FCB     $20, $2A                 ;
;       BRA     Z0D67
; .+2A is mid BRA @ Z0D67
;
; This is very messed up @FIXME:
;
; ------------------------------------------------------------------------------
        FCC     " *DEL*\4"                    ;* 0D3D: 44 45 4C 'DEL'
;
;        BPL     Z0D46                    ;* 0D40: 2A 04    '*\4'
; ------------------------------------------------------------------------------
Z0D42   TSX                              ;0D42: 30             '0'
        LDX     ,X                       ;0D43: EE 00          '..'
Z0D45   INS                              ;0D45: 31             '1'
Z0D46   INS                              ;0D46: 31             '1'
        JSR     PRSTR                    ;0D47: BD E0 7E       '..~'
        BSR     Z0D58                    ;0D4A: 8D 0C          '..'
        LDX     BUFBEG                   ;0D4C: DE 24          '.$'
        BRA     Z0D1C                    ;0D4E: 20 CC          ' .'
;*
;*  Continue CLI
;*
Z0D50   STAA    ,X                       ;0D50: A7 00          '..'
        CMPA    #NL                      ;0D52: 81 0D          '..'
        BNE     Z0D5F                    ;0D54: 26 09          '&.'
        CLR     ,X                       ;0D56: 6F 00          'o.'
;*
;* Print CR/LF
;*
Z0D58   LDAA    #$01                     ;0D58: 86 01          '..'
        STAA    CHRCNT                   ;0D5A: 97 26          '.&'
        JMP     PCRLF                    ;0D5C: 7E E1 41       '~.A'
; ------------------------------------------------------------------------------
;*
;*
;*
Z0D5F   TSTB                             ;0D5F: 5D             ']'
ZD060   BEQ     Z0D22                    ;0D60: 27 C0          ''.'
        INX                              ;0D62: 08             '.'
        DECB                             ;0D63: 5A             'Z'
        BRA     Z0D22                    ;0D64: 20 BC          ' .'
; BC = 
Z0D67   equ     $0D67                    ;
Z0D66   LDAA    #$20                     ;0D66: 86 20          '. '
Z0D68   STX     XSAVE                    ;0D68: DF 20          '. '
        LDX     BUFPTR                    ;0D6A: DE 22          '."'
        STAA    ,X                       ;0D6C: A7 00          '..'
        LDAA    CHRCNT                   ;0D6E: 96 26          '.&'
        CMPA    #$80                     ;0D70: 81 80          '..'
        BHI     Z0D76                    ;0D72: 22 02          '".'
        INCA                             ;0D74: 4C             'L'
        INX                              ;0D75: 08             '.'
Z0D76   CLR     ,X                       ;0D76: 6F 00          'o.'
        STAA    CHRCNT                   ;0D78: 97 26          '.&'
        STX     BUFPTR                    ;0D7A: DF 22          '."'
        LDX     XSAVE                    ;0D7C: DE 20          '. '
        RTS                              ;0D7E: 39             '9'
; ------------------------------------------------------------------------------

Z0D7F   STX     BUFBEG                    ;0D7F: DF 24          '.$'
        BRA     Z0D87                    ;0D81: 20 04          ' .'
Z0D83   LDAA    #$01                     ;0D83: 86 01          '..'
        STAA    CHRCNT                   ;0D85: 97 26          '.&'
Z0D87   LDX     BUFBEG                    ;0D87: DE 24          '.$'
        STX     BUFPTR                    ;0D89: DF 22          '."'
        RTS                              ;0D8B: 39             '9'
; ------------------------------------------------------------------------------

Z0D8C   BSR     Z0D66                    ;0D8C: 8D D8          '..'
        LDAA    CHRCNT                   ;0D8E: 96 26          '.&'
        ANDA    #$07                     ;0D90: 84 07          '..'
        CMPA    #$01                     ;0D92: 81 01          '..'
        BNE     Z0D8C                    ;0D94: 26 F6          '&.'
        RTS                              ;0D96: 39             '9'
; ------------------------------------------------------------------------------

Z0D97   BSR     Z0D87                    ;0D97: 8D EE          '..'
Z0D99   LDAA    ,X                       ;0D99: A6 00          '..'
        ;;
        ;; Don't write out those NULLs
        ;; 
        BEQ     Z0DA8                    ;0D9B: 27 0B          ''.'
        BSR     Z0DCE                    ;0D9D: 8D 2F          './'
        INX                              ;0D9F: 08             '.'
        BRA     Z0D99                    ;0DA0: 20 F7          ' .'
Z0DA2   BSR     Z0D66                    ;0DA2: 8D C2          '..'
        CMPB    CHRCNT                   ;0DA4: D1 26          '.&'
        BHI     Z0DA2                    ;0DA6: 22 FA          '".'
Z0DA8   RTS                              ;0DA8: 39             '9'
; ------------------------------------------------------------------------------

Z0DA9   BRA     Z0D68                    ;0DA9: 20 BD          ' .'

; ------------------------------------------------------------------------------
;*
;* X->BUFBEG
;* X->BUFPTR
;*
;* Just a guess, TWRITE
TWRITE
Z0DAB   LDAA    #DC2                     ;0DAB: 86 12          '..' ^R
        LDAB    #$3C                     ;0DAD: C6 3C          '.<'
        BSR     Z0DC7                    ;0DAF: 8D 16          '..'
        ;;
        ;; Send out 90 NULLS
        ;;
        LDAB    #$5A                     ;0DB1: C6 5A          '.Z' 90
Z0DB3   CLRA                             ;0DB3: 4F             'O'
        BSR     OUTEEE                   ;0DB4: 8D 18          '..'
        DECB                             ;0DB6: 5A             'Z'
        BNE     Z0DB3                    ;0DB7: 26 FA          '&.'
        LDAA    #STX                     ;0DB9: 86 02          '..' ^B
        ;;
        ;; No NULLs sent here
        ;; 
        BSR     OUTEEE                   ;0DBB: 8D 11          '..'
        BSR     Z0D97                    ;0DBD: 8D D8          '..'
        LDAA    #ETX                     ;0DBF: 86 03          '..' ^C
        BSR     OUTEEE                   ;0DC1: 8D 0B          '..'
        LDAA    #DC4                     ;0DC3: 86 14          '..' ^T
        LDAB    #$34                     ;0DC5: C6 34          '.4' 
Z0DC7   STAB    PIACB                    ;0DC7: F7 80 07       '...'
        BSR     OUTEEE                   ;0DCA: 8D 02          '..'
        NOP                              ;0DCC: 01             '.'
        RTS                              ;0DCD: 39             '9'
; ------------------------------------------------------------------------------
;*
OUTEEE                                   ; OUTEEE ?
Z0DCE   JMP     OUT1CH                   ;0DCE: 7E E3 A6       '~..'

Z0DD1   BSR     Z0D97                    ;0DD1: 8D C4          '..'
Z0DD3   BSR     Z0D83                    ;0DD3: 8D AE          '..'
        JMP     PCRLF                    ;0DD5: 7E E1 41       '~.A'
; ------------------------------------------------------------------------------
;*
Z0DD8   PSHA                             ;0DD8: 36             '6'
        LDAA    ,X                       ;0DD9: A6 00          '..'
        BNE     Z0DE1                    ;0DDB: 26 04          '&.'
        TST     $01,X                    ;0DDD: 6D 01          'm.'
        BEQ     Z0DE7                    ;0DDF: 27 06          ''.'
Z0DE1   ORAA    #$30                     ;0DE1: 8A 30          '.0'
        BSR     Z0D68                    ;0DE3: 8D 83          '..'
        INC     $01,X                    ;0DE5: 6C 01          'l.'
Z0DE7   CLR     ,X                       ;0DE7: 6F 00          'o.'
        PULA                             ;0DE9: 32             '2'
        RTS                              ;0DEA: 39             '9'
; ------------------------------------------------------------------------------
;* Unreachable code
        LDAB    #$20                     ;0DEB: C6 20          '. '
        BRA     Z0DF1                    ;0DED: 20 02          ' .'
; ------------------------------------------------------------------------------
;* PRINT the string pointed to by X
;* the string should be terminate with a null
;* or be less than equal to 80
XPRNT
Z0DEF   LDAB    #$80                     ;0DEF: C6 80          '..'
Z0DF1   LDAA    ,X                       ;0DF1: A6 00          '..'
        BEQ     Z0DFB                    ;0DF3: 27 06          ''.'
        BSR     Z0DA9                    ;0DF5: 8D B2          '..'
        INX                              ;0DF7: 08             '.'
        DECB                             ;0DF8: 5A             'Z'
        BNE     Z0DF1                    ;0DF9: 26 F6          '&.'
Z0DFB   RTS                              ;0DFB: 39             '9'
; ------------------------------------------------------------------------------

Z0DFC   TSTA                             ;0DFC: 4D             'M'
        BPL     Z0E09                    ;0DFD: 2A 0A          '*.'
        PSHA                             ;0DFF: 36             '6'
        LDAA    #$2D                     ;0E00: 86 2D          '.-'
        BSR     Z0DA9                    ;0E02: 8D A5          '..'
        PULA                             ;0E04: 32             '2'
        NEGA                             ;0E05: 40             '@'
        NEGB                             ;0E06: 50             'P'
        SBCA    #$00                     ;0E07: 82 00          '..'
Z0E09   DES                              ;0E09: 34             '4'
        DES                              ;0E0A: 34             '4'
        TSX                              ;0E0B: 30             '0'
        CLR     ,X                       ;0E0C: 6F 00          'o.'
        CLR     $01,X                    ;0E0E: 6F 01          'o.'
Z0E10   SUBB    #$10                     ;0E10: C0 10          '..'
        SBCA    #$27                     ;0E12: 82 27          '.''
        BCS     Z0E1A                    ;0E14: 25 04          '%.'
        INC     ,X                       ;0E16: 6C 00          'l.'
        BRA     Z0E10                    ;0E18: 20 F6          ' .'
Z0E1A   ADDB    #$10                     ;0E1A: CB 10          '..'
        ADCA    #$27                     ;0E1C: 89 27          '.''
        BSR     Z0DD8                    ;0E1E: 8D B8          '..'
Z0E20   SUBB    #$E8                     ;0E20: C0 E8          '..'
        SBCA    #$03                     ;0E22: 82 03          '..'
        BCS     Z0E2A                    ;0E24: 25 04          '%.'
        INC     ,X                       ;0E26: 6C 00          'l.'
        BRA     Z0E20                    ;0E28: 20 F6          ' .'
Z0E2A   ADDB    #$E8                     ;0E2A: CB E8          '..'
        ADCA    #$03                     ;0E2C: 89 03          '..'
        BSR     Z0DD8                    ;0E2E: 8D A8          '..'
        ;; 
Z0E30   SUBB    #$64                     ;0E30: C0 64          '.d'
        SBCA    #$00                     ;0E32: 82 00          '..'
        BCS     Z0E3A                    ;0E34: 25 04          '%.'
        INC     ,X                       ;0E36: 6C 00          'l.'
        BRA     Z0E30                    ;0E38: 20 F6          ' .'
        ;; 
Z0E3A   ADDB    #$64                     ;0E3A: CB 64          '.d'
        BSR     Z0DD8                    ;0E3C: 8D 9A          '..'
Z0E3E   SUBB    #$0A                     ;0E3E: C0 0A          '..'
        BCS     Z0E46                    ;0E40: 25 04          '%.'
        INC     ,X                       ;0E42: 6C 00          'l.'
        BRA     Z0E3E                    ;0E44: 20 F8          ' .'
        ;; 
Z0E46   ADDB    #$0A                     ;0E46: CB 0A          '..'
        BSR     Z0DD8                    ;0E48: 8D 8E          '..'
        STAB    ,X                       ;0E4A: E7 00          '..'
        INC     $01,X                    ;0E4C: 6C 01          'l.'
        BSR     Z0DD8                    ;0E4E: 8D 88          '..'
        INS                              ;0E50: 31             '1'
        INS                              ;0E51: 31             '1'
        RTS                              ;0E52: 39             '9'
; ------------------------------------------------------------------------------

Z0E53   PSHB                             ;0E53: 37             '7'
        LDAB    #$08                     ;0E54: C6 08          '..'
        PSHB                             ;0E56: 37             '7'
        TSX                              ;0E57: 30             '0'
        CLRB                             ;0E58: 5F             '_'
Z0E59   ASLB                             ;0E59: 58             'X'
        ROLA                             ;0E5A: 49             'I'
        BCC     Z0E61                    ;0E5B: 24 04          '$.'
        ADDB    $01,X                    ;0E5D: EB 01          '..'
        ADCA    #$00                     ;0E5F: 89 00          '..'
Z0E61   DEC     ,X                       ;0E61: 6A 00          'j.'
        BNE     Z0E59                    ;0E63: 26 F4          '&.'
        INS                              ;0E65: 31             '1'
        INS                              ;0E66: 31             '1'
        RTS                              ;0E67: 39             '9'
; ------------------------------------------------------------------------------

Z0E68   LDX     STRPTR                    ;0E68: DE 27          '.''
        STX     STRSAV                    ;0E6A: DF 29          '.)'
        TSX                              ;0E6C: 30             '0'
        LDAA    STRSAV                    ;0E6D: 96 29          '.)'
        STAA    $02,X                    ;0E6F: A7 02          '..'
        LDAA    M002A                    ;0E71: 96 2A          '.*'
        STAA    $03,X                    ;0E73: A7 03          '..'
        RTS                              ;0E75: 39             '9'
; ------------------------------------------------------------------------------
;* Unreachable code
        TSX                              ;0E76: 30             '0'
        LDX     $02,X                    ;0E77: EE 02          '..'
        RTS                              ;0E79: 39             '9'
; ------------------------------------------------------------------------------

Z0E7A   CLRB                             ;0E7A: 5F             '_'
Z0E7B   TST     ,X                       ;0E7B: 6D 00          'm.'
        BEQ     Z0E83                    ;0E7D: 27 04          ''.'
        INX                              ;0E7F: 08             '.'
        INCB                             ;0E80: 5C             '\'
        BRA     Z0E7B                    ;0E81: 20 F8          ' .'
Z0E83   CLRA                             ;0E83: 4F             'O'
        RTS                              ;0E84: 39             '9'
; ------------------------------------------------------------------------------
;* Unreachable code
        TSX                              ;0E85: 30             '0'
        LDX     $02,X                    ;0E86: EE 02          '..'
        BSR     Z0E7A                    ;0E88: 8D F0          '..'
; ------------------------------------------------------------------------------

Z0E8A   TSTB                             ;0E8A: 5D             ']'
        BEQ     Z0EF3                    ;0E8B: 27 66          ''f'
        DEX                              ;0E8D: 09             '.'
        LDAA    ,X                       ;0E8E: A6 00          '..'
        CMPA    #$20                     ;0E90: 81 20          '. '
        BNE     Z0EF3                    ;0E92: 26 5F          '&_'
        CLR     ,X                       ;0E94: 6F 00          'o.'
        DECB                             ;0E96: 5A             'Z'
        BRA     Z0E8A                    ;0E97: 20 F1          ' .'
Z0E99   LDAB    #$80                     ;0E99: C6 80          '..'
        BSR     Z0EA2                    ;0E9B: 8D 05          '..'
        CLR     ,X                       ;0E9D: 6F 00          'o.'
        RTS                              ;0E9F: 39             '9'
; ------------------------------------------------------------------------------
; A string element has 32 bytes
Z0EA0   LDAB    #$20                     ;0EA0: C6 20          '. '
Z0EA2   STX     STRSAV                    ;0EA2: DF 29          '.)'
        LDX     STRPTR                    ;0EA4: DE 27          '.''
        LDAA    ,X                       ;0EA6: A6 00          '..'
        INX                              ;0EA8: 08             '.'
        STX     STRPTR                    ;0EA9: DF 27          '.''
        LDX     STRSAV                    ;0EAB: DE 29          '.)'
        STAA    ,X                       ;0EAD: A7 00          '..'
        BEQ     Z0EB5                    ;0EAF: 27 04          ''.'
        INX                              ;0EB1: 08             '.'
        DECB                             ;0EB2: 5A             'Z'
        BNE     Z0EA2                    ;0EB3: 26 ED          '&.'
Z0EB5   RTS                              ;0EB5: 39             '9'
; ------------------------------------------------------------------------------
;* Unreachable code
        TSX                              ;0EB6: 30             '0'
        LDX     $02,X                    ;0EB7: EE 02          '..'
        STX     STRPTR                   ;0EB9: DF 27          '.''
        PSHB                             ;0EBB: 37             '7'
        BSR     Z0E7A                    ;0EBC: 8D BC          '..'
        TBA                              ;0EBE: 17             '.'
        PULB                             ;0EBF: 33             '3'
        BEQ     Z0EF3                    ;0EC0: 27 31          ''1'
        SBA                              ;0EC2: 10             '.'
        BLS     Z0EF3                    ;0EC3: 23 2E          '#.'
        INCA                             ;0EC5: 4C             'L'
        LDX     STRPTR                   ;0EC6: DE 27          '.''
        BRA     Z0ECD                    ;0EC8: 20 03          ' .'
; ------------------------------------------------------------------------------
;* ... MID$(BUF$,33,32) 33==$21 (B) 32==$20 (A)
_MID
Z0ECA   TSX                              ;0ECA: 30             '0'
        LDX     $02,X                    ;0ECB: EE 02          '..'
Z0ECD   STX     STRPTR                    ;0ECD: DF 27          '.''
        TSTA                             ;0ECF: 4D             'M'
        BEQ     Z0EF3                    ;0ED0: 27 21          ''!'
Z0ED2   TST     ,X                       ;0ED2: 6D 00          'm.'
        BEQ     Z0F04                    ;0ED4: 27 2E          ''.'
        DECA                             ;0ED6: 4A             'J'
        BEQ     Z0EDC                    ;0ED7: 27 03          ''.'
        INX                              ;0ED9: 08             '.'
        BRA     Z0ED2                    ;0EDA: 20 F6          ' .'

Z0EDC   TSTB                             ;0EDC: 5D             ']'
        BEQ     Z0F04                    ;0EDD: 27 25          ''%'
        BSR     Z0F0B                    ;0EDF: 8D 2A          '.*'
        BRA     Z0EF7                    ;0EE1: 20 14          ' .'

Z0EE3   BRA     Z0E7A                    ;0EE3: 20 95          ' .'
;*
;* LEFT$(buf, n)
;*
;* 0,X -> Some Function Addr (???)
;* 2,X -> BUF$  
;*
_LEFT
Z0EE5   TSX                              ;0EE5: 30             '0'
        LDX     $02,X                    ;0EE6: EE 02          '..'
Z0EE8   TSTB                             ;0EE8: 5D             ']'
        BEQ     Z0EF3                    ;0EE9: 27 08          ''.'
        LDAA    ,X                       ;0EEB: A6 00          '..'
        BEQ     Z0EF3                    ;0EED: 27 04          ''.'
        INX                              ;0EEF: 08             '.'
        DECB                             ;0EF0: 5A             'Z'
        BRA     Z0EE8                    ;0EF1: 20 F5          ' .'

Z0EF3   STX     STRPTR                   ;0EF3: DF 27          '.''
        CLR     ,X                       ;0EF5: 6F 00          'o.'
Z0EF7   TSX                              ;0EF7: 30             '0'
        LDX     ,X                       ;0EF8: EE 00          '..'
        INS                              ;0EFA: 31             '1'
        INS                              ;0EFB: 31             '1'
        INS                              ;0EFC: 31             '1'
        INS                              ;0EFD: 31             '1'
        ;;
        ;;  What's in X? Is this that DES/DES earlier?
        ;; 
; JMP ,X
        JMP     ,X                       ;0EFE: 6E 00          'n.'
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
;
; X contains the address of the string to ??? (like "ME\0")
;
Z0F00   LDAB    #$80                     ;0F00: C6 80          '..'
        BRA     Z0F0B                    ;0F02: 20 07          ' .'
; ------------------------------------------------------------------------------

Z0F04   TSX                              ;0F04: 30             '0'
        LDX     $02,X                    ;0F05: EE 02          '..'
        BRA     Z0EF3                    ;0F07: 20 EA          ' .'

Z0F09   LDAB    #$20                     ;0F09: C6 20          '. '
Z0F0B   LDAA    ,X                       ;0F0B: A6 00          '..' ;* Get the character (ex: M)
        BSR     Z0F17                    ;0F0D: 8D 08          '..' 
        TSTA                             ;0F0F: 4D             'M'  ;* Check for null
        BEQ     Z0F24                    ;0F10: 27 12          ''.' ;* Done
        INX                              ;0F12: 08             '.'
        DECB                             ;0F13: 5A             'Z'
        BNE     Z0F0B                    ;0F14: 26 F5          '&.'
Z0F16   TBA                              ;0F16: 17             '.'
;*
Z0F17   STX     STRSAV                   ;0F17: DF 29          '.)'
        LDX     STRPTR                   ;0F19: DE 27          '.''
        STAA    ,X                       ;0F1B: A7 00          '..'
        BEQ     Z0F20                    ;0F1D: 27 01          ''.'
Z0F1F   INX                              ;0F1F: 08             '.'
Z0F20   STX     STRPTR                   ;0F20: DF 27          '.''
        LDX     STRSAV                   ;0F22: DE 29          '.)'
Z0F24   RTS                              ;0F24: 39             '9'
; ------------------------------------------------------------------------------

Z0F25   BSR     Z0F16                    ;0F25: 8D EF          '..'
        CLRA                             ;0F27: 4F             'O'
        BRA     Z0F17                    ;0F28: 20 ED          ' .'
Z0F2A   LDX     STRPTR                   ;0F2A: DE 27          '.''
        CLR     ,X                       ;0F2C: 6F 00          'o.'
        BRA     Z0F1F                    ;0F2E: 20 EF          ' .'
Z0F30   LDAB    #$01                     ;0F30: C6 01          '..'
        STAB    M002F                    ;0F32: D7 2F          './'
        STX     STRPTR                   ;0F34: DF 27          '.''
        BSR     Z0EE3                    ;0F36: 8D AB          '..'
        TSTB                             ;0F38: 5D             ']'
        BEQ     Z0F65                    ;0F39: 27 2A          ''*'
        STAB    M002C                    ;0F3B: D7 2C          '.,'
        LDX     XSAVE                    ;0F3D: DE 20          '. '
        BSR     Z0EE3                    ;0F3F: 8D A2          '..'
Z0F41   STAB    M002B                    ;0F41: D7 2B          '.+'
        LDAB    M002C                    ;0F43: D6 2C          '.,'
        CMPB    M002B                    ;0F45: D1 2B          '.+'
        BLS     Z0F4C                    ;0F47: 23 03          '#.'
        CLRB                             ;0F49: 5F             '_'
        CLRA                             ;0F4A: 4F             'O'
        RTS                              ;0F4B: 39             '9'
; ------------------------------------------------------------------------------

Z0F4C   LDX     STRPTR                    ;0F4C: DE 27          '.''
        STX     STRSAV                    ;0F4E: DF 29          '.)'
        LDX     XSAVE                    ;0F50: DE 20          '. '
Z0F52   STX     M002D                    ;0F52: DF 2D          '.-'
        LDX     STRSAV                    ;0F54: DE 29          '.)'
        LDAA    ,X                       ;0F56: A6 00          '..'
        INX                              ;0F58: 08             '.'
        STX     STRSAV                    ;0F59: DF 29          '.)'
        LDX     M002D                    ;0F5B: DE 2D          '.-'
        CMPA    ,X                       ;0F5D: A1 00          '..'
        BNE     Z0F69                    ;0F5F: 26 08          '&.'
        INX                              ;0F61: 08             '.'
        DECB                             ;0F62: 5A             'Z'
        BNE     Z0F52                    ;0F63: 26 ED          '&.'
Z0F65   LDAB    M002F                    ;0F65: D6 2F          './'
        CLRA                             ;0F67: 4F             'O'
        RTS                              ;0F68: 39             '9'
; ------------------------------------------------------------------------------

Z0F69   LDX     XSAVE                    ;0F69: DE 20          '. '
        INX                              ;0F6B: 08             '.'
        STX     XSAVE                    ;0F6C: DF 20          '. '
        INC     >M002F                   ;0F6E: 7C 00 2F       '|./'
        LDAB    M002B                    ;0F71: D6 2B          '.+'
        DECB                             ;0F73: 5A             'Z'
        BRA     Z0F41                    ;0F74: 20 CB          ' .'
; ------------------------------------------------------------------------------
;* Does a compare A (*STRPTR) & B (*SBFPTR)
COMPARE
Z0F76   STX     STRPTR                    ;0F76: DF 27          '.''
        LDX     XSAVE                    ;0F78: DE 20          '. '
        LDAA    ,X                       ;0F7A: A6 00          '..'
        BEQ     Z0F8D                    ;0F7C: 27 0F          ''.'
        INX                              ;0F7E: 08             '.'
        STX     XSAVE                    ;0F7F: DF 20          '. '
        LDX     STRPTR                    ;0F81: DE 27          '.''
        LDAB    ,X                       ;0F83: E6 00          '..'
        BEQ     Z0F8B                    ;0F85: 27 04          ''.'
        INX                              ;0F87: 08             '.'
        CBA                              ;0F88: 11             '.'
        BEQ     Z0F76                    ;0F89: 27 EB          ''.'
Z0F8B   CLC                              ;0F8B: 0C             '.'
        RTS                              ;0F8C: 39             '9'
; ------------------------------------------------------------------------------

Z0F8D   LDX     STRPTR                    ;0F8D: DE 27          '.''
        TST     ,X                       ;0F8F: 6D 00          'm.'
        BNE     Z0F8B                    ;0F91: 26 F8          '&.'
        SEC                              ;0F93: 0D             '.'
        RTS                              ;0F94: 39             '9'
; ------------------------------------------------------------------------------
;* Unreachable code
        PSHA                             ;0F95: 36             '6'
        BSR     Z0FBC                    ;0F96: 8D 24          '.$'
        LDX     STRPTR                    ;0F98: DE 27          '.''
        STX     BUFPTR                    ;0F9A: DF 22          '."'
        PULA                             ;0F9C: 32             '2'
        BSR     Z0FCB                    ;0F9D: 8D 2C          '.,'
        LDX     BUFPTR                    ;0F9F: DE 22          '."'
        STX     STRPTR                    ;0FA1: DF 27          '.''
        CLR     ,X                       ;0FA3: 6F 00          'o.'
        BRA     Z0FB1                    ;0FA5: 20 0A          ' .'
; ------------------------------------------------------------------------------

Z0FA7   STX     STRSAV                   ;0FA7: DF 29          '.)'
        BSR     Z0FBC                    ;0FA9: 8D 11          '..'
        LDX     STRSAV                   ;0FAB: DE 29          '.)'
        STX     BUFPTR                   ;0FAD: DF 22          '."'
        BSR     Z0FC8                    ;0FAF: 8D 17          '..'
Z0FB1   PSHA                             ;0FB1: 36             '6'
        LDAA    M002B                    ;0FB2: 96 2B          '.+'
        STAA    CHRCNT                   ;0FB4: 97 26          '.&'
        LDX     M002D                    ;0FB6: DE 2D          '.-'
        STX     BUFPTR                   ;0FB8: DF 22          '."'
        PULA                             ;0FBA: 32             '2'
        RTS                              ;0FBB: 39             '9'
; ------------------------------------------------------------------------------

Z0FBC   LDAA    CHRCNT                   ;0FBC: 96 26          '.&'
        STAA    M002B                    ;0FBE: 97 2B          '.+'
        CLR     >CHRCNT                  ;0FC0: 7F 00 26       '..&'
        LDX     BUFPTR                   ;0FC3: DE 22          '."'
        STX     M002D                    ;0FC5: DF 2D          '.-'
        RTS                              ;0FC7: 39             '9'
; ------------------------------------------------------------------------------

Z0FC8   JMP     Z0C59                    ;0FC8: 7E 0C 59       '~.Y'
Z0FCB   JMP     Z0DF4                    ;0FCB: 7E 0D F4       '~..'
; ------------------------------------------------------------------------------

Z0FCE   STAB    BASE+1                   ;0FCE: F7 13 01       '...'
;       STAA    M1300                    ;0FD1: B7 13 00       '...'
        STAA    BASE                     ;0FD1: B7 13 00       '...'
        LDX     BASE                     ;0FD4: FE 13 00       '...'
;       LDX     M1300                    ;0FD4: FE 13 00       '...'
        LDAA    ,X                       ;0FD7: A6 00          '..'
        LDAB    $01,X                    ;0FD9: E6 01          '..'
        RTS                              ;0FDB: 39             '9'

; ------------------------------------------------------------------------------
	;;
        ;; This is past the end of the code
        ;; Not really sure what this is
        ;; Is this not the end?
;0FDC   JSR     Z031A                    ;0FDC: BD 03 1A       '...'
X0FDC   JSR     LDFROM                   ;0FDC: BD 03 1A       '...'
X0FDF   FCB     $24

        END
; END @ 0FDB but also $0FF0
