TITLE  Low level I/O Procedure Program     (Proj6_awanf.asm)

; Author: Fahad Awan
; Last Modified: 6/2/2021
; OSU email address:awanf@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:         6        Due Date: 6/6/2021
; Description: Program displays program title and programmer.
;			   Program prompts user for 10 strings of digits up to 15 (inclusive) digits long.
;			   Program validates that the string entry is valid and in the acceptable range of an SDWORD.
;			   Program converts the 10 user entered strings to integers.
;			   Program displays the user entered strings of digits.
;			   Program calculates and displays the sum and average of the validated user input.
;			   Program bids farewell.

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

mGetString MACRO promptOffset:REQ, storeLocationOffset:REQ, maxLength:REQ, userInputLengthOffset:REQ
	

.code
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX
	PUSH	EBX

	MOV		EDX, promptOffset
	CALL	WriteString
	
	MOV		EDX, storeLocationOffset	 ; point to the buffer
	MOV		ECX, maxLength				 ; specify max characters
	CALL	ReadString					 ; input the string
	MOV		[userInputLengthOffset], EAX
	
	POP		EBX
	POP		EAX
	POP		ECX
	POP		EDX
	
ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays string in console.
;
; Preconditions: do not use EDX as argument (untrue)
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
MAXNUMS=10

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

	progTitle		BYTE		"Welcome to the Low level I/O Procedure Program by Fahad",13,10,13,10,0

	enterNum		BYTE		"Enter a signed number: ",0
	errorMsg		BYTE		"ERROR: Number too large, too long (15 digits max), or invalid",0
	intHolder		SDWORD		?
	intArray		SDWORD		MAXNUMS DUP(?)				
	
	sumInfo			BYTE		"The sum of the numbers is: ",0
	averageInfo		BYTE		"The average of the numbers is: ",0
	delimiter		BYTE		"  ",0
	userNumInfo		BYTE		"These are the numbers you entered:",13,10,0

	farewell		BYTE		"Thanks for using this program! Bye!",13,10,0




.code
main PROC


	mDisplayString OFFSET progTitle ; display prog title and progr name
	

	MOV		ECX, MAXNUMS			; amount of strings to gather from user
	MOV		EDI, OFFSET intArray
	
	; prompts user for MAXNUMS amount of strings and converts them to SDWORDS

_getNums:	
	
	PUSH	OFFSET	errorMsg
	PUSH	OFFSET	enterNum
	PUSH	OFFSET	intHolder
	CALL	ReadVal
	
	; stores the generated integer in an array

	MOV		EAX, intHolder
	MOV		[EDI], EAX
	ADD		EDI, 4

	LOOP	_getNums

	; displays the array of user entered strings as strings

	
	CALL	CrLf
	mDisplayString	OFFSET userNumInfo

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



	; calculates, stores, and displays sum and average
	
	PUSH	OFFSET	averageInfo
	PUSH	OFFSET	sumInfo
	PUSH	OFFSET	intArray
	CALL	Math

	
	; displays farewell message to the user
	
	CALL	CrLf
	mDisplayString	OFFSET farewell




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

	
	LOCAL		lengthCounter:DWORD, intAccumulator:SDWORD, inputLength:DWORD, negBool:BYTE, storedString[16]:BYTE


	
	PUSHAD				; preserve registers

	; prompts user for input

_rePrompt:
	
	MOV		negBool, 0


	LEA		ECX, storedString
	LEA		EBX, inputLength

	mGetString	[EBP+12], ECX, LENGTHLIMIT, EBX


	; validates length of user inputs

	CMP		inputLength, 15		; num too long
	JG		_invalidItem

	CMP		inputLength,0		; user didn't enter anything
	JE		_invalidItem

	; user entered only a + or - sign

	CMP		inputLength, 1
	JNE		_validLength
	LEA		ESI, storedString
	LODSB	
	CMP		AL, MINUS
	JE		_invalidItem
	CMP		AL, PLUS
	JE		_invalidItem


