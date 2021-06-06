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
; Preconditions: promptOffset, storeLocationOffset, and userInputLengthOffset must be mem addresses
;				 do not use EAX as argument for userInputLengthOffset
;
; Postconditions: string at promptOffset written to console
;				  user prompted for input			  
;
; Receives:
;			promptOffset = offset of string used to prompt user 
;			storeLocationOffset = offset of array in which to store user input
;			maxLength = maximum amount of characters to store
;			userInputLengthOffset = offset of where to store amount of bytes user enters
;	
; returns: user keyboard input stored in storeLocation
;		   amount of bytes read in where userInputLengthOffset points
; ---------------------------------------------------------------------------------

mGetString MACRO promptOffset:REQ, storeLocationOffset:REQ, maxLength:REQ, userInputLengthOffset:REQ
	
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX
	PUSH	EBX

	; displays string in console
	MOV		EDX, promptOffset
	CALL	WriteString
	
	; prompts user for data
	MOV		EDX, storeLocationOffset	 ; point to the buffer
	MOV		ECX, maxLength			 ; specify max characters
	CALL	ReadString
	
	; stores amount of bytes read
	MOV		[userInputLengthOffset], EAX
	
	POP		EBX
	POP		EAX
	POP		ECX
	POP		EDX
	
ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays given string in console.
;
; Preconditions: none
;
; Postconditions: string starting at stringOffset printed to console
;
; Receives: stringOffset = offset of string to display
;		
; Returns: none
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

; sdword and buffer limits
LENGTHLIMIT=150
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
	index			DWORD		0



.code
main PROC

	; display program title and programmer's name

	mDisplayString OFFSET progTitle 
	
;--------------------------------------------------------------------------------------------	
; Prompt user for input and stores in array.
;		Queries user for MAXNUMS amount of strings and converts them to SDWORDS. 
;--------------------------------------------------------------------------------------------
	
	MOV		ECX, MAXNUMS			; amount of strings to gather from user

	; loop MAXNUMS times calling ReadVal procedure

_getNums:	

	PUSH	OFFSET	index
	PUSH	OFFSET	intArray	
	PUSH	OFFSET	errorMsg
	PUSH	OFFSET	enterNum
	PUSH	OFFSET	intHolder
	CALL	ReadVal	
	LOOP	_getNums
	CALL	CrLf


;--------------------------------------------------------------------------------------------	
; Display stored array as strings.
;		Loops through SDWORD array converting to a string and displaying each element as a string.
;--------------------------------------------------------------------------------------------

	mDisplayString	OFFSET userNumInfo 

	MOV		ECX, LENGTHOF intArray
	MOV		index, 0					; reset index

	; loop through array, convert to string, display

_printArray:
	
	PUSH	OFFSET delimiter
	PUSH	OFFSET index
	PUSH	OFFSET intArray
	CALL	display
	LOOP	_printArray
	CALL	CrLf

;--------------------------------------------------------------------------------------------	
; Calculate and display sum and average.
;		Uses SDWORD array to calculate and display the sum and average of the converted
;		to integer user entered strings.
;--------------------------------------------------------------------------------------------

	
	PUSH	OFFSET	averageInfo
	PUSH	OFFSET	sumInfo
	PUSH	OFFSET	intArray
	CALL	Math

	CALL	CrLf

	
	; displays farewell message to the user
	
	mDisplayString	OFFSET farewell


	Invoke ExitProcess,0	; exit to operating system
main ENDP



