TITLE  Low level I/O Procedure Program     (Proj6_awanf.asm)

; Author: Fahad Awan
; Last Modified: 5/25/2021
; OSU email address:awanf@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:         6        Due Date: 6/6/2021
; Description: 

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays prompt then get's user's keyboard input into a memory location.
;
; Preconditions: do not use eax, ecx as arguments
; Postconditions: EAX modified
;
; Receives:
; promptOffset = prompt string offset
; storeLocation = variable to store user input
; lengthValue = maximum amount of characters to store
;	
; returns: user keyboard input stored in storeLocation
;		   amount of bytes read in EAX
; ---------------------------------------------------------------------------------

mGetString MACRO promptOffset:REQ, storeLocationOffset:REQ, lengthValue:REQ
	

.code
	PUSH	EDX
	PUSH	ECX

	MOV		EDX, promptOffset
	CALL	WriteString
	
	mov edx, storeLocationOffset	 ; point to the buffer
	mov ecx, lengthValue			 ; specify max characters
	call ReadString					 ; input the string
	
	POP		ECX
	POP		EDX
	
ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays string in console.
;
; Preconditions: do not use EDX as argument
; Postconditions: string at stringOffset printed to console
;
; Receives: stringOffset = offset of string to display
;	
;	
; returns: none
;		   
; ---------------------------------------------------------------------------------

mDisplayString MACRO stringOffset:REQ

	PUSH	EDX
	
	MOV		EDX, stringOffset
	CALL	WriteString
	
	POP		EDX
ENDM


; amount of integers to prompt/display
MAXNUMS=1

; ASCII codes
PLUS=43
MINUS=45
ZERO=48
NINE=57

; sdword limits
MAX= 2147483647
MIN= -2147483648

.data

	; readval proc

	enterNum		BYTE		"Enter a signed number: ",0
	errorMsg		BYTE		"ERROR: Number too large or invalid",0
	storedString	BYTE		16 DUP(?) 
	intHolder		SDWORD		?
	intArray		SDWORD		MAXNUMS DUP(?)				; array of entered strings
;	indexer			DWORD		0

	; writeval proc

	someNum			SDWORD		2147483647
;	outputString	BYTE		16 DUP(?)
;	otherString		BYTE		"Hope this doesn't print",0
;	reversedString	BYTE		16 DUP(?)
	;doesThisWork	BYTE		"Testing",0,"Worked!"

	; math proc
	
	sumInfo			BYTE		"The sum of the numbers is: ",0
	averageInfo		BYTE		"The average of the numbers is: ",0
	delimiter		BYTE		"  ",0
	userNumInfo		BYTE		"These are the numbers you entered:",13,10,0




.code
main PROC

	; gets and converts MAXNUMS strings to an array of integers

;	PUSH	OFFSET intArray
	
	MOV		ECX, MAXNUMS		; amount of strings to gather from user
	MOV		EDI, OFFSET intArray
	
_getNums:			; gets MAXNUMS numbers, converts to sdword, stores them in intArray
	
	PUSH	OFFSET intHolder
	CALL	ReadVal
	MOV		EAX, intHolder
	MOV		[EDI], EAX
	ADD		EDI, 4

	LOOP	_getNums

	
	; calculate and stores sum and average
	
	PUSH	OFFSET	averageInfo
	PUSH	OFFSET	sumInfo
	PUSH	OFFSET	intArray
	CALL	Math

	CALL	CrLf
	MOV		EDX, OFFSET userNumInfo
	mDisplayString	EDX

	; prints userArray
;
	MOV		EDI, OFFSET intArray
	MOV		ECX, LENGTHOF intArray

_printArray:
	MOV		EAX, [EDI]
	PUSH	EAX
	CALL	WriteVal
	mDisplayString	OFFSET delimiter
	ADD		EDI, 4
	LOOP	_printArray
	CALL	CrLf


	Invoke ExitProcess,0	; exit to operating system
main ENDP



