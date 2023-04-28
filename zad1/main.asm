;--[DATA SEGMENT]---------------------------- ;

DATA_SEG SEGMENT
; =[EXAMPLE]================================ ;
t1	DB "To jest tekst!", 10, 13, "$"
t2	DB "To jest drugi tekst!", 10, 13, "$"
t3	DB "A to jest test $"

; =[BUFFERS]================================ ;
buff	DB 30, ?, 30 DUP('$')
nfirst	DB 30, 0, 30 DUP('$')
nsecond	DB 30, 0, 30 DUP('$')
oper	DB 30, 0, 30 DUP('$')

; =[UTILS]================================== ;
nline	DB 10, 13, '$'

; =[TRANSLATION]============================= ;
; vname		db value, length, name

vzero		DB 0d, 4d, "zero$"
vone		DB 1d, 5d, "jeden$"
vtwo		DB 2d, 3d, "dwa$"
vthree		DB 3d, 4d, "trzy$"
vfour		DB 4d, 6d, "cztery$"
vfive		DB 5d, 4d, "piec$"
vsix		DB 6d, 5d, "szesc$"
vseven		DB 7d, 6d, "siedem$"
veight		DB 8d, 5d, "osiem$"
vnine		DB 9d, 8d, "dziewiec$"
vten		DB 10d, 8d, "dziesiec$"
veleven		DB 11d, 10d, "jedenascie$"
vtwelve		DB 12d, 9d, "dwanascie$"
vthirteen	DB 13d, 10d, "trzynascie$"
vfourteen	DB 14d, 11d, "czternascie$"
vfiveteen	DB 15d, 10d, "pietnascie$"
vsixteen	DB 16d, 10d, "szesnascie$"
vseventeen	DB 17d, 12d, "siedemnascie$"
veighteen	DB 18d, 11d, "osiemnascie$"
vnineteen	DB 19d, 14d, "dziewietnascie$"
vtwenty		DB 20d, 10d, "dwadziescia$"
vthirty		DB 30d, 11d, "trzydziesci$"
vfourty		DB 40d, 12d, "czterdziesci$"
vfivety		DB 50d, 11d, "piecdziesiat$"
vsixty		DB 60d, 13d, "szescdziesiat$"
vseventy	DB 70d, 14d, "siedemdziesiat$"
veighty		DB 80d, 13d, "osiemdziesiat$"
vninety		DB 90d, 16d, "dziewiecdziesiat$"
vhundred	DB 100d, 4d, "sto$"

oplus		DB "+", 4d, "plus$"
ominus		DB "-", 5d, "minus$"
otimes		DB "*", 4d, "razy$"

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
main_read_buffer:

	; READ INPUT ;

	CALL	read
	CALL	trim_buffer
	MOV	DX, OFFSET t3

	; GET BUFFER LENGTH ;

	XOR	AX, AX	; clear ax
	XOR	CX, CX	; clear cx

	MOV 	SI, OFFSET buff			; get start pointer
	MOV	AL, byte ptr ds:[SI + 1]	; copy length value to ax
	
	CMP	AL, 0
	JE	main_read_buffer

main_parse_buffer:

	; PARSE INPUT BUFFER ;

	MOV	CX, AX	; set string length
	MOV	SI, OFFSET buff + 2	; set pointer to first character
	call 	parse_input
	

	; GET LENGTH ;
	
	MOV	SI, OFFSET nfirst
	CALL	get_length

	MOV	SI, OFFSET oper
	CALL	get_length

	MOV	SI, OFFSET nsecond
	CALL	get_length

	; GET VALUE ;
	
	MOV	SI, OFFSET nfirst
	CALL	get_value

	; MOV	SI, OFFSET oper
	; CALL	get_value_oper

	MOV	SI, OFFSET nsecond
	CALL	get_value

	; =[PRINT INPUT]============= ;

	CALL	print_nl

	MOV	dx, offset oper + 2
	CALL	print

	CALL	print_nl

	MOV	dx, offset nfirst + 2
	CALL	print

	CALL	print_nl

	MOV	dx, offset nsecond + 2
	CALL	print

	CALL	print_nl

	; COMPARE STRINGS ;

	MOV	SI, OFFSET nfirst  ; set si pointer to first character
	MOV	DI, OFFSET vzero   ; set di pointer to first character
	CALL	cmp_str

	JE	end_program_2

	MOV	DX, OFFSET vhundred + 2 ; print example data
	call	print

	
end_program:


	XOR	AX, AX

	MOV	AL, BYTE PTR DS:[nfirst + 1]
	MOV	AH, BYTE PTR DS:[vzero + 1]

	CMP	AL, AH
	JE	end_program_2

	MOV	DX, OFFSET t3
	call	print

end_program_2:

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
	MOV	AX, SEG DATA_SEG	; Load data segment
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
	MOV	BL, BYTE PTR DS:[BP]
	ADD	BL, 1
	XOR	BH, BH
	ADD	BP, BX
	MOV	BYTE PTR DS:[BP], '$'

	RET
trim_buffer ENDP


