# RT68mx

Microware's RT/68MX Real Time OS for the Motorola 6800 (1977).

RT68mx is a real time OS by Microware. Microware has been kind enough to allow us to make the code available. It's a very interesting OS as it's quite small, about 1K in size, has very little overhead using 128 bytes of RAM for the OS. The rest is for programs/applications/processes.

RT68mx can handle 8 processes.

# Table of Contents

1. [History](#History)
2. [Notes](#Notes)
3. [Files](#Files)

# History

I grew up working with systems such as SWTPC and operating systems such as TSC FLEX, Microware's OS-9 and RT/68MX. It was a fun and interesting time. While today we have much more resource and better tools the past wasn't all that bad. Things were a lot more manual but the learning experience was what helped us to build what we have today.

# RT68/MX

This version of RT68mx source code has been modified to specifically assemble properly with the asl macro assembler ([links below](#Source)). I've also taken the liberty to clean up and reformat the source. Sorry I understand why it was done but I've always hated the way the source code looked.

RT/68 provides three modes which are mutually exclusive: Console Monitor to load, save and debug programs; Single Task Mode to execute existing Mikbug(TM) software without modification; and Multi-Task Mode which is the real time multiprogramming mode.

## rt68.asm

This file is just the rt68mx.asm modified to work on the [68Retro](https://github.com/crsjones/68Retro) board. I have the ACIA at $E000, the PIA at $8004 and the ROM from $E000-$FFFF ($E100-$E1FF are for IO). Initial testing suggets this version works. I don't have the cassette tape interface built yet.

# A/BASIC

A/BASIC is a basic compiler for use with RT68mx. The compiled code can be run as a process under  RT68mx. The compiler itself runs as a process.

This is a work in progress. Currently there appear to be a few different 'ABASIC's. One is the ABASIC/RTEDIT that belongs with RT/68MX. This doesn't run under an operating system like FLEX or OS-9 but rather RT/68MX and is loaded, compiles and saves to tape. This version can run mulit-task or single task. We currently have an rtbasic-10c.s19 file (A/BASIC) from the manual. We're working to disassemble the code and will post that here. Then there is a modified version that runs under 6800 FLEX. This version is single task only. Then there appears to be another that I don't have details for yet.

The code in the ABASIC-FLEX directory is the 6800(?) FLEX version.

I'll update this as I get things sorted out better.

# RTEDIT

RTEDIT is an editor that runs under RT68mx that can be used to edit the A/BASIC code.

This is a work in progress. There are some files under the FuFu Flex collection which we think is a modified version to work under Flex. We do have a file: rtedit.s19, which we are in the process if disassembling. We will post the results here.

# Mikbug

This version of 6800 mikbug source code has been modified to specifically assemble properly with the asl macro assembler. Sorry I understand why it was done but I've always hated the way the source code looked.

MIKBUG is a ROM monitor from Motorola for the Motorola 6800 8-bit microprocessor. It is intended to "be used to debug and evaluate a user's program".[1]

MIKBUG was distributed by Motorola in 1974[2] on a 1 K ROM chip part number MCM6830L7. It occupied 512 bytes on the chip, where the remainder was occupied by a 256 byte MINIBUG monitor—a stripped-down version of MIKBUG—and a 256 byte "test pattern" (really just a different and unused revision of MINIBUG). It requires 128 bytes of random-access memory for operation. Its functionality was similar to other monitors of the early microcomputer era, such as the Intel MON-80 for the Intel 8080.

MIKBUG is initiated when power is first applied to the system, or when the system RESET button is pressed. It assumes the presence of a terminal that the user will use to issue commands.

List of commands and functions
| Command | Function |
|--|--|
| L	| Load a program from a paper tape reader on the attached terminal. The program tapes may be a "formatted binary object tapes or MIKBUG punched memory dump tapes". |
| M	| Examine or change memory contents. |
| P	| Print and/or punch memory contents. The user stores the beginning address in locations A002h and A003h, and the ending address in A004h and A005h before entering this command. The data is punched in absolute binary format. |
| R	| Display the contents of the CPU registers. |
| A	| Change the contents of a register. |
| G	| Run a user's program. |

Callable functions include input and output of a character on the terminal, input and output of a byte in hexadecimal format, print a string terminated by EOT, and terminate the current program and return control to MIKBUG.

MIKBUG allows the user to install an interrupt handler using the M command to specify the handler address.

# Minibug

| Range | Function |
|--|--|
| FFFE-FFFF | Restart Vectors |
| FF80-FFFd | ? |
| FF00-FF7F | RAM (6810) |
| FE00-FEFF | Minibug |
| FCF6-FDFF | ? |
| FCF4-FCF5 | UART |

L
M
R
P
G

E000-E1FF - Minibug ???

## Various notes:

### Jump table

The beginning of the monitor ROM consists of a jump table to common routines further into the ROM.

```
RETURN	EQU	$C000	RETURN TO PROMPT
OUTCHAR	EQU	$C003	OUTPUT CHAR ON CONSOLE
INCHAR	EQU	$C006	INPUT CHAR FROM CONSOLE AND ECHO
PDATA	EQU	$C009	PRINT TEXT STRING @ X ENDED BY $04
OUTHR	EQU	$C00C	PRINT RIGHT HEX CHAR @ X
OUTHL	EQU	$C00F	PRINT LEFT HEX CHAR @ X
OUT2HS	EQU	$C012	PRINT 2 HEX CHARS @ X
OUT4HS	EQU	$C015	PRINT 4 HEX CHARS @ X
INHEX	EQU	$C018	INPUT 1 HEX CHAR TO A. CARRY SET = OK
INBYTE	EQU	$C01B	INPUT 1 BYTE TO A. CARRY SET = OK
BADDR	EQU	$C01E	INPUT ADDRESS TO X. CARRY SET = OK
```

https://www.waveguide.se/?article=mc3-monitor-11

Vector table
The monitor sets up a vector table in RAM for access to various routines. Each vector consists of three bytes. A jump ($7E) and then the address to the routine. This allows software to use different routines for these functions.

```
CONSVEC	EQU	$7FE5	CONSOLE STATUS VECTOR
CONOVEC	EQU	$7FE8	CONSOLE OUTPUT VECTOR
CONIVEC	EQU	$7FEB	CONSOLE INPUT VECTOR
TMOFVEC	EQU	$7FEE	TIMER OVER FLOW INTERUPT VECTOR
TMOCVEC	EQU	$7FF1	TIMER OUTPUT COMPARE INTERUPT VECTOR
TMICVEC	EQU	$7FF4	TIMER INPUT CAPTURE INTERUPT VECTOR
IRQVEC	EQU	$7FF7	IRQ INTERUPT VECTOR
SWIVEC	EQU	$7FFA	SWI INTERUPT VECTOR
NMIVEC	EQU	$7FFD	NMI INTERUPT VECTOR
```

The interrupt vectors are a mirror of the CPU vectors. After initialization these all points to an RTI that effectively disables the interrupt. One exception is the SWI vector that points to a stack printout and then back to the monitor prompt. Pressing 'G' will continue execution after an SWI. The three vectors for handling the console I/O are CONSVEC, CONOVEC and CONIVEC. Think of them as stdin and stdout in the Unix world. They point to the routines for the console interface and can be changed and redirected for other output or input. 

| Command | Function |
| ------- | -------- |
| CONSVEC | Status vector. Returns the number of characters in buffer in A-acc. |
| CONIVEC | Input vector. Returns a character in A-acc. |
| CONOVEC | Output vector. Sends a character in A-acc. |

Jump table
The beginning of the monitor ROM consists of a jump table to common routines further into the ROM.

```
RETURN	EQU	$C000	RETURN TO PROMPT
OUTCHAR	EQU	$C003	OUTPUT CHAR ON CONSOLE
INCHAR	EQU	$C006	INPUT CHAR FROM CONSOLE AND ECHO
PDATA	EQU	$C009	PRINT TEXT STRING @ X ENDED BY $04
OUTHR	EQU	$C00C	PRINT RIGHT HEX CHAR @ X
OUTHL	EQU	$C00F	PRINT LEFT HEX CHAR @ X
OUT2HS	EQU	$C012	PRINT 2 HEX CHARS @ X
OUT4HS	EQU	$C015	PRINT 4 HEX CHARS @ X
INHEX	EQU	$C018	INPUT 1 HEX CHAR TO A. CARRY SET = OK
INBYTE	EQU	$C01B	INPUT 1 BYTE TO A. CARRY SET = OK
BADDR	EQU	$C01E	INPUT ADDRESS TO X. CARRY SET = OK
```

The reason for using a jump table is that the contents of the monitor ROM can be altered without affecting these addresses meaning that programs utilizing these routines will not have to be changed.

# Systems

I'll be using the MP-02 from https://github.com/crsjones/68Retro . I ordered up some boards from JLCPCB and I'm building those. I also have Corsham SS50 6800 board, which I'll build later. I would expect this code to also work with real SWTPC 6800 processor boards and Motorola MEK6800D2 (with some mods). Fredric Brown of Peripheral Technology also has 6800 boards that should work: https://peripheraltech.com/SWTPC%20Reprodution.htm

# Memory layout (WIP)

| Device | Description |
|--|--|
| RAM | $0000 at least 128 bytes, $A000 |
| ROM | $E000 or $FC00 (2764) |
| ACIA | $8000-8001 (where FLEX expects it) |
| PIA | $8004-8007 |

| Start | End  |                               |
|-------|------|-------------------------------|
| E400  | FFFF | Images of RT/68 ROM due to    |
|       |      | partial address decoding      |
|       |      | to allow access to interrupt  |
|       |      | vector addresses              |
| E000  | E3FF | RT/68 Program (ROM)           |
| A080  | DFFF | Not used - available for      |
|       |      | RAM, ROM or I/O               |
| A000  | A07F | Operating system RAM:         |
|       |      | A000-A013 = Monitor temp RAM  |
|       |      | A014-A04F = Stack             |
|       |      | A050-A07F = Status table (not |
|       |      | used in single tasking mode)  |
| 8004  | 8007 | PIA (control or console)      |
| 8000  | 8001 | ACIA (console, optional)      |
| 000C  | 7FFF | Avail. For RAM, ROM or I/O    |
| 0000  | 000B | RT/68 multiprogramming exec.  |
|       |      | temp. (multi-task mode only)  |

# RT/68 System Entry Points

There are several points a program or rask may jump to
to enter various system modes or functions.

| Description                        | Addr | Label  | Addr  |
|------------------------------------|------|--------|-------|
| Console/System cold start          | E147 | INIT   | FD47  |
| Console monitor soft start/reentry | E16A | CONENT | FD6A  |
| or ...                             | E0E3 | CONTRL | FCE3  |
| Console monitor error entry        | E1E8 | ERTEST | FDE8  |
| RT Exec cold start                 | E20C | SYSCOM | FE0C  |
| RT Exec warm start                 | E2F3 | EXEC03 | FEF3  |

## FLEX Adaptation Guide

3.1 Console Driver Routine Descriptions

A small portion of the 8K space where FLEX resides has been set aside for the Console Drivers. This area begins at $B390 and runs through $B3E4. If the user's driver routines do not fit in this space, the overflow will have to be placed somewhere outside the 8K FLEX area. To inform FLEX where each routine begins, there is a table of addresses located between $B3E5 and $B3FC. This table has 12 two-byte entries, each entry being the address of a particular routine in the Console I/O Driver package. It should look something like this:


```
* CONSOLE I/O DRIVER VECTOR TABLE
   ORG $B3E5 TABLE STARTS AT $B3E5
INCHNE FDB XXXXX INPUT CHARACTER W/O ECHO
IHNDLR FDB XXXXX IRQ INTERRUPT HANDLER
SWIVEC FDB XXXXX SWI VECTOR LOCATION
IRQVEC FDB XXXXX IRQ VECTOR LOCATION
TMOFF  FDB XXXXX TIMER OFF ROUTINE
TMON   FDB XXXXX TIMER ON ROUTINE
TMINT  FDB XXXXX TIMER INITIALIZATION
MONITR FDB XXXXX MONITOR ENTRY ADDRESS
TINIT  FDB XXXXX TERMINAL INITIALIZATION
STAT   FDB XXXXX CHECK TERMINAL STATUS
OUTCH  FDB XXXXX OUTPUT CHARACTER
INCH   FDB XXXXX INPUT CHARACTER W/ ECHO 
```

Entry points?

```
  "ACIAIN": "FF84",
  "ACOUT": "FFC0",
  "BOUT": "FCCE",
  "CHKSTB": "FF78",
  "CMSRCH": "FD81",
  "IN1CHR": "FF50",
  "INBYTE": "FF59",
  "INCH": "FC78",
  "INEEE": "FDAC",
  "INHEX": "FCAA",
  "INIT": "FD47",
  "INTBAD": "FE95",
  "INTRET": "FF2B",
  "JOUT1C": "FD09",
  "OUT1CH": "FFA6",
  "OUT2H": "FCBF",
  "OUT2HS": "FCCA",
  "OUT4HS": "FCC8",
  "OUTCH": "FC75",
  "OUTEEE": "FDD1",
  "OUTHL": "FC67",
  "OUTHR": "FC6B",
  "OUTLDR": "FCF4",
  "OUTS": "FCCC",
  "PIAIN": "FF5E",
  "PIAIN2": "FF6D",
  "POUT1": "FFB5",
  "RNINT2": "FED4",
  "RNINT3": "FED6",
  "RUNINT": "FECB",
  "SINT": "FE80",
  "TAPOUT": "FCEE",
```

# RT/68 Hardware Configuration

The addresses of the RT/68 ROM range from E000 to E3FF. However, the restart and interrupt vectors are also contained in the ROM so it must be able to respond to all addresses

MCM6830 is not a 27xx compatible chip

 | CPU     | ROM     | Notes    |
 |---------|---------|----------|
 | A0 - A9 | A0 - A9 |          |
 | Ph2     | CS0     | Ph2 == E |
 | R/-W    | CS1     |          |
 | A15     | CS2     |          |
 | A13+A14 | CS3     |          |

from E000 - FFFF. This menas that address lines A10 through A12 can not be decoded. A circuit that will accomplish this is illustrated above.

If full decode is desired, a separate PROM that has the correct interrupt vectors included can be placed at the top of memory. The vector data is found on the last page of the source listing.

Any circuit that accepts the MC6830L7-L8 Mikbug(TM) ROM will properly decode the addresses for the RT/68 ROM.

The circuits on the following pages give example configurations for several option features. The abort switch may be connected to the control terminal PIA input CA2. The switch circuit must have a normally low, debounced function. If this feature is not used, ground the CA2 pin.

Two circuits are shown that can provide a stable, precise clock signal for the RT/68 multitask executive, This is also an optional feature. Both circuits cost less than a dollar or so to construct and are extremely simple, but provide an accurate reference signal. This clock signal should be in the range if 10 to 100 Hz for optimum operation.

## Modification for use with the 68Retro MP02A clone

| Addr | Description |
|--|--|
| 0000 | RT68MX Real Time OS variables |
| A000 | RT68MX Monitor and stack |
| E000 | Start of ROM code |
| F000 | ACIA ($F000-02) and PIA ($F004-08) |
| FFF8 | Interupt vectors for RT68MX ROM |

I'm experimenting with the RT68MX code but keeping the entry points so existing code (RT/EDIT & A/BASIC) works.

## Notes

I've currently added an IFDEF to allow the RT/68MX to be compiled at $FC00 which should allow us to avoid the cutting and bodging of the address lines.

# Files

| File | Description |
| -- | -- |
| abasic-10c.s19 | |
| abasic.asm | A/BASIC Disassembly (WIP)|
| ABASIC-FLEX | Dir |
| abasic.info | f9dasm info file |
| docs | Dir |
| LICENSE | |
| Makefile | |
| mikbug.asm | |
| minibug.asm | |
| README.md | |
| rt68mx.asm | RT68mx 6800 asm source |
| rt68mx.inc | |
| docs/RT68MX-Manual.pdf | RT68MX Manual |
| rtbasic-10c.s19 | |
| rtedit-10c.s19 | |
| rtedit.asm | RTEdit disaeembly |
| rtedit.info | f9dasm info file |
| rtedit.s | |
| rtedit.s19 | |
| s0.sh | Shell script to create S0 record |
| src | Safe place for original source files|
| src/rt68mx.s | Code that closely matches the original S19 file in the RT68MX Manual |
| src/rt68mx-s.lst | Listing generated by ASL |

# Source

- FuFu mail list - <mailto:fufu-subscribe@flexusergroup.com>
- http://www.swtpcemu.com/swtpc/Downloads.htm
- http://www.flexusergroup.com:8080/
- AS (I call it ASL) - http://john.ccac.rwth-aachen.de:8000/as/

# Credits

- Microware, creaters of RT68mx & OS9.
- Stanley Ruppert
- Michael Evenson