; ---------------------------------------------------------------------------------
; Name: ReadVal
; 
; Converts a string of digits into a signed integerTranslator. 
;
; Preconditions: 
;
; Postconditions: 
;
; Receives: 
; [ebp+16] = type of array element
; [ebp+12] = length of array
; [ebp+8] = address of array
; arrayMsg, arrayError are global variables
;
; returns: eax = smallest integerTranslator
; ---------------------------------------------------------------------------------
ReadVal PROC

	
	LOCAL		negBool:BYTE, lengthCounter:DWORD, intAccumulator:SDWORD, inputLength:DWORD

;	PUSH	EBP
;	MOV		EBP, ESP  TODO: RESTORE OTHER REGS
	
	PUSH	ECX
	PUSH	EDI

	;prompts and fills userStrings array with input

_rePrompt:
	mGetString	OFFSET enterNum, OFFSET storedString, LENGTHOF storedString   ;need to get these from stack

	MOV			inputLength, EAX	; length of user input (includes sign if present)

	CMP			EAX,0		; user didn't enter anything
	JE			_invalidItem


	MOV			intAccumulator, 0 
	MOV			ESI, OFFSET storedString
	MOV			ECX, LENGTHOF storedString    
	XOR			EAX, EAX	; clear accumulator for conversion
	MOV			lengthCounter, 0
	CLD

_toIntLoop:
	LODSB						; load string digit from inString into AL

	; this all gets skipped after first digit checked for sign

	INC			lengthCounter	; lengthCounter at first digit, check sign to be + or - or none
	CMP			lengthCounter, 1
	JNE			_continueCalcs	; past the first digit, so don't check for sign
	CMP			EAX, MINUS		; compare ascii of first digit with ascii of -
	JNE			_checkPlus		; if no - sign present check for + sign
	MOV			negBool, 1		; - sign present raise the negBool flag
	LOOP		_toIntLoop		; move to next digit, a negative sign was found
	
_checkPlus:	
	
	CMP			EAX, PLUS		; compare ascii of first digit with ascii of +
	JNE			_continueCalcs	; if no + sign present
	LOOP		_toIntLoop		; move to next digit, nothing to calculate



_continueCalcs:

	; checks to see if the digit string is an actual numerical digit. 
	CMP			EAX, 0			; end of the string (null terminator)
	JE			_endCalculations

	CMP			EAX, ZERO
	JL			_invalidItem	;invalid entry ascii was less than ZERO
	CMP			EAX, NINE
	JG			_invalidItem	;invalid entry ascii was greater than NINE
	

	MOV			EBX, EAX		; store a copy in EBX
	SUB			EAX, 48			; determines numerical representation of single valid digit
	MOV			EBX, EAX		; 
	MOV			EAX, intAccumulator	; gets the previous calculations
	MOV			EDX, 10			; prepare for multiplication
	IMUL		EDX				; 10(previous calculations)
	
	JO			_invalidItem		; checks for overflow flag

	ADD			EAX, EBX		; +(49-digit)
	MOV			intAccumulator, EAX	; store accumulation
	XOR			EAX, EAX		; reset eax

	LOOP	_toIntLoop

_endCalculations:

	CMP			negBool, 1
	JNE			_writeToConsole
	NEG			intAccumulator		; negBool was raised, negate the number
	MOV			negBool, 0			; reset negBool

_writeToConsole:

	MOV		EAX, intAccumulator
	CALL	WriteInt
	CALL	CrLf
	JMP		_return

	; invalid entries 

_invalidItem:
	MOV		EDX, OFFSET errorMsg
	CALL	WriteString
	CALL	CrLf
	JMP		_rePrompt		; prompt user again for valid input

_return:					; TODO: save the SDWORD into an array



	; stores the valid input in the intArray array as SDWORDS

	MOV	EDI, [EBP+8]	; OFFSET intHolder
	MOV [EDI], EAX






	POP	EDI
	POP	ECX


_theEnd:	
	RET 4
ReadVal ENDP