; -----------------------------------------------------------------------------------------------
; Name: ReadVal
; 
; Prompts user to enter a number, validates input, converts string of digits into a SDWORD, then stores
;	a converted SDWORD in an array. Entries can be up to but not including 16 characters long.
;	Invokes mGetString macro.
;
; Preconditions: errorMsg, enterNum are global strings
;				 intHolder is a global SDWORD
;				 intArray is a global SDWORD array
;				 index is a global DWORD
;				 mGetString macro exists
;				 offset of intHolder, offset of enterNum, offset of errorMsg, offset of intArray, offset of index on system stack
;
; Postconditions: none
;
; Receives: 
;			[EBP+8]  = offset of intHolder global DWORD
;			[EBP+12] = offset of enterNum global string
;			[EBP+16] = offset of errorMsg global string
;			[EBP+20] = offset of intArray
;			[EBP+24] = offset of index
;
; returns: intArray[index] = valid user input as an SDWORD
;		   index = incremented by 4 for each valid user input
; ---------------------------------------------------------------------------------------------------

ReadVal PROC

	LOCAL		lengthCounter:DWORD, intAccumulator:SDWORD, inputLength:DWORD, negBool:BYTE, storedString[16]:BYTE

	
	PUSHAD	; preserve registers

	; prompts user for input

_rePrompt:
	
	MOV		negBool, 0			; set negative boolean flag to false
	LEA		ECX, storedString
	LEA		EBX, inputLength		
	mGetString	[EBP+12], ECX, LENGTHLIMIT, EBX


	; validates length of user inputs 0<length<16

	CMP		inputLength, 15		; num too long
	JG		_invalidItem
	CMP		inputLength,0		; user didn't enter anything
	JE		_invalidItem

	; checks if user entered only a + or - sign

	CMP		inputLength, 1
	JNE		_validLength
	LEA		ESI, storedString
	LODSB	
	CMP		AL, MINUS
	JE		_invalidItem
	CMP		AL, PLUS
	JE		_invalidItem

;--------------------------------------------------------------------------------
; Checks user string for + or -.
;	User input passed initial length checks. Validates and records whether a 
;	sign (+ or -) is present in the beginning of the string.
;--------------------------------------------------------------------------------

	; loads user string for use with string primitive and conversion loop

_validLength:

	MOV		intAccumulator, 0 
	LEA		ESI, storedString
	MOV		ECX, LENGTHOF storedString    
	XOR		EAX, EAX			; clear accumulator for conversion
	MOV		lengthCounter, 0
	CLD

	; validates if a + or - sign is present in the beginning of string

_toIntLoop:
	
	LODSB						
	INC		lengthCounter	; lengthCounter at first digit, check sign to be + or - or none
	CMP		lengthCounter, 1
	JNE		_continueCalcs	; past the first digit, so don't check for sign
	
	; compares ascii code of - with digit present at beginning of string
	
	CMP		EAX, MINUS		
	JNE		_checkPlus		
	MOV		negBool, 1		; - sign present raise the negBool flag
	LOOP	_toIntLoop	
	
	; compares ascii code of + with digit present at beginning of string
	
_checkPlus:	
	
	CMP		EAX, PLUS		
	JNE		_continueCalcs	
	LOOP	_toIntLoop		


;--------------------------------------------------------------------------------
; Main string to integer conversion loop.
;	User input passed sign checks. Validates each digit of the remaining string to
;	be an ASCII character 0-9. Determines numerical representation of each digit
;	using formula  numInt = 10 * numInt + (numChar - 48). If an overflow or carry occurs
;	the current number is checked to see if it is the special case of the minimum
;	SDWORD else the current number is invalidated.
;--------------------------------------------------------------------------------


_continueCalcs:

	CMP		EAX, 0			; end of the string (null terminator)
	JE		_endCalculations

	; validates if each character ASCII is ASCII representation of 0-9 

	CMP		EAX, ZERO
	JL		_invalidItem	
	CMP		EAX, NINE
	JG		_invalidItem	
	
	; determines numerical representation of each character

	MOV		EBX, EAX		
	SUB		EAX, 48			
	MOV		EBX, EAX		 
	MOV		EAX, intAccumulator		; the previous calculations
	MOV		EDX, 10			
	IMUL	EDX						; 10(previous calculations)
	
	; checks if carry or overflow flags have been raised in event of invalid number

	JC		_invalidItem	
	ADD		EAX, EBX		
	MOV		intAccumulator, EAX		; store accumulation
	JO		_overflowDetected		


	XOR		EAX, EAX		
	LOOP	_toIntLoop

	; handles with overflow events and the special case of the smallest SDWORD

