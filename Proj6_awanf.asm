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
	MOV		ECX, maxLength				 ; specify max characters
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

	; display prog title and progr name

	mDisplayString OFFSET progTitle 
	
;--------------------------------------------------------------------------------------------	
; Prompt user for input and store in array.
;		Queries user for MAXNUMS amount of strings and converts them to SDWORDS. Then, stores
;		converted strings in an array.
;--------------------------------------------------------------------------------------------
	MOV		ECX, MAXNUMS			; amount of strings to gather from user
	MOV		EDI, OFFSET intArray

	; loop MAXNUMS times calling ReadVal procedure

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
	CALL	CrLf


;--------------------------------------------------------------------------------------------	
; Display stored array as strings.
;		Loops through SDWORD array converting each element to a string using the WriteVal
;		procedure and then display string using mDisplayString macro.
;--------------------------------------------------------------------------------------------

	mDisplayString	OFFSET userNumInfo

	MOV		EDI, OFFSET intArray
	MOV		ECX, LENGTHOF intArray

	; loop through array, convert to string, display

_printArray:
	MOV		EAX, [EDI]
	PUSH	EAX
	CALL	WriteVal
	mDisplayString	OFFSET delimiter
	ADD		EDI, 4
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
; Prompts user to enter a number, validates input, then converts string of digits into a SDWORD. 
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
; ---------------------------------------------------------------------------------------------------

ReadVal PROC

	LOCAL		lengthCounter:DWORD, intAccumulator:SDWORD, inputLength:DWORD, negBool:BYTE, storedString[16]:BYTE

	
	PUSHAD	; preserve registers

	; prompts user for input

_rePrompt:
	
	MOV		negBool, 0
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

	MOV		EDI, [EBP+8]	; OFFSET intHolder
	MOV		[EDI], EAX


	; restores registers and control
	
	POPAD
	RET 12

ReadVal ENDP

; ---------------------------------------------------------------------------------
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

	MOV		EAX, [EBP+8]		; value to be converted
	MOV		testNum, EAX

	LEA		EDI, outputString
	MOV		AL,0				; place null terminator at beginning of string
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

	; stores the negative sign if the negFlag was raised

_stringComplete:
	

	CMP		negFlag, 1
	JNE		_displayString
	MOV		AL, MINUS
	STOSB
	DEC		ECX					; accomodates for - sign


	; reverses the ouputString for proper display

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
