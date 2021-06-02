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
;		   amount of bytes read in userInputLength
; ---------------------------------------------------------------------------------

mGetString MACRO promptOffset:REQ, storeLocationOffset:REQ, maxLength:REQ, userInputLength:REQ
	

.code
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX

	MOV		EDX, promptOffset
	CALL	WriteString
	
	MOV		EDX, storeLocationOffset	 ; point to the buffer
	MOV		ECX, maxLength			 ; specify max characters
	CALL	ReadString					 ; input the string
	MOV		userInputLength, EAX
	
	POP		EAX
	POP		ECX
	POP		EDX
	
ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays string in console.
;
; Preconditions: do not use EDX as argument (needs testing)
; Postconditions: string starting at stringOffset printed to console
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
MAXNUMS=3

; ASCII codes
PLUS=43
MINUS=45
ZERO=48
NINE=57

LENGTHLIMIT=150

; sdword limits
MAX= 2147483647
MIN= -2147483648

.data

	enterNum		BYTE		"Enter a signed number: ",0
	errorMsg		BYTE		"ERROR: Number too large, too long, or invalid",0
	intHolder		SDWORD		?
	intArray		SDWORD		MAXNUMS DUP(?)				; array of entered strings
	
	sumInfo			BYTE		"The sum of the numbers is: ",0
	averageInfo		BYTE		"The average of the numbers is: ",0
	delimiter		BYTE		"  ",0
	userNumInfo		BYTE		"These are the numbers you entered:",13,10,0




.code
main PROC

	; gets and converts MAXNUMS strings to an array of integers


	
	MOV		ECX, MAXNUMS		; amount of strings to gather from user
	MOV		EDI, OFFSET intArray
	
_getNums:			; gets MAXNUMS numbers, converts to sdword, stores them in intArray
	
	PUSH	OFFSET	errorMsg
	PUSH	OFFSET	enterNum
	PUSH	OFFSET	intHolder
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
; Prompts user to enter a number, validates input, then converts string of digits into a signed integer. 
;
; Preconditions: errorMsg, enterNum are global strings
;				 intHolder is a global SDWORD
;				 mGetString macro exists
;
; Postconditions: none
;
; Receives: 
;			[EBP+8]  = offset of intHolder global SDWORD
;			[EBP+12] = offset of enterNum global string
;			[EBP+16] = offset of errorMsg global string
;
; returns: intHolder = valid user input as an SDWORD
; ---------------------------------------------------------------------------------
ReadVal PROC

	
	LOCAL		lengthCounter:DWORD, intAccumulator:SDWORD, inputLength:DWORD
	
	.data
		storedString		BYTE		LENGTHLIMIT DUP(?)
		negBool				BYTE		0 

	.code

	
	PUSHAD				; preserve registers

	;prompts and fills userStrings array with input

_rePrompt:

	;[EBP+12]=enterNum string
	;[EBP+16]=errormsg string
	mGetString	[EBP+12], OFFSET storedString, LENGTHOF storedString, inputLength   ;need to get these from stack. 

	; TODO some kind of length validations? might need to limit length

	CMP		inputLength, 15		; num too long
	JGE		_invalidItem

	CMP		inputLength,0		; user didn't enter anything
	JE		_invalidItem

	; user entered only a + or - sign

	CMP		inputLength, 1
	JNE		_validLength
	MOV		ESI, OFFSET storedString
	LODSB	
	CMP		AL, MINUS
	JE		_invalidItem
	CMP		AL, PLUS
	JE		_invalidItem


_validLength:


	MOV		intAccumulator, 0 
	MOV		ESI, OFFSET storedString
	MOV		ECX, LENGTHOF storedString    
	XOR		EAX, EAX	; clear accumulator for conversion
	MOV		lengthCounter, 0
	CLD

_toIntLoop:
	LODSB						; load string digit from inString into AL

	; this all gets skipped after first digit checked for sign

	INC		lengthCounter	; lengthCounter at first digit, check sign to be + or - or none
	CMP		lengthCounter, 1
	JNE		_continueCalcs	; past the first digit, so don't check for sign
	CMP		EAX, MINUS		; compare ascii of first digit with ascii of -
	JNE		_checkPlus		; if no - sign present check for + sign
	MOV		negBool, 1		; - sign present raise the negBool flag
	LOOP	_toIntLoop		; move to next digit, a negative sign was found
	
_checkPlus:	
	
	CMP		EAX, PLUS		; compare ascii of first digit with ascii of +
	JNE		_continueCalcs	; if no + sign present
	LOOP	_toIntLoop		; move to next digit, nothing to calculate



_continueCalcs:

	; checks to see if the digit string is an actual numerical digit. 
	CMP		EAX, 0			; end of the string (null terminator)
	JE		_endCalculations

	CMP		EAX, ZERO
	JL		_invalidItem	;invalid entry ascii was less than ZERO
	CMP		EAX, NINE
	JG		_invalidItem	;invalid entry ascii was greater than NINE
	

	MOV		EBX, EAX		; store a copy in EBX
	SUB		EAX, 48			; determines numerical representation of single valid digit
	MOV		EBX, EAX		; 
	MOV		EAX, intAccumulator	; gets the previous calculations
	MOV		EDX, 10			; prepare for multiplication
	IMUL	EDX				; 10(previous calculations)
	

	ADD		EAX, EBX		; +(49-digit)
	MOV		intAccumulator, EAX	; store accumulation


	JO		_overflowDetected		; checks for overflow flag


	XOR		EAX, EAX		; reset eax

	LOOP	_toIntLoop

_overflowDetected:

	CMP		negBool,1
	JNE		_invalidItem
	;MOV		EAX, MIN
	;NEG		EAX
	CMP		intAccumulator, MIN
	JNE		_invalidItem


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
;	MOV		EDX, [EBP+16]	; errormsg String
	mDisplayString	[EBP+16]
	CALL	CrLf
	MOV		negBool, 0			; reset negBool
	JMP		_rePrompt		; prompt user again for valid input

_return:					; TODO: save the SDWORD into an array



	; stores the valid input in the intArray array as SDWORDS

	MOV		EDI, [EBP+8]	; OFFSET intHolder
	MOV		[EDI], EAX

	POPAD


_theEnd:	
	RET 12
ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: Math
; 
; Calculates and displays the sum and average (floor rounding) of an array.
;
; Preconditions: errorMsg, enterNum are global strings
;				 intHolder is a global SDWORD
;
; Postconditions: none
;
; Receives: 
;			[EBP+8]  = offset of intHolder global SDWORD
;			[EBP+12] = offset of enterNum global string
;			[EBP+16] = offset of errorMsg global string
;
; returns: intHolder = valid user input as an SDWORD
; ---------------------------------------------------------------------------------

Math PROC

	PUSH	EBP
	MOV		EBP, ESP
	
	PUSHAD

	
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

	POPAD
;	POP		EBX
;	POP		EAX
;	POP		ESI
;	POP		ECX

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

;	PUSH	EAX
;	PUSH	EDI
;	PUSH	ECX
;	PUSH	EBX
;	PUSH	ESI
;	PUSH	EDX
	PUSHAD

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

;	POP	EDX
;	POP	ESI
;	POP	EBX
;	POP	ECX
;	POP	EDI
;	POP	EAX
	POPAD

	RET		4

WriteVal ENDP




END main
