        MACEXP  off
        CPU     6800            ; That's what asl has
        include "rt68mx.inc"    ;
        ;include "mikbug.inc"
;*[ Start ]**********************************************************************
	NAM  RT68-V2	;* 
	
;*  <ESC> 1 <ESC> ! python3 ~/dev/python/asm-indent.py ~/dev/MC6800/r/rt68mx.asm <ENTER>

;*	****************
;*	*	       *
;*	*     RT/68    *
;*	*      MX      *
;*	*	       *
;*	****************
;*
;* Semantic version
;*
;* Given a version number MAJOR.MINOR.PATCH, increment the:
;*
;* MAJOR version when you make incompatible API changes (except for 0.x.x -> 1.x.x)
;* MINOR version when you add functionality in a backward compatible manner
;* PATCH version when you make backward compatible bug fixes
;*
;* Additional labels for pre-release and build metadata are available as
;* extensions to the MAJOR.MINOR.PATCH format.
;*
;* Example:
;* 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2
;*   < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.
;*
SEMVER  EQU     "1.1.0"        ;* Original, almost
;*
;* RT/68MX REAL TIME OPERATING SYSTEM
;* (REVISED VERSION OF RT/68MR)
;*
;* COPYRIGHT (C) 1976,1977
;* THE MICROWARE SYSTEMS CORPORATION
;*
;* RT/68 LISTING AND OBJECT MAY NOT BE
;* REPRODUCED IN ANY FORM WITHOUT
;* EXPRESS WRITTEN PERMISSION.
;
;* MEMORY DEFINITIONS
;
;* RT/68 EXECUTIVE USES 12 BYTES OF RAM
;* BEGINNING AT 0, THESE ARE NOT NEEDED
;* IN SINGLE TASK MODE AND MAY BE
;* USED FOR ANY OTHER PURPOSE.
	ORG  LOWRAM	;* Usually 0
SYSMOD	RMB  1  	;* RT MODE 0=USER 1=EXEC
CURTSK	RMB  1  	;* TASK CURRENTLY ACTIVE
TIMREM	RMB  1  	;* TASK TIME REMAINING
TSKTMR	RMB  2  	;* TIMED TASK COUNTER
CLOCK	RMB  2  	;* RT CLOCK COUNTER
INTREQ	RMB  1  	;* INTERRUPT REQUEST FLAG
TSKTMP	RMB  1  	;* RT EXEC TEMP VAL
PTYTMP	RMB  1  	;* RT EXEC TEMP VAL
TIMTSK	RMB  1  	;* TIMED TASK INTR STATUS
SYSPTY	RMB  1  	;* SYS PRIORITY LEVEL

	ORG  RAM	;* Originally $A000
IRQTSK	RMB  2  	;* IRQ TASK/VECTOR
BEGADR	RMB  2  	;* 
ENDADR	RMB  2  	;* 
NMITSK	RMB  2  	;* NMI TASK/VECTOR
SPTMP	RMB  2  	;* SP TMP VAL
RTMOD	RMB  1  	;* RT MODE FLAG
BKPOP	RMB  1  	;* BKPT OPCODE/FLAG
BKPADR	RMB  2  	;* BKPT ADDRESS
RELFLG	RMB  1  	;* SWI FLAG
ERRFLG	RMB  1  	;* ERROR FLAG/CODE
XTMP	RMB  2  	;* 
IOVECT	RMB  2  	;* ACIA ADDRESS VECTOR

;	ORG  $A042	;* 
	ORG  RAM+$42	;* 
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
;	ORG  $A050	;* 
	ORG  RAM+$50	;* 
TSKTBL	RMB  48  	;* 

    ifdef    NJC
;* DEFINE PERIPHERIAL REGISTERS
;	ORG  $8004	;* 
	ORG  IO		;* 
PIADA	RMB  1  	;* 
PIACA	RMB  1  	;* 
PIADB	RMB  1  	;* 
PIACB	RMB  1  	;* 
ACIACS	RMB  1  	;* 
ACIADB	RMB  1  	;* 
    endif               ;* NJC

;	ORG  $E000	;* 
	ORG  ROM	;*
zSTART  EQU  *
;* TAPE LOAD SUBROUTINE
;*
;* READS MIKBUG(TM) FORMATTED OBJECT TAPES
;* INTO RAM.
;*
;* READER DEVICE IS CONTROLLED BY EITHER ASCII
;* CONTROL CODES OR PIA READER CONTROL OUTPUT
;* OUTPUT.
;*
;* TWO ERRORS ARE CHECKED: CHECKSUM AND
;* NO CHANGE
LOAD	LDAB #$3C	;* TAPE ON CONSTANTS XXXXXXXX
	LDAA #$11	;* READER ON CODE
	BSR  RDRCON	;* LET IT ROLL
LOAD2	BSR  INCH	;*
	CMPA #'S' 	;* LOOK FOR START OF BLOCK
	BNE  LOAD2	;* BRA IF NOT
	BSR  INCH	;* 
	CMPA #'9' 	;* END OF FILE?
	BNE  LOAD4	;* BRA IF NOT
LOAD3	LDAB #$34	;* TAPE OFF CONSTANTS XXXXXXXX
	LDAA #$13	;* 
RDRCON	STAB PIACB	;* PIA READER CTRL XXXXXXXX
	BRA  OUTCH	;* ASCII TAPE CONTROL