; calculates sum and average
Math PROC

	PUSH	EBP
	MOV		EBP, ESP

	PUSH	ECX
	PUSH	ESI
	PUSH	EAX
	PUSH	EBX

	
	;[EBP+8]=intArray offset
	;[EBP+12] = sumInfo
	;[EBP+16]=averageInfo


	MOV		ECX, MAXNUMS	; loop maxnums times
	MOV		ESI, [EBP+8]	; intArray offset
	XOR		EAX, EAX		; prepare for accumulation

_sumLoop: ; iterates thru array adding nums
	
	ADD		EAX, [ESI]
	ADD		ESI, 4
	LOOP	_sumLoop

	CALL	CrLf		


	mDisplayString [EBP+12]  ; displays sumInfo

	
	PUSH	EAX				; the sum
	CALL	WriteVal
	CALL	CrLf

	; calc/display avg

	CDQ						; sign extend
	MOV		EBX, MAXNUMS	
	IDIV	EBX				; divide by amount of user inputs
	CALL	CrLf

	mDisplayString [EBP+16]		;averageInfo strng

	PUSH	EAX						; the average
	CALL	WriteVal				
	CALL	CrLf


	POP		EBX
	POP		EAX
	POP		ESI
	POP		ECX

	POP		EBP
	RET		12

Math ENDP


WriteVal PROC
	LOCAL	testNum:SDWORD, negFlag:DWORD, minFlag:DWORD
	.data
		outputString	BYTE	16 DUP(?)
		reversedString	BYTE	16 DUP(?)

	.code
	; LOCAL does stack frame initialization 

	PUSH	EAX
	PUSH	EDI
	PUSH	ECX
	PUSH	EBX
	PUSH	ESI


	MOV		EAX, [EBP+8]
	MOV		testNum, EAX

	
	MOV		EDI, OFFSET outputString;outputString

	MOV		AL,0 ; null terminator at beginning
	
	STOSB
	CLD
	

	;MOV		EDI, OFFSET outputString
	

	; determines if the number is positive or 0

	CMP		testNum, -1
	JG		_positiveOrZeroNum

	; tests to see if this number is the minimum SDWORD special case
	CMP		testNum, MIN
	JNE		_notMinimumNum
	MOV		minFlag, 1		; raise the min flag
	
	; all other negative numbers
_notMinimumNum:

	NEG		testNum
	MOV		negFlag, 1 ;negFlag
;	PUSH	EAX
	JMP		_loopSetup
	

_positiveOrZeroNum:
	MOV		negFlag, 0
;	PUSH	EAX


_loopSetup:
	
	MOV		EAX, testNum


	CMP		minFlag,1
	JNE		_notSpecialCase
	DEC		EAX			; decrement the max num

_notSpecialCase:
	MOV		EBX, 10		; divisor
	MOV		ECX, LENGTHOF outputString	



_stringLoop:

;	XOR		EDX, EDX

	CDQ					; prep div

	IDIV	EBX
	PUSH	EAX
	MOV		AL, DL
	ADD		AL, 48

	; special case min flag raised
	CMP		minFlag, 1
	JNE		_continueLoop
	DEC		minFlag			; set minFlagg to 0
	INC		AL				; change the digit from 7 to 8
	

_continueLoop:
	STOSB


	POP		EAX
	CMP		EAX, 0
	JE		_stringComplete





	LOOP	_stringLoop

_stringComplete:
	
;	POP		EAX
	CMP		negFlag, 1
	JNE		_displayString
	MOV		AL, MINUS
	STOSB
	DEC		ECX  ;accomodates for - sign


_displayString:

	; need to reverse string for display here
	MOV		EDI, OFFSET reversedString
	MOV		ESI, OFFSET outputString
	ADD		ESI, LENGTHOF reversedString ; point at end of outputString
	DEC		ECX
	SUB		ESI, ECX
	MOV		ECX, LENGTHOF reversedString

;	DEC		ESI

_revLoop:
	STD
	LODSB
	CLD
	STOSB
	LOOP	_revLoop

	
	
	mDisplayString	OFFSET reversedString

	
	POP	ESI
	POP	EBX
	POP	ECX
	POP	EDI
	POP	EAX


	;POP		EBP
	RET		4

WriteVal ENDP




END main
