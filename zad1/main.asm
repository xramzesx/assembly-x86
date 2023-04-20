;--[DATA SEGMENT]---------------------------- ;

DATA_SEG SEGMENT
; =[EXAMPLE]================================ ;
t1	DB "To jest tekst!", 10, 13, "$"
t2	DB "To jest drugi tekst!", 10, 13, "$"
t3	DB "A to jest test $"

; =[BUFFERS]================================ ;

DATA_SEG ENDS
;--[CODE SEGMENT]---------------------------- ;

CODE_SEG SEGMENT

START1:
	; LOAD STACK SEGMENT ;
	; TO SS ;
	MOV	AX, SEG STACK_SEG
	MOV 	SS, AX
	MOV	SP, OFFSET WSTOS1
	
	; DISPLAY TEXT ;
	; LOAD TO AX ;
	MOV 	AX, SEG t1
	MOV	DS, AX
	MOV	DX, OFFSET t1
	MOV	AH,9	; DISPLAY TEXT DS:DX
	INT	21h;

	; READ SINGLE BYTE ;

	MOV	DX, OFFSET t2
	CALL	print

	CALL	read
	CALL	trim_buffer
	MOV	DX, OFFSET t3

	MOV	DX, OFFSET nline
	CALL	print

	MOV	DX, OFFSET buff + 2
	CALL 	print
	
	; GET BUFFER LENGTH ;

	XOR	AX, AX	; clear ax
	XOR	CX, CX	; clear cx

	MOV 	SI, OFFSET buff	; get start pointer
	MOV	AL, [SI + 1]	; copy length value to ax
	
	MOV	CX, AX	; set string length
	
	MOV	SI, OFFSET buff + 2	; set pointer to first character
	call	parse_input

	; END PROGRAM ;

	MOV	AL,0	; set value that OS return
	MOV	AH,4CH 	; value for ending program
	INT	21h		; DOS interrupt


;=== PROCEDURES ===============================================;

; [USAGE]:
;	MOV	DX, OFFSET offset_name
;	CALL	print
;
print PROC
	MOV	AX, SEG DATA_SEG	; Load data segment
	MOV	DS, AX		; move loaded data to ds
	MOV	AH, 09h		; set DOS code (print)
	INT	21h		; DOS interrupt
	RET
print ENDP

; [NOTE]:
; 	this procedure doesn't work,
; 	threat it like an example to
; 	properly printing new line
print_nl PROC
	MOV	DX, OFFSET nline
	CALL	print
	RET
print_nl ENDP

; [USAGE]:
; 	CALL read
; 	<...> do with buff whatever you want <...>
;
read PROC
	MOV	AX, SEG DATA_SEG ; Load data segment
	MOV	DS, AX		 ; move loaded segment to ds
	MOV	DX, OFFSET buff	 ; load buffer to dx
	MOV	AH, 0ah		 ; set DOS code (read)
	INT	21H		 ; DOS interrupt
	RET
read ENDP

trim_buffer PROC
	MOV	BP, OFFSET buff + 1
	MOV	BL, BYTE PTR CS:[BP]
	ADD	BL, 1
	XOR	BH, BH
	ADD	BP, BX
	MOV	BYTE PTR CS:[BP], '$'

	RET
trim_buffer ENDP

exit PROC
	MOV	AL, 0	; set program return value
	MOV	AH, 4CH	; set DOS code (exit)
	INT	21H	; DOS interrupt
	RET
exit ENDP

; [USAGE]:
; 	MOV si, OFFSET source_string
; 	MOV di, OFFSET destination_string
; 	CALL cmp_str
; 	<...> do with buff whatever you want <...>
;
cmp_str PROC
	cmp_str_loop:
		push 	cx

		mov al, [si] ; Wczytaj znak z pierwszego stringu do rejestru AL
		mov ah, [di] ; Wczytaj znak z drugiego stringu do rejestru AH
		cmp al, ah ; Porównaj znaki


		INC	SI
		INC	DI

		pop 	cx
		loop 	cmp_str_loop

	cmp_str_true:

		RET

	cmp_str_false:

		RET
	RET
cmp_str ENDP


; [USAGE]:
; 	MOV si, OFFSET source_string
;	MOV cx, string_length
; 	CALL parse_input
; 	<...> do with buff whatever you want <...>
;
parse_input PROC

	; parse codes (at BL):
	; 0h	- finish
	; 1h	- parse first
	; 2h	- parse operator
	; 3h	- parse second

	; SET INITIAL STATE ;
	XOR	BL, BL
	MOV	BL, 1h
	
	remove_spaces:
		PUSH	CX
		
		; mov	dx, OFFSET t2
		; call	print

		MOV	AL, [SI]
		CMP	AL, ' '
		JNE	parse_first
		; if (si != ' ') then goto parse_first
		

		INC	SI
		POP	CX
		LOOP	remove_spaces
		JMP parse_finish
		; RET

	parse_hub:
		CMP	BL, 1H
		JE	parse_first

		CMP	BL, 2H
		JE	parse_first

		CMP	BL, 3H
		JE	parse_first

		JMP parse_finish

	parse_first:
		mov dx, offset t1
		call print
		JMP parse_finish
	parse_finish:

		RET

parse_input ENDP

CODE_SEG ENDS

;--[STACK SEGMENT]---------------------------- ;

STACK_SEG SEGMENT STACK
	DW	300 DUP(?)
WSTOS1	DW	?
STACK_SEG ENDS

END START1