LOAD4	CMPA #'1'	;* S1 DATA RECORD? XXXXXXXX
	BNE  LOAD2	;* BRA IF NOT, LOOK AGAIN
	CLRB		;* ACCB WILL GENERATE CHKSUM
	BSR  BYTE	;* PICK UP BYTE COUNT
	SUBA #2 	;* LESS 2 FOR THE BLOCK ADDR
LOAD5	STAA BEGADR	;* SAVE IT XXXXXXXX
	BSR  BADDR	;* GET BLOCK START ADDR IN X

;* LOOP TO READ DATA BLOCK
LOAD6	BSR  BYTE	;* GET A DATA BYTE XXXXXXXX
	DEC  BEGADR	;* DECR BYTE COUNT
	BEQ  LOAD7	;* BRA IF LAST BYTE
	STAA 0,X 	;* PUT IN MEMORY
	CMPA 0,X 	;* BE SURE IT CHANGED
	BNE  LDMERR	;* BRA TO ERROR- MUST BE ROM!!
	INX		;* NEXT ADDR
	BRA  LOAD6	;* NEXT BYTE

;* B ADDS CHKSM FROM TAPE TO CALCULATED CHKSUM,
;* SO BY ADDING ONE IT SHOULD ZERO
LOAD7	INCB		;* (LABEL/NM only?)
	BEQ  LOAD2	;* BRA IF IT DID
	LDAA #$32	;* TOO BAD, GET THE ERROR CODE
	BRA  LODERR	;* 
LDMERR	LDAA #$31	;* NO CHANGE ERROR CODE XXXXXXXX
LODERR	STAA ERRFLG	;*
	BRA  LOAD3	;* 

;* BUILD 4 HEX CHAR VALUE (ADDRESS)
;* RETURNS VALUE IN XR
BADDR	BSR  BYTE	;* INPUT 2 LEFT CHRS XXXXXXXX
	STAA ENDADR	;* 
	BSR  BYTE	;* INPUT 2 RIGHT CHRS
	STAA ENDADR+1	;* 
	LDX  ENDADR	;* 
	RTS		;* 

;* INPUT A BYTE (2 HEX CHARS)
;* RETURNS BINARY VALUE IN ACC A

BYTE	PSHB		;* INPUT 2 HEX CHAR XXXXXXXX
	BSR  INHEX	;* LEFT HEX CHAR
	ASLA		;* 
	ASLA		;* 
	ASLA		;* 
	ASLA		;* 
	TAB		;* 
	BSR  INHEX	;* RIGHT HEX CHAR
	ABA		;* 
	PULB		;* 
	PSHA		;* 
	ABA		;* 
	TAB		;* 
	PULA		;* 
	RTS		;* 
	NOP		;* 

;* HEX OUTPUT AUX SUBROUTINES
OUTHL	LSRA		;* (LABEL/NM only?)
	LSRA		;* 
	LSRA		;* 
	LSRA		;* 
OUTHR	ANDA #$F  	;*
	ADDA #$30	;* 
	CMPA #$39	;* 
	BLS  OUTCH	;* 
	ADDA #$7 	;* 

OUTCH	JMP  OUT1CH	;*
INCH	JMP  IN1CHR	;*

;* PRINT DATA STRING POINTED TO BY XR
;* AND ENDING WITH ASCII EOT ($04)
PDATA2	BSR  OUTCH	;*
	INX		;* 
PDATA1	LDAA 0,X	;* SUBR ENTRY POINT XXXXXXXX
	CMPA #4 	;* 
	BNE  PDATA2	;* 
	RTS		;* 

;*
;* CONSOLE MEMORY DUMP SUBROUTINE
;*
;* PRINTS BEG ADDR AND 16 BYTES OF DATA ON EACH LINE
;* STARTING ADDR IN BEGADR
;* ENDING ADDR IN ENDADR
;*
DUMP	JSR  CRLF	;* CR AND LF XXXXXXXX
	LDX  #BEGADR	;* 
	BSR  OUT4HS	;* PRINT BEGINNING ADDR
	LDAB #16 	;* BYTE COUNT FOR LINE
	LDX  BEGADR	;* GET BEG ADDR
DUMP1	BSR  OUT2HS	;* PRINT A BYTE XXXXXXXX
	DEX		;* 
	CPX  ENDADR	;* DONE YET?
	BNE  DUMP2	;* BRA IF NOT
	RTS		;* 
DUMP2	INX		;* ADV X TO NEXT BYTE XXXXXXXX
	DECB		;* DEC LINE BYTE COUNT
	BNE  DUMP1	;* BRA IF LINE NOT DONE
	STX  BEGADR	;* UPDATE BEGADR TO CURRENT ADDR
	BRA  DUMP	;* 

HBAD	LDAA #$33	;* INHEX ERROR RETURN XXXXXXXX
	STAA ERRFLG	;* 
	RTS		;* 

;* INPUT HEX CHARACTER, IF CHAR IS NOT
;* HEX, THE ERROR FLAG IS SET TO THE
;* ERROR CODE ($33 - ASCII 1)
INHEX	BSR  INCH	;* INPUT ONE HEX CHAR XXXXXXXX
	SUBA #$30	;* 
	BCS  HBAD	;* 
	CMPA #9 	;* 
	BLS  IHRET	;* 
	SUBA #7 	;* 
	BCS  HBAD	;* 
	CMPA #15 	;* 
	BHI  HBAD	;* 