; [USAGE]:
; 	MOV  SI, OFFSET source_offset
; 	CALL get_length
; 	<...> do with buff whatever you want <...>
; [NOTE]:
; first 2 bytes of source_offset contains data like: value and length
; main string starts from source_offset + 2
; 
get_length PROC
	PUSH	SI
	PUSH	DI
	PUSH	AX
	PUSH	BX
	PUSH	CX
	
	MOV	DI, SI	; save si begin to di
	ADD	SI, 2	; point si to actual string
	
	XOR	AX, AX	; CLEAR AX
	XOR	BX, BX	; CLEAR BX

	MOV	CX, 30	; SET BUFFOR MAX LENGTH
	
	get_length_loop:

		MOV	AL, BYTE PTR DS:[SI]
		MOV	AH, "$"

		CMP	AL, AH
		JE	get_length_end

		INC	BL
		INC	SI

		LOOP	get_length_loop

	get_length_end:
		INC	DI
		MOV	AL, BL
		MOV	BYTE PTR DS:[DI], AL

		POP	CX
		POP	BX
		POP	AX
		POP	DI
		POP	SI
		RET

get_length ENDP

; [USAGE]:
; 	MOV  SI, OFFSET source_offset
; 	CALL get_value
; [NOTE]:
; 	this procedure parse string value to 
get_value PROC
	PUSH 	SI
	PUSH 	DI
	PUSH	AX
	
	XOR	AX, AX	; clear AX

	MOV	DI, OFFSET vzero
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET vone
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET vtwo
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET vthree
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET vfour
	CALL	check_number
	JE	get_value_end
	
	MOV	DI, OFFSET vfive
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET vsix
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET vseven
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET veight
	CALL	check_number
	JE	get_value_end

	MOV	DI, OFFSET vnine
	CALL	check_number
	JE	get_value_end

	get_value_invalid:
		POP	AX
		POP	DI
		POP	SI

		; MOV	DX, OFFSET error_parse
		; call throw_exception
		
		RET

	get_value_end:

		MOV	BYTE PTR DS:[SI], AL

		POP	AX
		POP	DI
		POP	SI
		RET
get_value ENDP

check_number PROC
	MOV	AL, BYTE PTR DS:[DI]
	CALL	cmp_str
	RET
check_number ENDP

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
; [NOTE]:
; 	this procedure return result as ZF flag
cmp_str PROC
	PUSH	CX
	PUSH	AX

	XOR	CX, CX	; clear cx
	XOR	AX, AX	; clear ax
	
	cmp_str_len:
		MOV	AL, BYTE PTR DS:[SI + 1]
		MOV	AH, BYTE PTR DS:[DI + 1]
		CMP	AL, AH
		JNE	cmp_str_end

	cmp_str_equal:
		XOR	CX, CX ; clear CX
		XOR	AX, AX ; clear AX

		MOV	AL, BYTE PTR DS:[SI + 1] ; get length
		MOV	CX, AX			 ; set length
		
		MOV	AX, SEG DATA_SEG	; Load data segment
		MOV	DS, AX			; move loaded data to ds
		
		MOV	AX, SEG DATA_SEG	; Load data segment
		MOV	ES, AX			; move loaded data to es

		ADD	SI, 2			; skip value bytes
		ADD	DI, 2			; skip value bytes

		CLD				; clear flag to compare forward 
		REPE	CMPSB			; repeat while equal compare string byte-by-byte
		
	cmp_str_end:

		POP	AX
		POP	CX
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

	MOV	AX, SEG DATA_SEG	; Load data segment
	
	; SET INITIAL STATE ;
	XOR	BL, BL
	MOV	BL, 0h

	remove_spaces:
		; PUSH	CX

		; POP	CX

		MOV	AL, byte ptr ds:[SI]
		CMP	AL, ' '		; check if space
		JE	remove_spaces_end
		CMP	AL, 09h		; check if tabulation
		JE	remove_spaces_end

		JMP	parse_hub	; If not whitespace

		remove_spaces_end:
			INC	SI
			LOOP	remove_spaces
			JMP 	parse_finish

	parse_hub:
		INC	BL

		CMP	BL, 1H
		JE	parse_first

		CMP	BL, 2H
		JE	parse_operator

		CMP	BL, 3H
		JE	parse_second

		JMP 	parse_finish

	
	parse_first:
		MOV	DI, OFFSET nfirst + 2
		nop
		JMP	parse_word
		nop
	parse_operator:
		MOV	DI, OFFSET oper + 2
		JMP	parse_word
	
	parse_second:
		MOV	DI, OFFSET nsecond + 2
		JMP	parse_word

	parse_word:
		PUSH	CX

		MOV	AL, BYTE PTR DS:[SI]
		MOV	BYTE PTR DS:[DI], AL

		; ; if (si != ' ') then goto parse_first

		INC	DI
		INC	SI
		POP	CX
		
		MOV	AL, BYTE PTR DS:[SI]
		
		CMP	AL, ' '		; check if space
		JE	remove_spaces
	
		CMP	AL, 09h		; check if tabulation
		JE	remove_spaces

		CMP	AL, 0dh		; check if carriage return
		JE	parse_hub

		LOOP	parse_word

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