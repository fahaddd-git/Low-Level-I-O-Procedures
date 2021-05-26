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
	
	mov edx, storeLocationOffset ; point to the buffer
	mov ecx, lengthValue+1 ; specify max characters
	call ReadString ; input the string
	
	POP		ECX
	POP		EDX
	
ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays
;
; Preconditions: do not use eax, ecx as arguments
; Postconditions: EAX modified
;
; Receives: stringOffset = offset of string to display
;	
;	
; returns: user keyboard input stored in storeLocation
;		   amount of bytes read in EAX
; ---------------------------------------------------------------------------------
mDisplayString MACRO stringOffset:REQ
	PUSH	EDX
	MOV		EDX, stringOffset
	CALL	WriteString
	POP		EDX
ENDM

; ...
; (insert constant definitions here)

 .data

 testString	BYTE	"ABCDE",0
 storedString BYTE	5 DUP(?)


; (insert variable definitions here)

.code
main PROC

	mGetString			OFFSET testString,  OFFSET storedString, 5
	mDisplayString		OFFSET	 storedString


	Invoke ExitProcess,0	; exit to operating system
main ENDP

; (insert additional procedures here)

END main