IHRET	RTS		;* (LABEL/NM only?)

	NOP		;* 
	NOP		;* 

;* OUTPUT BYTE (TWO HEX CHARS) POINTED
;* TO BY XR
OUT2H	LDAA 0,X  	;*
	BSR  OUTHL	;* 
	LDAA 0,X 	;* 
	INX		;* 
	BRA  OUTHR	;* 

;* OUTPUT 4 HEX CHARS AND SPACE
OUT4HS	BSR  OUT2H	;*

;* OUTOUT 2 HEX CHARS AND SPACE
OUT2HS	BSR  OUT2H	;*

;* OUTPUT A SPACE
OUTS	LDAA #$20	;*
BOUT	BRA  OUTCH	;*

;* PRINT CONTENTS OF STACK
;* FORMAT:
;* SP CC B A XR PC
PRSTAK	BSR  CRLF	;* PRINT CF+LF XXXXXXXX
	LDX  #SPTMP	;* 
	BSR  OUT4HS	;* PRINT SP
	LDX  SPTMP	;* 
PRSTK	INX		;* ENTRY TO PRINT TASK STACK XXXXXXXX
	BSR  OUT2HS	;* PRINT CC
	BSR  OUT2HS	;* PRINT ACC B
	BSR  OUT2HS	;* PRINT ACC A
	BRA  PRSTK2	;* BRA OVER PATCH
CONTRL	JMP  CONENT	;* PATCH FOR ADDR ALIGNMENT XXXXXXXX
PRSTK2	BSR  OUT4HS	;* PRINT XR XXXXXXXX
	BRA  OUT4HS	;* PRINT PC +RTS

;* WRITE OBJECT TAPE SUBROUTINE
;*
;* GENERATES MIKBUG(TM) FORMATTED TAPES
;* ON SYSTEM TAPE DEVICE (PAPER TAPE,
;* AUDIO CASSETTE, ETC.)
;*
;* BEGINNING ADDRESS OF DATA IN "BEGADR"
;* ENDING ADDRESS IN "ENDADR"
;*
;* ENTRY POINT IS "TAPOUT" - E0EE
;
;* AUX. SUBR. TO OUTPUT BYTE + UPDATE
;* CHECKSUM.
TAPAUX	ADDB 0,X  	;*
	BRA  OUT2H	;* 

TAPOUT	LDAA #$12	;* TAPE ON CODE XXXXXXXX
	BSR  OUTCH	;* 
;* OUTPUT 60 NULL CHARS TO GENERATE
;* EITHER A 6" LEADER FOR PAPER TAPE "
;* OR A 2 SECOND TAPE SPEEDUP DELAY
;* (AT 30CPS) FOR AUDIO CASSETTES
	LDAB #60 	;* LEADER/DELAY NULL COUNT
OUTLDR	CLRA		;* (LABEL/NM only?)
	BSR  JOUT1C	;* 
	DECB		;* 
	BNE  OUTLDR	;* 

;* SUBTRACT BEGADR FROM ENDADR
TOUT1	LDX  #BEGADR	;*
	LDAA 2,X 	;* 
	LDAB 3,X 	;* 
	SUBB 1,X 	;* 
	SBCA 0,X 	;* 
	BCC  TOUT2	;* BRA IF BEG < END TO DUMP
	LDAA #$14	;* PUNCH OFF CODE
JOUT1C	JMP  OUTCH	;*

;* CALCULATE BYTE COUNT
TOUT2	BNE  TOUT3	;* BRA IF HIGH BYTE NONZERO XXXXXXXX
	CMPB #16 	;* 
	BCS  TOUT4	;* BRA IF BLOCK < 16 BYTES
TOUT3	LDAB #15	;* SET FULL BLOCK XXXXXXXX
TOUT4	ADDB #4		;* ADD FOR B.C. + BEG ADDR. XXXXXXXX

;* OUTPUT BLOCK HEADER
	BSR  CRLF	;* OUTPUT CR,LF,NULLS
	INX		;* 
	BSR  JPDATA	;* OUTPUT S,1
	PSHB		;* SAVE BYTE COUNT
	TSX		;* 
	CLRB		;* CLEAR CHECKSUM
	BSR  TAPAUX	;* PRINT BYTE CNT
	PULA		;* 
	SUBA #3 	;* UPDATE BYTE COUNT
	PSHA		;* 
	LDX  #BEGADR	;* 
	BSR  TAPAUX	;* OUTPUT BEG. ADDR
	BSR  TAPAUX	;* 

;* LOOP TO OUTPUT ONE BLOCK OF DATA
	LDX  BEGADR	;* XR POINTS TO CURRENT DATA BYT
TOUT5	BSR  TAPAUX	;* OUTPUT BYTE XXXXXXXX
	PULA		;* 
	DECA		;* DECR BYTE COUNT
	PSHA		;* 
	BNE  TOUT5	;* BRA IF BYTE CNT NOT ZERO

	INS		;* 
	STX  BEGADR	;* SAVE CURRENT ADDR
	COMB		;* COMPL CHKSUM
	PSHB		;* 
	TSX		;* 
	BSR  TAPAUX	;* OUTPUT CHKSUM
	INS		;* 
	BRA  TOUT1	;* 

;* SUBROUTINE TO PRINT CR + LF
CRLF	LDX  #CRLSTR	;*
JPDATA	JMP  PDATA1	;*

