TITLE Program 5A			(Program5A.asm)

; Program Description: this program gets 10 valid integers from the user and 
;			stores the numeric values in an produce the output
;	Note: This program performs data validation.  The user must input a
;			number that can fit in a 32 bit register. 
; Author: Alex Marsh
; class: CS271
; email: marshal@onid.oregonstate.edu 
; Date Created: August 9, 2015
; Last Modification Date: August 10, 2015

INCLUDE Irvine32.inc

; (insert symbol definitions here)
;----------------------------------------
displayString MACRO buffer
;displays a string from inputed buffer
;recieves: the name of the string to display
	push edx					;save edx register
	mov edx, buffer
	call WriteString
	pop edx						;Restore edx
ENDM		
;---------------------------------------------
;--------------------------------------------
getString MACRO varName:REQ
;reads from standard input into a buffer
;receives:the name of the buffer.
;Note: taken from 415
	push ecx
	push edx
	mov edx, varName
	mov ecx, SIZEOF varName 
	call ReadString
	pop edx
	pop ecx
ENDM


.data
programTitle    BYTE	"Program 5A",0
myName     BYTE    "Programmed by Alex Marsh",0
intro1  BYTE "Please provide 10 unsigned decimal integers.",0
intro2  BYTE  "Each number needs to be small enough to fit inside a 32 bit register.",0
intro3 BYTE   "After you have finished inputting the raw numers I will display a list",0
intro4 BYTE   "of the integers, their sum, and their average value.",0

prompt BYTE "Please enter an unsigned number: ",0
invalidMsg BYTE "ERROR: You did not enter an unsigned number or your number was too big.",0
displayMsg BYTE "You entered the following numbers: ",0
sumMsg BYTE "The sum of these numbers is: ",0
averageMsg BYTE "The average is: ",0
here1 BYTE "converted now here",0
convertedMsg BYTE "Your converted number is: ",0
resultsCert   BYTE	"Results certified by Alex Marsh. ",0
goodBye	  BYTE	"Thank you for playing!  Until next time, goodbye!",0

intArray BYTE 100 DUP (?)   ;array to keep converted integers
sumString BYTE 32 DUP (?)	  ;string to hold converted sum
averageString BYTE 32 DUP (?)  ;string to hold converted average
stringIn BYTE 32 DUP (?)  ; string to keep inputed strings
stringOut BYTE 32 DUP (?)  ;string to keep validated strings
 

sum DWORD ?				;sum of integers in array
average DWORD ?			;average of integers in array
howMany DWORD ?			;holds the inputed strings length	
COUNT DWORD ?				;number of integers allowed
guess BYTE 10
switch BYTE ?

; (insert variables here)

.code
main PROC

; (insert executable instructions here)

;introduce program
	push OFFSET programTitle
	push OFFSET myName
	push OFFSET intro1
	push OFFSET intro2
	push OFFSET intro3
	push OFFSET intro4
	call introduction

;get values from user to fill array after converting them
	push OFFSET convertedMsg   ;says number was converted & proof
	push SIZEOF stringIn
	push OFFSET intArray	;address of array of DWORD
	push OFFSET stringIn	;address of string for user input
	push OFFSET prompt
	push OFFSET invalidMsg	
	push COUNT
	call readVal			;invokes getString and converst it to dec

;calculate sum	
	push OFFSET sum		;address of sum
	push OFFSET intArray
	push LENGTHOF intArray
	call getSum			;gets sum of dec in array

;calculate average
	push sum
	push OFFSET average
	push LENGTHOF intArray
	call getAverage		;gets average of dec in array

;display array, sum, and average
	push COUNT
	push OFFSET displayMsg	
	push OFFSET intArray
	push OFFSET sumMsg
	push OFFSET averageMsg
	push sum
	push average
	call writeVal			;invokes displayString and convert numeric to string for display
	 

;say goodbye to user	
	push OFFSET resultsCert
	push OFFSET goodBye
	call farewell

	exit		; exit to operating system
main ENDP

; (insert additional procedures here)

;*************************************************
;procedure to introduce the program
;recieves: paramters on stack
;returns: none
;preconditions: none
;registers changed: edx
;*******************************************************
introduction PROC
		push ebp
		mov ebp, esp

	;Display title "Program 5A"
		displayString [ebp+28]
		call Crlf
		call Crlf

	;Display "Programmed by Alex Marsh"
		displayString [ebp+24]
		call Crlf
		call Crlf

	;Display intro1
		displayString [ebp+20]
		call Crlf

	;Display intro2
		displayString [ebp+16]
		call Crlf	
		
	;Display intro3
		displayString [ebp+12]
		call Crlf		

	;Display intro4
		displayString [ebp+8]
		call Crlf
		call Crlf

		pop ebp
		ret 24