_validLength:


	MOV		intAccumulator, 0 
	LEA		ESI, storedString
;	MOV		ESI, EBX ;OFFSET storedString
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
	
	JC		_invalidItem	; carry flag 


	ADD		EAX, EBX		; +(49-digit)
	MOV		intAccumulator, EAX	; store accumulation


	JO		_overflowDetected		; checks for overflow flag


	XOR		EAX, EAX		; reset eax

	LOOP	_toIntLoop

_overflowDetected:

	CMP		negBool,1
	JNE		_invalidItem
	CMP		intAccumulator, MIN
	JNE		_invalidItem


_endCalculations:

	CMP			negBool, 1
	JNE			_writeToConsole
	NEG			intAccumulator		; negBool was raised, negate the number
	MOV			negBool, 0			; reset negBool

_writeToConsole:

	MOV		EAX, intAccumulator
	JMP		_return

	; invalid entries 

_invalidItem:

	mDisplayString	[EBP+16]	; display errorMsg string
	CALL	CrLf
	MOV		negBool, 0			; reset negBool
	JMP		_rePrompt			; prompt user again for valid input

_return:					



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

	POP		EBP
	RET		12

Math ENDP




; ---------------------------------------------------------------------------------
; Name: WriteVal
; 
; Converts and displays an SDWORD integer to a string and displays it in the console.
;	Invokes mDisplayString macro.
;
; Preconditions: value to be converted is on the system stack at [EBP+8]
;				 mDisplayString macro exists
;
; Postconditions: numerical string written to console
;
; Receives: 
;			[EBP+8]  = value of validated SDWORD to be converted and written as a string
;			
; returns: none
; ---------------------------------------------------------------------------------

WriteVal PROC

	LOCAL	testNum:SDWORD, negFlag:DWORD, minFlag:DWORD, outputString[16]:BYTE, reversedString[16]:BYTE
	

	PUSHAD

	MOV		EAX, [EBP+8]		; value to be converted
	MOV		testNum, EAX

	LEA		EDI, outputString
	MOV		AL,0				; place null terminator at beginning	
	STOSB
	CLD

	; determines if the number is positive or 0

	CMP		testNum, -1
	JG		_positiveOrZeroNum

	; tests to see if this number is the minimum SDWORD value special case

	CMP		testNum, MIN
	JNE		_notMinimumNum
	MOV		minFlag, 1			; raise the min flag
	
	; all other negative numbers. negate the number to positive and raise the negFlag.

_notMinimumNum:

	NEG		testNum				
	MOV		negFlag, 1			
	JMP		_loopSetup
	
	; positive or 0 numbers

_positiveOrZeroNum:
	MOV		negFlag, 0


	; sets up loop for string conversion.  Decrement the now positive number by 1 if min flag raised.

_loopSetup:
	
	MOV		EAX, testNum
	CMP		minFlag,1
	JNE		_notSpecialCase
	DEC		EAX					; decrement the max num

_notSpecialCase:
	MOV		EBX, 10				; divisor
	MOV		ECX, LENGTHOF outputString	

	; loops through the integer dividing by 10 until 0. Adds 48 to each remainder which determines the
	; current digit's ASCII value.  If the special case minFlag is raised increments the final digit from 7 to 8.
	; stores the string (in reverse) in outputString

_stringLoop:



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
	

	CMP		negFlag, 1
	JNE		_displayString
	MOV		AL, MINUS
	STOSB
	DEC		ECX  ;accomodates for - sign


_displayString:

	; need to reverse string for display here
	LEA		EDI, reversedString
	LEA		ESI, outputString
;	MOV		EDI, OFFSET reversedString
;	MOV		ESI, OFFSET outputString
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

	LEA		EAX, reversedString
	mDisplayString	EAX;OFFSET reversedString

	POPAD

	RET		4

WriteVal ENDP


END main