;* RT/68 CONSOLE MONITOR PROGRAM
;*
;* ACCEPTS COMMANDS FORM THE CONSOLE DEVICE
;* AND EXECUTES THE APPROPRIATE FUNCTION.
;
;* ENTRY POINT FOR RESTART
INIT	LDS  #STACK	;* INITIALIZE PERIPHERALS XXXXXXXX
	STS  SPTMP	;* 
	LDX  #$8000	;* 
	STX  IOVECT	;* INIT ACIA VECTOR
;* INITIALIZE CONTROL PIA
	INC  4,X 	;* 
	LDAB #$16	;* 
	STAB 5,X 	;* 
	INC  4,X 	;* 
	LDAA #$05	;* 
	STAA 6,X 	;* 
	LDAA #$34	;* 
	STAA 7,X 	;* 
;* INITIALIZE ACIA AT $8000
	LDAA #3 	;* 
	STAA 0,X 	;* 
	DECB		;* 
	STAB 0,X 	;* SET ACIA CSR
CONENT	CLR  BKPOP	;* CONSOLE ROUTINE ENTRY POINT XXXXXXXX
	CLR  RTMOD	;* 
CONSOL	CLR  ERRFLG	;*
	LDS  #STACK	;* INIT SP
	BSR  CRLF	;* 
	LDAA #'$' 	;* PRINT PROMPT
	BSR  OUTEEE	;* 
	BSR  INEEE	;* INPUT COMMAND CODE

;* COMMAND TABLE LOOKUP/EXECUTE LOOP
;* SEARCHES FOR COMMAND CODE ON TABLE TO OBTAIN
;* FUNCTION SUBROUTINE ADDRESS.
	LDX  #CMDTBL-3	;* INIT X TO BEGINNING OF TABL
CMSRCH	INX  		;* ADV TO NEXT ENTRY XXXXXXXX
	INX		;* 
	INX		;* 
	LDAB 0,X 	;* GET CODE FROM TABLE
	BEQ  CMDERR	;* IF ZERO, END OF TABLE
	CBA		;* COMMAND CODE MATCH COMPARE
	BNE  CMSRCH	;* BACK TO ADV IF NOT
	LDX  1,X 	;* GET CMND SUBR ADDR FROM TABLE
	JSR  0,X 	;* DO IT
TSTENT	BSR  ERTEST	;* TEST FOR ERROR XXXXXXXX
GOCON	BRA  CONSOL	;* GET ANOTHER CMND XXXXXXXX

CMDERR	LDAB #'6'	;* ILLEGAL COMMAND CODE XXXXXXXX
	BRA  ERROR	;* 

;* SUBR TO SET 0R REMOVE BREAKPOINTS
SETBKP	LDAA BKPOP	;* GET BKPT FLAG OR OPCODE XXXXXXXX
	BEQ  SBRET	;* IF = 0, NO BKPT ACTIVE
	LDX  BKPADR	;* GET ADDR
;* SWAP FLAG/OPCODE
	LDAB 0,X 	;* 
	STAA 0,X 	;* 
	STAB BKPOP	;* 
SBRET	RTS		;* (LABEL/NM only?)

;* "D" DUMP COMMAND
DMPCOM	BSR  GET2AD	;*
	JMP  DUMP	;* 

INEEE	JMP  IN1CHR	;*

;* SUBR TO PREPARE FOR USER PROGRAM
;* EXECUTION. CALLED BY G, E, & S COMMANDS
;*
SETRUN	BSR  SETBKP	;* SET BKPT IF ANY XXXXXXXX
	LDAB #$1E	;* 
	LDAA RTMOD	;* TEST IF MULTITASK MODE
	BEQ  SETRN2	;* BRA IF NOT MULTI
	INCB		;* ENABLE RT CLOCK INTR
	CLRA		;* 
	STAA SYSMOD	;* 
SETRN2	LDAA PIADA	;*
	STAB PIACA	;* 
RETURN	RTS		;* (LABEL/NM only?)

;* "B" BREAKPOINT COMMAND ROUTINE
BKPCOM	CLR  BKPOP	;*
	BSR  GETADR	;* 
	STX  BKPADR	;* 
	LDAA #$3F	;* 
	STAA BKPOP	;* 
	RTS		;* 

OUTEEE	JMP  OUT1CH	;*

;* SUBR TO READ ONE OR TWO ADDRESS
;* PARAMETERS, COMMA LEADS ADDRESSES,
;* (CR) CANCELS COMMAND
GET2AD	BSR  GETADR	;* GET TWO ADDRESSES XXXXXXXX
	STX  BEGADR	;* 

GETADR	BSR  INEEE	;* GET ONE ADDRESS XXXXXXXX
	LDAB #$34	;* 
	CMPA #$0D	;* 
	BEQ  CONSOL	;* 
	CMPA #',' 	;* 
	BNE  ERROR	;* 
	JSR  BADDR	;* 

;* ERROR TEST SUBROUTINE
ERTEST	LDAB ERRFLG	;*
	BEQ  RETURN	;* 

;* ERROR HANDLER, PRINTS MESSAGE
;* AND ERROR CODE
ERROR	LDX  #ERRMSG	;*
	JSR  PDATA1	;* 
	TBA		;* 
	BSR  OUTEEE	;* 
	BRA  GOCON	;* 