_overflowDetected:

	CMP		negBool,1
	JNE		_invalidItem
	CMP		intAccumulator, MIN
	JNE		_invalidItem

	; replaces the negative sign if needed

_endCalculations:

	CMP			negBool, 1
	JNE			_writeToConsole
	NEG			intAccumulator		; negBool was raised, negate the number
	MOV			negBool, 0			

_writeToConsole:

	MOV		EAX, intAccumulator
	JMP		_return

	; invalid entries. display error message, reprompt user. 

_invalidItem:

	mDisplayString	[EBP+16]	; displays errorMsg string
	CALL	CrLf
	MOV		negBool, 0			; reset negBool
	JMP		_rePrompt			; prompt user again for valid input

	; stores the validated generated SDWORD in global variable intHolder

_return:					

	; stores converted valid result in array

	MOV		EDI, [EBP+20]		; OFFSET intArray
	
	MOV		EBX, [EBP+24]		; OFFSET index
	ADD		EDI, [EBX]			; increment pointer
	MOV		[EDI], EAX
	MOV		EAX, 4
	ADD		[EBX], EAX

	; restores registers and control
	
	POPAD
	RET 20

ReadVal ENDP

; -----------------------------------------------------------------------------------------------
; Name: display
; 
; Displays an array of SDWORDs as strings delimited by a " ". 
;	Invokes mDisplayString macro and calls WriteVal proc.
;
; Preconditions:  delimiter is a global string
;				  index is a global DWORD variable
;				  intArray is a validated and filled SDWORD array
;				  mDisplayString macro and WriteVal procedure exist
;				  offset intArray, offset index, and offset delimiter on system stack
;
; Postconditions: intArray printed to console
;
; Receives: 
;			 [EBP+16]= starting address of delimiter string
;			 [EBP+12] = offset of index DWORD
;			 [EBP+8] = starting address of intArray SDWORD array
;
; returns: none
; ---------------------------------------------------------------------------------------------------


display PROC

	; initialize stack frame, preserve registers
	
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD
	
	; load array and increment pointer to location to be converted

	MOV		EAX, [EBP+8]	; intArray address
	MOV		EBX, [EBP+12]	
	ADD		EAX, [EBX]		; increment pointer

	; send value to WriteVal for string conversion

	PUSH	[EAX]			
	CALL	WriteVal

	mDisplayString [EBP+16]	; print delimiter

	MOV		EAX, 4
	ADD		[EBX], EAX			; increment index

	; restore registers and control

	POPAD
	POP		EBP
	RET		12

display ENDP

;---------------------------------------------------------------------------------
; Name: Math
; 
; Calculates and displays the sum and average (floor rounding) of an array.
;	Invokes mDisplayString. Calls WriteVal.
;
; Preconditions: intArray is of type SDWORD
;				 offset of sumInfo, offset of averageInfo, and intArray on system stack
;				 mDisplayString macro and WriteVal procedures exist.
;				 MAXNUMS constant exists.
;				 
;
; Postconditions: sumInfo string written to console
;				  sum of intArray written to console as string
;				  averageInfo string written to console
;				  average of intArray written to console as string
;
; Receives: 				
;			[EBP+8]  = starting address of intArray 
;			[EBP+12] = starting address of sumInfo 
;			[EBP+16] = starting address of averageInfo
;
; returns: none
; ---------------------------------------------------------------------------------

Math PROC

	PUSH	EBP
	MOV		EBP, ESP
	
	PUSHAD					; preserve registers

	; sets up summation loop and prepares for accumulation

	MOV		ECX, MAXNUMS	
	MOV		ESI, [EBP+8]	; intArray offset
	XOR		EAX, EAX		; clear for accumulation

	; iterates thru array adding each number in array