introduction ENDP

;*************************************************
;procedure to read in values, store in array as converted dec
;recieves: paramaters on stack
;returns: none
;preconditions: none
;registers changed: edx, al, bl, dl, esi, ebp, esp
;*******************************************************
readVal PROC
;set up system stack	
	push ebp
	mov ebp, esp
		
	mov ecx, 10				; for 10 inputs
	mov edi, [ebp+24]		;array of Ints
newString:
	mov [ebp+8], ecx		;move loop into COUNT
	mov bl, 0				;x=0
tryAgain:
	displayString[ebp+16]	;display prompt
	;getString [ebp+20]
	mov edx, [ebp+20]		;points to array
	mov ecx, [ebp+28]		;sizeOf buffer
	call ReadString
	mov ecx, eax
	mov ebx, 0				;x=0
	mov esi, [ebp+20]		;esi is stringIn
	cld						;set flag to move forward in string
getByte:
	cld
	lodsb					;load byte from esi to al
	movzx eax, al
	cmp eax, 48
	jb invalid
	cmp eax, 57
	ja invalid
	
	sub eax, 48				;bl -48
	
	xchg eax, ebx			
	
	mul guess				;al * 10 
	
	xchg eax, ebx

	add ebx, eax
	
	loop getByte
	
	mov eax, ebx
	mov [edi], eax
	add edi, 4
	call Crlf
	displayString [ebp+32]  ;"Your converted number is:"
	call writedec
	call Crlf
	cmp ecx, 0
	je nextStep
			
nextStep:
	mov ecx, [ebp+8]		;count for outer loop
	loop newString
	jmp endNow
invalid:
	displayString[ebp+12]	;display invalid msg
	call Crlf
	jmp tryAgain

endNow:
	pop ebp
	ret 28
readVal ENDP

;****************************************************
;procedure to calculate sum of array
;recieves: parameters on the stack
;returns: none
;preconditions: none
;registers changed: edx, ebp, esp, esi
;note: this procedure was taken from the book p.319
;******************************************************
getSum PROC
;set up system stack	
	push ebp
	mov ebp, esp

	mov esi, [ebp+12]		;address of the array
	mov ecx, 10		;size of the array
	mov eax, 0				;set sum to zero 
	cmp ecx, 0				;length = zero?	
	je L2
L1:
	add eax, [esi]			;add each integer to sum
	add esi, 4				;point to next integer
	loop L1					;sum is in eax

	mov ebx, [ebp+16]		;address of sum
	mov [ebx], eax			;move sum to address of variable 
L2:
	pop ebp
	ret 12
getSum ENDP

;****************************************************
;procedure to calculate average of array
;recieves: parameters on the stack
;returns: none
;preconditions: none
;registers changed: edx, ebp, esp, esi
;note: this procedure was taken from the book p.319
;******************************************************
getAverage PROC
;set up system stack	
	push ebp
	mov ebp, esp

	mov edx, 0
	mov ebx, 10		; size of array
	mov eax, [ebp+16]		; sum
	div ebx
	mov ebx, [ebp+12]		;average
	mov [ebx], eax

	pop ebp
	ret 12
getAverage ENDP

;****************************************************
;procedure to display string, sum, and average
;recieves: parameters on the stack
;returns: none
;preconditions: none
;registers changed: edx, ebp, esp
;******************************************************
writeVal PROC
;set up system stack	
	push ebp
	mov ebp, esp

	displayString[ebp+20]     ;sumMsg
	mov eax, [ebp+12]				;sum
	call WriteDec
	call Crlf

	displayString[ebp+16]		;averageMsg
	mov eax, [ebp+8]			;average
	call WriteDec
	call Crlf

	displayString[ebp+28]		;displayMsg
	call Crlf
	mov edx,10		;count
	mov esi,[ebp+24]		;array
	dec edx
more:
	mov eax, [esi]
	call WriteDec 
	mov al, ' '
	call WriteChar
	dec edx
	add esi, 4
	cmp edx, 0
	jge more
	call Crlf
	pop ebp
	ret 28
writeVal ENDP

;****************************************************
;procedure to say goodbye to the user
;recieves: parameters on the stack
;returns: none
;preconditions: none
;registers changed: edx, ebp, esp
;******************************************************
farewell PROC
;set up system stack
		push ebp
		mov ebp, esp

	;Display title "Results certified by Alex Marsh."
		displayString [ebp+12]
		call Crlf

	;Display intro1 "Thank you for playing!  Until next time, goodbye"
		displayString [ebp+8]
		call Crlf
		call Crlf
		
		pop ebp
		ret 8
farewell ENDP	

END main