;* "E" EXECUTE SINGLE TASK COMMAND
EXCOM	BSR  GETADR	;*
	BSR  SETRUN	;* 
	LDX  ENDADR	;* 
	JMP  0,X 	;* 

;* "G" GO TO USER PGM OR RETURN FROM
;* BREAKPOINT COMMAND ROUTINE
GOCOM	LDS  SPTMP	;*
	BSR  SETRUN	;* 
	RTI		;* 

;* "P" WRITE TAPE COMMAND
PUNCOM	BSR  GET2AD	;*
	JMP  TAPOUT	;* 

;* "S" COMMAND
;* ACTIVATES AND INITIALIZES RT/68
;* EXECUTIVE
SYSCOM	CLR  RELFLG	;*
	LDAA #1 	;* 
	STAA RTMOD	;* 
	LDX  #PTYTMP	;* 
CLOOP	CLR  0,X  	;*
	DEX		;* 
	BNE  CLOOP	;* 
	STAA 0,X 	;* 
	BSR  SETRUN	;* 
	JMP  EXEC02	;* JUMP TO RT EXEC ENTRY

;* "M" MEMORY EXAMINE/CHANGE ROUTINE
;* AFTER BEGINNING ADDR IS ENTERED, PGM
;* PRINTS ADDR AND DATA IN HEX:
;*	AAAA DD
;* A SLASH AND NEW HEX DATA CHANGES LOACTION,
;* A (LF) OPENS NEXT ADDR, AND A (CR) CLOSES
;* FUNCTION
MEMCOM	BSR  GETADR	;* GET BEG ADDR XXXXXXXX

;* EXAMINE/CHANGE LOOP
MEM1	JSR  CRLF	;*
MEM2	LDAA #$0D	;* PRINT LF XXXXXXXX
	BSR  OUTEEE	;* 
	LDX  #ENDADR	;* 
	JSR  OUT4HS	;* PRINT ADDRESS
	LDX  ENDADR	;* 
	JSR  OUT2H	;* PRINT CONTENTS
	STX  ENDADR	;* 
	JSR  INEEE	;* INPUT DELIMITER
	CMPA #$0A	;* 
	BEQ  MEM2	;* BRA IF LF TO OPEN NEXT
	CMPA #'/' 	;* 
	BEQ  MEM3	;* BRA IF CHANGE
	RTS		;* 

;* CHANGE MEMORY LOCATION
MEM3	JSR  BYTE	;* READ NEW DATA XXXXXXXX
	BSR  ERTEST	;* 
	DEX		;* 
	STAA 0,X 	;* STORE NEW DATA
	CMPA 0,X 	;* TEST FOR CHANGE
	BEQ  MEM1	;* BRA IF OK TO OPEN NEXT
	LDAB #$35	;* ERROR CODE
	BRA  ERROR	;* 

;*	REAL TIME OPERATING SYSTEM COMPONENTS
;*
;* CONSISTS OF:
;*
;*	INTERRUPT PROCESSORS
;*	TASK EXECUTIVE
;*	AUX. SUBROUTINES
;*


;* BREAKPOINT SERVICE ROUTINE
RUNBKP	TSX		;* GET SP IN XR XXXXXXXX
	BSR  ADJSTK	;* DECR PC ON STACK
	LDX  5,X 	;* GET TASK PC OFF STACK
	CPX  BKPADR	;* COMPARE TO PRESET ADR
	BEQ  RUNBK2	;* BRA IF SAME
	LDAB #$37	;* SET ERROR FLAG
	STAB ERRFLG	;* 
RUNBK2	JSR  SETBKP	;* REMOVE BKPT OPCODE XXXXXXXX
	LDAA #$16	;* 
	STAA PIACA	;* OFF RT CLOCK + ABORT INTR
	STS  SPTMP	;* SAVE TASK SP
	JSR  PRSTAK	;* DUMP STACK
	JMP  TSTENT	;* ENTER CONSOLE MONITOR

;* SUBR TO DECREMEMT PC ON STACK
ADJSTK	TST  0,X  	;*
	BNE  ADSTK2	;* 
	DEC  5,X 	;* 
ADSTK2	DEC  6,X  	;*
	RTS		;* 

;* SWI ENTRY POINT, DETERMINES WHETHER
;* BREAKPOINT OR PGM RELEASE FUNCTION

SINT	EQU  *  	;* SWI VECTOR DESTINATION
	LDAA RELFLG	;* GET PGM RELEASE FLAG
	BEQ  RUNBKP	;* EXEC BKPT IF NOT SET
	CLR  RELFLG	;* RESET FLAG
	CLRB		;* 
	BRA  EXEC09	;* GO TO EXEC TO SWAP

;* IRQ INTERRUPT ENTRY POINT
;* INCLUDES LOGIC TO DETECT AND CORRECT
;* INTERRUPT ERROR OCCURRING WHEN SWI +
;* NMI OCCUR SIMULTANEOUSLY. (SEE P. A-10
;* OF M6800 APPLICATIONS MANUAL)

IRQ	EQU  *  	;* IRQ VECTOR DESTINATION
	LDAA RELFLG	;* GET SWI FLAG
	BNE  INTBAD	;* BRA TO ERR CORR. IF SET
	LDX  #IRQTSK	;* PTR TO IRQ VECTOR/STATUS
	BRA  RUNINT	;* GOTO INTR SERVICE

