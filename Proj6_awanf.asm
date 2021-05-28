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
MAXNUMS=3

; ASCII codes
PLUS=43
MINUS=45
ZERO=48
NINE=57

.data
	enterNum		BYTE		"Enter a signed number: ",0
	errorMsg		BYTE		"ERROR: Number too large or invalid",0


	;inString	BYTE	"5",0
	;outString	SDWORD	0

	storedString		BYTE	16 DUP(?) 
	intHolder			SDWORD		?

	intArray			SDWORD		MAXNUMS DUP(?)				; array of entered strings

	indexer			DWORD	0

	testNum			SDWORD		2147483647		
	outputString	BYTE		10 DUP(?)
	otherString		BYTE		"Hope this doesn't print",0




.code
main PROC

	; gets and converts MAXNUMS strings to an array of integers
;	PUSH	OFFSET intArray
;	MOV		ECX, MAXNUMS		; amount of strings to gather from user
;_getNums:
;	CALL	ReadVal
;	LOOP	_getNums
;
;
;
;	; prints array for testing purposes
;
;	MOV		EDI, OFFSET intArray
;	MOV		ECX, LENGTHOF intArray
;
;_printArray:
;	MOV		EAX, [EDI]
;	CALL	WriteInt
;	MOV		AL, " "
;	CALL	WriteChar
;	ADD		EDI, 4
;	LOOP	_printArray
;
;	PUSH	OFFSET intArray
;	CALL	math

	CALL	WriteVal
	


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

	
	LOCAL		negBool:BYTE, lengthCounter:DWORD, intAccumulator:SDWORD 

	PUSH	EBP
	MOV		EBP, ESP
	
	PUSH	ECX
;	PUSH	EDI

	;prompts and fills userStrings array with input

_rePrompt:
	mGetString	OFFSET enterNum, OFFSET storedString, LENGTHOF storedString   ;need to get these from stack


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

	MOV		intHolder,	EAX				; TODO: needs fixing, uses globals

	MOV		EDI, OFFSET intArray
	ADD		EDI, indexer
	MOV		ESI, intHolder
	MOV		[EDI], ESI
	
	ADD		indexer, 4









	POP	ECX
	POP	EBP


_theEnd:	
	RET 4
ReadVal ENDP



; calculates sum and average
math PROC

	PUSH	EBP
	MOV		EBP, ESP

	MOV		ECX, MAXNUMS	; loop maxnums times
	MOV		ESI, [EBP+8]	; intArray offset
	XOR		EAX, EAX		; prepare for accumulation

_sumLoop:
	
	ADD		EAX, [ESI]
	ADD		ESI, 4
	LOOP	_sumLoop

	CALL	CrLf
	CALL	WriteInt

	; calc/display avg

	CDQ			; sign extend
	MOV		EBX, MAXNUMS
	IDIV	EBX
	CALL	CrLf
	CALL	WriteInt



	POP		EBP
	RET		8

math ENDP


WriteVal PROC

	LOCAL		temporary:DWORD

	PUSH	EBP
	MOV		EBP, ESP
; testString sdword 12345
;outputString byte 5 dup(?)

	

	MOV		EDI, OFFSET	outputString
	ADD		EDI, LENGTHOF outputString	; edi now points at end of outputstring

;	MOV		ECX, LENGTHOF testNum
	
	STD					; set flag so pointer moves backwards
	MOV		AL, 0
	STOSB
	
	MOV		ECX, LENGTHOF outputString	

	MOV		EAX, testNum
	MOV		EBX, 10		; divisor

_stringLoop:

;	XOR		EDX, EDX

	CDQ					; prep div

	IDIV	EBX
	PUSH	EAX
;	MOV		temporary, EDX
	MOV		AL, DL;BYTE ptr temporary
	ADD		AL, 48

	STOSB
	POP		EAX
	CMP		EAX, 0
	JE		_stringComplete



	LOOP	_stringLoop

_stringComplete:

	mDisplayString	offset outputString



	POP		EBP
	RET

WriteVal ENDP




END main