_sumLoop:
	
	ADD		EAX, [ESI]
	ADD		ESI, 4
	LOOP	_sumLoop
	CALL	CrLf		

	mDisplayString [EBP+12]		; displays sumInfo string

	; passes the calculated sum to WriteVal procedure to convert and display as string
	
	PUSH	EAX					; sum integer
	CALL	WriteVal
	CALL	CrLf

	; calculates average (floor rounding)

	CDQ							; sign extend
	MOV		EBX, MAXNUMS	
	IDIV	EBX					; divide by amount of user inputs
	CALL	CrLf
	
	mDisplayString [EBP+16]		;displays averageInfo string

	; passes the calculated average to WriteVal procedure to convert and display as string

	PUSH	EAX					; average integer
	CALL	WriteVal				
	CALL	CrLf

	; restores registers and returns control

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
; Preconditions: value to be converted is on top of the system stack before procedure called
;				 mDisplayString macro exists
;				 received SDWORD has been validated by ReadVal procedure
;
; Postconditions: string of digits written to console
;
; Receives: 
;			[EBP+8]  = value of validated SDWORD to be converted and written as a string
;			
; returns: none
; ---------------------------------------------------------------------------------

WriteVal PROC

	LOCAL	testNum:SDWORD, negFlag:DWORD, minFlag:DWORD, outputString[16]:BYTE, reversedString[16]:BYTE
	

	PUSHAD

	; loads the value to be converted and sets flags for conversion

	MOV		EAX, [EBP+8]		; value to be converted
	MOV		testNum, EAX

	LEA		EDI, outputString
	MOV		AL,0				; place null terminator at beginning of string
	STOSB
	CLD

;---------------------------------------------------------------------------------
; Sets local boolean flags.
;	Determines and sets various local flags based on whether the number is 0, +, -, or
;	the special case minimum SDWORD.
;---------------------------------------------------------------------------------
	
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

;----------------------------------------------------------------------------------
; String conversion loop.
;	Sets up string conversion loop. In the event the special case minimum SDWORD was 
;	detected, decrements the now positive value by 1. Converts to string by dividing
;	by 10 and adding 48 to the remainder until the original integer reaches 0. This determines
;	each character's ASCII value. Stores representation in outputString in reverse.
;---------------------------------------------------------------------------------

_loopSetup:
	
	MOV		EAX, testNum
	CMP		minFlag,1
	JNE		_notSpecialCase
	DEC		EAX					; decrement the max num

_notSpecialCase:
	MOV		EBX, 10				; divisor
	MOV		ECX, LENGTHOF outputString	

	; divides by 10, adds 48 to remainder

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
	
	; stores calculated ASCII values in outputString

_continueLoop:

	STOSB
	POP		EAX
	CMP		EAX, 0
	JE		_stringComplete
	LOOP	_stringLoop

	; stores the negative sign if the negFlag was raised

_stringComplete:
	
	CMP		negFlag, 1
	JNE		_displayString
	MOV		AL, MINUS
	STOSB
	DEC		ECX					; accomodates for - sign

;---------------------------------------------------------------------------------
; Reverses ouputString and displays reversedString.
;	Indexes into reversedString to determine where to start storing digits. Writes
;	the reverse of outputString to reversedString.
;---------------------------------------------------------------------------------

	; sets up location where to begin storing string

_displayString:

	LEA		EDI, reversedString
	LEA		ESI, outputString
	ADD		ESI, LENGTHOF reversedString	 ; points at end of outputString
	DEC		ECX								 ; accounts for the possible - sign
	SUB		ESI, ECX						 ; moves pointer backwards
	MOV		ECX, LENGTHOF reversedString

	; stores outputString in reverse into reversedString

_revLoop:
	STD
	LODSB
	CLD
	STOSB
	LOOP	_revLoop

	; displays reversedString

	LEA		EAX, reversedString
	mDisplayString	EAX		

	; restores registers and returns control

	POPAD
	RET		4

WriteVal ENDP


END main