;* CORRECT SWI-IRQ COINC. ERROR
INTBAD	TSX		;* (LABEL/NM only?)
	BSR  ADJSTK	;* DECR TASK PC ON STACK

;* NMI INTERRUPT HANDLER
;*
;* TEST CONTROL PIA FOR ABORT OR CLOCK
;* INTERRUPT AND PROCESS SAME
;* IF NOT, EXECUTES USER INTERRUPT
NMI	EQU  *  	;* NMI VECTOR DEST.
	LDAA PIACA	;* GET PIA STATUS REG
	LDAB PIADA	;* CLEAR PIA INTR FLGS
	ASLA		;* 
	BMI  RUNBK2	;* BRA IF ABORT INTR
	BCC  NMI5	;* BRA IF USER INTR
;* HERE IF CLOCK INTR ONLY
	LDAA RTMOD	;* TEST SYS MOD
	BEQ  NMI5	;* BRA TO USER INTR IF NOT
	LDX  CLOCK	;* 
	INX		;* 
	STX  CLOCK	;* 
;* UPDATE TIMED TASK STATUS
	LDX  TSKTMR	;* GET THE TIMED TASK COUNTER
	BEQ  NMI3	;* BRA IF NOT ACTIVE
	DEX		;* DECR THE COUNTER
	STX  TSKTMR	;* 
	BNE  NMI3	;* BRA IF NOT EXPIRED
	LDAA TIMTSK	;* GET TIMED TASK STAT BYTE
	BRA  RNINT3	;* RUN AS INTERRUPT
;* UPDATE REMAINING TIME OF CURRENT TASK
NMI3	LDAA TIMREM	;* GET TIME LEFT XXXXXXXX
	BEQ  NMI4	;* BRA IF UNLIMITED
	DECA		;* 
	STAA TIMREM	;* 
	BEQ  EXEC01	;* BRA TO EXEC IF TIME UP
NMI4	LDAA INTREQ	;* TEST FOR PENDING INTR. XXXXXXXX
	BNE  EXEC01	;* 
	RTI		;* 
NMI5	LDX  #NMITSK	;* GET NMI STAT PTR XXXXXXXX

;* GENERAL INTERRUPT PRESERVICE
;* SELECTS PROPER MODE, AND EITHER
;* RUNS OR SCHEDULES INTERRUPT SERVICE
;* TASK ACCORDING TO THE APPROPRIATE
;* STATUS BYTE
RUNINT	LDAA RTMOD	;*
	BNE  RNINT2	;* BRA IF MULTITASK MODE
	LDX  0,X 	;* GET VECTOR
	JMP  0,X 	;* EXECUTE SAME AS MIKBUG

RNINT2	LDAA 0,X	;* GET INTR STATUS BYTE XXXXXXXX
RNINT3	BSR  TSKON	;* TURN SERV. TASK ON XXXXXXXX
	TSTA		;* CHK IMMED OR DEFERRED
	BPL  INTRET	;* BRA IF DEFERRED
	STAA INTREQ	;* SET INTR REQ. FLAG
;* FALL THRU TO EXECUTIVE

;* RT/68 MULTI TASK EXECUTIVE PROGRAM
;*
;* SAVES CURRENT TASK STATUS IN TASK STATUS
;* TABLE, THEN SEARCHES THE TABLE FOR THE
;* HIGHEST PRIORITY RUNNABLE TASK AND STARTS
;* IT. IF THERE IS MORE THAN ONE RUNNABLE TASK
;* AT THE HIGHEST LEVEL, THE
;* EXECUTIVE WII RUN THEM ROUND ROBIN

;* TEST MODE TO PREVENT MULTIPLE
;* EXECUTION OF EXEC BY INTERRUPTS
EXEC01	LDAB SYSMOD	;*
	BNE  INTRET	;* BRA IF EXEC ALREADY ACTIVE
EXEC09	INCB		;* SET EXEC MODE XXXXXXXX
	STAB SYSMOD	;* 
;* SAVE CURRENT TASK SP ON TABLE
	LDAA CURTSK	;* GET CURRENT TASK #
	BSR  FNDTSB	;* FIND ADDR OF TSB
	STS  1,X 	;* SAVE SP

;* INITIALIZE EXEC TEMP VALUES
;* PTYTMP = HIGHEST PRIORITY FOUND
;* TSKTMP = TASK # FOR ABOVE
EXEC02	CLRA		;* (LABEL/NM only?)
	STAA INTREQ	;* 
	STAA PTYTMP	;* 
	STAA TSKTMP	;* 
	LDAA CURTSK	;* 

;* LOOP TO SEARCH THRU TABLE FOR
;* HIGHEST RUNNABLE TASK
;* STARTS WITH CURRENT TASK AND COUNTS
;* DOWN SO LAST TASK TESTED IS THE
;* CURRENT TASK # -1. THIS ALLOWS TASKS
;* AT THE SAME PRIORITY LEVEL TO EXECUTE
;* ROUND-ROBIN.
EXEC03	BSR  FNDTSB	;* FIND TSB XXXXXXXX
	BPL  EXEC04	;* BRA IF TASK OFF
	ANDB #$07	;* MASK PRIORITY
	CMPB PTYTMP	;* COMP. TO HIGHEST SO FAR
	BCS  EXEC04	;* BRA IF LOWER
	STAB PTYTMP	;* MAKE IT LATEST
	TAB		;* CHANGE SET TASK #
	ORAB #$80	;* SET FOUND FLAG
	STAB TSKTMP	;* 
;*ADVANCE TO NEXT TASK
EXEC04	DECA		;* (LABEL/NM only?)
	ANDA #$0F	;* 
	CMPA CURTSK	;* SEE IF LAST TASK
	BNE  EXEC03	;* BRA IF NOT FINISHED

;* CHECK IF TASK FOUND IS RUNNABLE
	LDAB PTYTMP	;* GET HI PRIORITY
	CMPB SYSPTY	;* COMPARE TO SYS PRIORITY
	BCS  EXEC02	;* SEARCH AGAIN IF LOWER
	LDAA TSKTMP	;* TEST FOUND FLAG
	BPL  EXEC02	;* BRA IF NOT SET

;* RUNNABLE TASK FOUND, SET SYSTEM
;* PARAMETERS TO RUN IT
	ANDA #$0F	;* 
	STAA CURTSK	;* SET TASK #
	BSR  FNDTSB	;* GET TASK TSB
	LSRB		;* EXTRACT TIME LIMIT
	LSRB		;* 
	LSRB		;* 
	ANDB #$0F	;* 
	STAB TIMREM	;* 
	LDS  1,X 	;* LOAD TASK SP
;* TEST FOR ANY INTERRUPT THAT OCCURRED
;* DURING EXEC MODE
	LDAA INTREQ	;* 
	BNE  EXEC02	;* 
	CLR  SYSMOD	;* SET USER MODE
INTRET	RTI		;* RUN TASK XXXXXXXX

;* RT EXECUTIVE AUX. SUBROUTINES
;*
;* ALL ARE REENTRANT SUBROUTINES THAT
;* PASS PARAMETERS AS FOLLOWS:
;*
;* ENTRY: TASK # IN ACC A
;*
;* RETURN: TASK # IN ACC A
;*		TASK STATUS BYTE (NEW) IN ACC B
;*		ADDR OF TSB IN XR

;* SUBR TO TURN TASK ON
TSKON	BSR  FNDTSB	;*
	ORAB #$80	;* 
RESTSB	STAB 0,X  	;*
	RTS		;* 

;* SUBR TO TURN CURRENT TASK OFF
CTSKOF	LDAA CURTSK	;*

;* SUBR TO TURN TASK OFF
TSKOFF	BSR  FNDTSB	;*
	ANDB #$7F	;* 
	BRA  RESTSB	;* 

;* SUBR TO FIND TASK STATUS BYTE/WORD
FNDTSB	PSHA		;* (LABEL/NM only?)
	ANDA #$0F	;* 
	TAB		;* 
	ASLA		;* 
	ABA		;* 
	ADDA lo(TSKTBL)	;* 
	PSHA		;* 
	LDAA hi(TSKTBL) ;* 
	PSHA		;* 
	TSX		;* 
	LDX  0,X 	;* 
	INS		;* 
	INS		;* 
	LDAB 0,X 	;* 
	PULA		;* 
	RTS		;* 

;* CHARACTER AND BYTE I/O ROUTINES
;*
;* SELECTS INTERFACE TYPE (PIA OR ACIA)
;* ACCORDING TO THE LEVEL OF PIA INPUT CB5
;* IF ACIA TYPE IS SELECTED, THE ADDRESS
;* OF THE ACIA IS OBTAINED FROM "IOVECT"
;* WHICH WILL DEFAULT TO $8000

;* READ CHAR WITHOUT PARITY OR RUBOUT
IN1CHR	BSR  INBYTE	;* GET BYTE XXXXXXXX
	ANDA #$7F	;* STRIP PARITY BIT
	CMPA #$7F	;* TEST FOR RUBOUT
	BEQ  IN1CHR	;* AGAIN IF RUBOUT
	RTS		;* 

;* READ 8-BIT BYTE
INBYTE	PSHB		;* (LABEL/NM only?)
	BSR  IOAUX	;* SAVE XR + SAMPLE TYPE
	BNE  ACIAIN	;* 

;* PIA SOFTWARE UART ROUTINE -
;* INPUT ONE CHAR WITHOUT PARITY
PIAIN	LDAA 4,X  	;*
	BMI  PIAIN	;* WAIT FOR START BIT
	CLR  6,X 	;* SET 1/2 BIT TIME
	BSR  STRTBT	;* RESET TIMER
	BSR  WAITBT	;* WAIT FOR TIMER
	LDAB #$04	;* 
	STAB 6,X 	;* SET TIMER TO FULL BIT TIME
	ASLB		;* BIT COUNT=8
;* LOOP TO INPUT 8 DATA BITS
PIAIN2	BSR  WAITBT	;* WAIT BIT TIME XXXXXXXX
	SEC		;* 
	ROL  4,X 	;* SHIFT OUT DATA
	RORA		;* SHIFT IN A TO BUILD
	DECB		;* DECR BIT COUNT
	BNE  PIAIN2	;* BRA IF NOT DONE
	BSR  WAITBT	;* WAIT FOR STOP BIT
CHKSTB	LDAB 6,X	;* TEST FOR # STOP BITS XXXXXXXX
	ASLB		;* 
	BPL  RESTOR	;* 
	BSR  WAITBT	;* 
;* RESTORE REGISTERS + RETURN
RESTOR	LDX  XTMP	;*
	PULB		;* 
	RTS		;* 

;* ACIA CHAR INPUT ROUTINE
ACIAIN	LDAB 0,X	;* GET STAT REG XXXXXXXX
	LSRB		;* MOVE RDY BIT TO SIGN POS
	BCC  ACIAIN	;* WAIT IF NOT READY
	LDAA 1,X 	;* READ DATA
	BRA  RESTOR	;* BRA TO CLEANUP

;* I/O SETUP SUBROUTINE
IOAUX	STX  XTMP	;* SAVE XR XXXXXXXX
	LDX  #$8000	;* LOAD XR WITH PERIPH PTR
	LDAB 6,X 	;* TEST FOR ACIA OR PIA
	BITB #$20	;* 
	BEQ  AUXRET	;* BRA IF PIA
	LDX  IOVECT	;* GET ACIA ADDRESS
AUXRET	RTS		;* (LABEL/NM only?)

;* SUBR TO WAIT FOR 1 BIT TIME
;* AND RESET TIMER
WAITBT	TST  6,X  	;*
	BPL  WAITBT	;* 

;* SUBROUTINE TO START (RESET) BIT TIMER
STRTBT	INC  6,X  	;*
	DEC  6,X 	;* 
	RTS		;* 
;* OUTPUT 1 CHARACTER SUBROUTINE TO
;* PIA OR ACIA
OUT1CH	PSHB		;* SAVE ACC B XXXXXXXX
	BSR  IOAUX	;* SETUP FOR ROUTINE
	BNE  ACOUT	;* USE ACIA SUBR IF TRUE

;* PIA SOFTWARE UART CHAR OUTPUT
	LDAB #4 	;* 
	STAB 4,X 	;* SPACE FOR START BIT
	STAB 6,X 	;* SET TIMER FOR FULL
	LDAB #10 	;* INIT. BIT COUNTER
	BSR  STRTBT	;* RESET TIMER
;* BIT OUTPUT LOOP
$$loop: BSR  WAITBT	;* WAIT BIT TIME XXXXXXXX
	STAA 4,X 	;* SET BIT OUTPUT
	SEC		;* 
	RORA		;* SHIFT IN NEXT BIT
	DECB		;* DEC BYTE COUNT
	BNE  $$loop	;* BRA IF NOT LAST BIT
	BRA  CHKSTB	;* 

;* ACIA CHAR OUTPUT ROUTINE
ACOUT	LDAB 0,X	;* GET STAT REG XXXXXXXX
	LSRB		;* SHIFT RDY BIT TO C
	LSRB		;* 
	BCC  ACOUT	;* BRA IF NOT READY
	STAA 1,X 	;* STORE DATA
	BRA  RESTOR	;* GO CLEANUP

;* ERROR MESSAGE STRING
ERRMSG	FCB  $20,'E','R','R',$20,4	;* 

;* CR/LF AND TAPE HEADER STRING
CRLSTR	FCB  $0D,$0A,0,0,0,4,'S','1',4	;* 

;*
;* COMMAND CODE/ADDRESS TABLE
;*
CMDTBL	EQU  *  	;* 
	FCB  'B' 	;* 
	FDB  BKPCOM	;* 
	FCB  'D' 	;* 
	FDB  DMPCOM	;* 
	FCB  'E' 	;* 
	FDB  EXCOM	;* 
	FCB  'G' 	;* 
	FDB  GOCOM	;* 
	FCB  'L' 	;* 
	FDB  LOAD	;* 
	FCB  'M' 	;* 
	FDB  MEMCOM	;* 
	FCB  'P' 	;* 
	FDB  PUNCOM	;* 
	FCB  'R' 	;* 
	FDB  PRSTAK	;* 
	FCB  'S' 	;* 
	FDB  SYSCOM	;* 
	FCB  $1B 	;* (ESC) NEXT ROM OR USER DEFINE
	FDB  $7000	;* 
	FCB  0 	;* END

;*
;* INTERRUPT VECTORS
;*
	FDB  IRQ 	;* * FFF8 IRQ VECTOR
	FDB  SINT	;* * FFFA SWI VECTOR
	FDB  NMI 	;* * FFFC NMI VECTOR
	FDB  INIT	;* * FFFE RESTART VECTOR

zEND    EQU  *
	END		;* 

;* $E000 base                          | $FC00 base                            |
;* RAM                                 | RAM                                   |
;* $0000 (at least 256 bytes?)         | $0000                                 |
;* $8000 - 8003 ACIA                   | $8000 - $8003 ACIA                    |
;* $8004 - RAM?                        | $8004 - $8007 PIA                     |
;* $A000 - RAM                         | $A000 - Base Ram                      |
;* ROM                                 | ROM                                   |
;* $E000 ROM starts                    | $FC00 ROM starts                      |
;* $F000 ROM (4096 bytes, reset @FFFE) |                                       |
;* $F000 ROM (4096 bytes, reset @FFFE) |                                       |
;* $F000 ROM (4096 bytes, reset @FFFE) |                                       |
;* I/O                                 | IO                                    |
;* PIAC $C000 ?                        |                                       |
;* PIAD $D000 ? (6820/6821/6522)       |                                       |
;* ACIA $8000 ? (weird, 6850)          |                                       |
;*[ Fini ]***********************************************************************

;/* Local Variables: */
;/* mode: asm        */
;/* End:             */
