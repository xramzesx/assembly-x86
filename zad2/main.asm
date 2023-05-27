;--[DIRECTIVES]---------------------------- ;
.387
; =[CONSTANTS]=============================== ;
screen_max_x	EQU	320
screen_max_y	EQU	200

midpoint_x	EQU	screen_max_x / 2
midpoint_y	EQU	screen_max_y / 2

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

; [NOTE]: result offset stores a result from 
; 	  calculations, so it need to have
; 	  at least 2 bytes
result	DW 0

; =[UTILS]================================== ;
nline	DB 10, 13, '$'
nspace	DB  " $"

; =[TRANSLATION]============================= ;
; STRING :=	db value, length, name
; where:
; 	value - integer value
; 	length - length of name string without '$' sign
; 	name - number or operator name, normal string
; 
; Strings defined here are in convention:
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
vfifteen	DB 15d, 10d, "pietnascie$"
vsixteen	DB 16d, 10d, "szesnascie$"
vseventeen	DB 17d, 12d, "siedemnascie$"
veighteen	DB 18d, 11d, "osiemnascie$"
vnineteen	DB 19d, 14d, "dziewietnascie$"
vtwenty		DB 20d, 10d, "dwadziescia$"
vthirty		DB 30d, 11d, "trzydziesci$"
vfourty		DB 40d, 12d, "czterdziesci$"
vfifty		DB 50d, 11d, "piecdziesiat$"
vsixty		DB 60d, 13d, "szescdziesiat$"
vseventy	DB 70d, 14d, "siedemdziesiat$"
veighty		DB 80d, 13d, "osiemdziesiat$"
vninety		DB 90d, 16d, "dziewiecdziesiat$"
vhundred	DB 100d, 4d, "sto$"

oplus		DB "+", 4d, "plus$"
ominus		DB "-", 5d, "minus$"
otimes		DB "*", 4d, "razy$"

; =[MESSAGES]================================ ;

message_intro		DB "Type required parameters (width and height): $"

; =[ERRORS]================================== ;

error_parse_number	DB "Invalid argument", 10, 13, "$" 
error_parse_operator	DB "Unknown operator", 10, 13, "$"
error_invalid_no_args	DB "Invalid number of arguments", 10, 13, "$"
error_calculate		DB "Unknown operator", 10, 13, "$"

; =[ELLIPSE WIDTH]============================ ;

ellipse_width	DW	0
ellipse_height	DW	0

radius_width	DW	0	; ellipse_width  / 2
radius_height	DW	0	; ellipse_height / 2

radius_width_pow	DW	0
radius_height_pow	DW	0

ellipse_x	DW	0	; for Bresenham algorithm x
ellipse_y	DW	0	; for Bresenham algorithm y

; =[RENDER]================================== ;

point_x		DW	0
point_y		DW	0
point_color	DB	13

background_color	DB	0
DATA_SEG ENDS

;--[CODE SEGMENT]---------------------------- ;

CODE_SEG SEGMENT

START1:

	; LOAD STACK SEGMENT ;
	; TO SS ;
	MOV	AX, SEG STACK_SEG
	MOV 	SS, AX
	MOV	SP, OFFSET WSTOS1


	; LOAD PSP ;

	MOV	AX, SEG DATA_SEG	; load data segment
	MOV	ES, AX			; move it to ES

	MOV	SI, 082h		; point to first PSP sign
	MOV	DI, OFFSET buff + 2	; point to first buffer sign

	XOR	CX, CX			; clear cx
	MOV	CL, BYTE PTR DS:[080h]	; move psp size to cx

	MOV	BYTE PTR ES:[buff + 1], CL	; store psp size in buff

	CMP	CL, 0			; check if psp is empty
	JE	prompt_buffer		; display prompt

	; COPY BUFFER ;

	CLD
	REP	MOVSB

	JMP	parse_buffer

	; ============================= PROMPT BUFFER ============================;

prompt_buffer:

	MOV	DX, OFFSET message_intro
	CALL	PRINT

	main_read_buffer:

		; READ INPUT ;

		CALL	read
		CALL	trim_buffer

		; GET BUFFER LENGTH ;

		XOR	AX, AX	; clear ax
		XOR	CX, CX	; clear cx

		MOV 	SI, OFFSET buff			; get start pointer
		MOV	AL, byte ptr ds:[SI + 1]	; copy length value to ax
		
		CMP	AL, 0
		JE	main_read_buffer

	; ======================== END PROMPT BUFFER =============================;

parse_buffer:


	; SETUP DEFAULT DS ;

	MOV	AX, SEG DATA_SEG
	MOV	DS, AX

	; PARSE BUFFER ;

	CALL	trim_buffer

	XOR	AX, AX
	MOV	AL, BYTE PTR DS:[buff + 1]	; get buffer length

	MOV	CX, AX			; set string length
	MOV	SI, OFFSET buff + 2	; set pointer to first character
	call 	parse_input

	CALL	set_graphical_mode

	MOV	DX, OFFSET buff + 2
	CALL	PRINT

	; DRAW ELLIPSE ;

	CALL	draw_ellipse

	; EXAMPLE MIDPOINT RENDER ;

	XOR	AX, AX
	
	MOV	WORD PTR DS:[point_x], midpoint_x
	MOV	WORD PTR DS:[point_y], midpoint_y

	MOV	WORD PTR DS:[point_color], 12
	CALL 	draw_point



	XOR	AX, AX
	INT	16h	; wait for any button


	CALL	set_text_mode

	CALL	EXIT



main_parse_buffer:

	; PARSE INPUT BUFFER ;

	MOV	CX, AX			; set string length
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


	MOV	SI, OFFSET nsecond
	CALL	get_value

	CALL	print_nl

	; =[CALCULATIONS]============ ;

	CALL	calculate

	CALL	print_result

	; END PROGRAM ;

	MOV	AL,0	; set value that OS return
	MOV	AH,4CH 	; value for ending program
	INT	21h	; DOS interrupt


;=== PROCEDURES ===============================================;

set_graphical_mode PROC
	PUSH	AX
	XOR	AX, AX	; clear ax
	MOV	AL, 13h	; 320x200 w/ 256 colors
	INT	10h	; submit new mode
	POP	AX
	RET
set_graphical_mode ENDP

set_text_mode PROC	
	PUSH	AX
	XOR	AX, AX	; clear ax
	MOV	AL, 3h	; text mode
	INT	10h	; submit new mode
	POP	AX
	RET
set_text_mode ENDP

; [USAGE]:
;	MOV	DX, OFFSET offset_name
;	CALL	print
;
print PROC
	PUSH	AX
	MOV	AX, SEG DATA_SEG	; Load data segment
	MOV	DS, AX		; move loaded data to ds
	MOV	AH, 09h		; set DOS code (print)
	INT	21h		; DOS interrupt
	POP	AX
	RET
print ENDP

; [USAGE]:
; 	CALL	print_nl
print_nl PROC
	PUSH	AX
	PUSH	DX
	
	MOV	AX, SEG DATA_SEG	; Load data segment
	MOV	DX, OFFSET nline
	CALL	print

	POP	DX
	POP	AX
	RET
print_nl ENDP

; [USAGE]:
; 	CALL	print_space
print_space PROC
	PUSH	AX
	PUSH	DX
	
	MOV	AX, SEG DATA_SEG	; Load data segment
	MOV	DX, OFFSET nspace	; Load space offset
	CALL	print

	POP	DX
	POP	AX
	RET
print_space ENDP

; [USAGE]:
; 	CALL read
; 	<...> do with buff whatever you want <...>
; [DESC]:
;	Read input from user via DOS interrupt
read PROC
	PUSH	AX
	PUSH	DS
	PUSH	DX
	
	MOV	AX, SEG DATA_SEG ; Load data segment
	MOV	DS, AX		 ; move loaded segment to ds
	MOV	DX, OFFSET buff	 ; load buffer to dx
	MOV	AH, 0ah		 ; set DOS code (read)
	INT	21H		 ; DOS interrupt
	
	POP	DX
	POP	DS
	POP	AX
	
	RET
read ENDP

; [USAGE]:
; 	CALL trim_buffer
; 	<...> do with buff whatever you want <...>
;
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
; 	CALL print_result
; [NOTE]:
; 	this function print result offset as 
; 	string translated to polish
print_result PROC
	PUSH	AX
	MOV	AX, WORD PTR DS:[result]
	CALL	print_number
	POP	AX
	RET
print_result ENDP

print_number PROC
	PUSH	AX

	; NEGATIVE NUMBER ;
	
	print_negative:
		CMP	AX, 0
		JGE	print_0_19
		
		MOV	CX, -1d
		IMUL	CX

		MOV	DX, OFFSET ominus + 2
		CALL	print_single_number
		
	; NUMBER FROM 0 TO 19 ;

	print_0_19:
		CMP	AL, 0
		JNE	print_1
		MOV	DX, OFFSET vzero + 2
		CALL	print_single_number
		JMP	print_number_end

		print_1:
		
		CMP	AL, 1
		JNE	print_2
		MOV	DX, OFFSET vone + 2
		CALL	print_single_number
		JMP	print_number_end

		print_2:
		
		CMP	AL, 2
		JNE	print_3
		MOV	DX, OFFSET vtwo + 2
		CALL	print_single_number
		JMP	print_number_end

		print_3:
		
		CMP	AL, 3
		JNE	print_4
		MOV	DX, OFFSET vthree + 2
		CALL	print_single_number
		JMP	print_number_end

		print_4:
		
		CMP	AL, 4
		JNE	print_5
		MOV	DX, OFFSET vfour + 2
		CALL	print_single_number
		JMP	print_number_end

		print_5:
		
		CMP	AL, 5
		JNE	print_6
		MOV	DX, OFFSET vfive + 2
		CALL	print_single_number
		JMP	print_number_end

		print_6:
		
		CMP	AL, 6
		JNE	print_7
		MOV	DX, OFFSET vsix + 2
		CALL	print_single_number
		JMP	print_number_end

		print_7:
		
		CMP	AL, 7
		JNE	print_8
		MOV	DX, OFFSET vseven + 2
		CALL	print_single_number
		JMP	print_number_end

		print_8:
		
		CMP	AL, 8
		JNE	print_9
		MOV	DX, OFFSET veight + 2
		CALL	print_single_number
		JMP	print_number_end

		print_9:
		
		CMP	AL, 9
		JNE	print_10
		MOV	DX, OFFSET vnine + 2
		CALL	print_single_number
		JMP	print_number_end

		print_10:
		
		CMP	AL, 10d
		JNE	print_11
		MOV	DX, OFFSET vten + 2
		CALL	print_single_number
		JMP	print_number_end

		print_11:
		
		CMP	AL, 11d
		JNE	print_12
		MOV	DX, OFFSET veleven + 2
		CALL	print_single_number
		JMP	print_number_end

		print_12:
		
		CMP	AL, 12d
		JNE	print_13
		MOV	DX, OFFSET vtwelve + 2
		CALL	print_single_number
		JMP	print_number_end

		print_13:
		
		CMP	AL, 13d
		JNE	print_14
		MOV	DX, OFFSET vthirteen + 2
		CALL	print_single_number
		JMP	print_number_end

		print_14:
		
		CMP	AL, 14
		JNE	print_15
		MOV	DX, OFFSET vfourteen + 2
		CALL	print_single_number
		JMP	print_number_end

		print_15:

		CMP	AL, 15
		JNE	print_16
		MOV	DX, OFFSET vfifteen + 2
		CALL	print_single_number
		JMP	print_number_end

		print_16:
		
		CMP	AL, 16
		JNE	print_17
		MOV	DX, OFFSET vsixteen + 2
		CALL	print_single_number
		JMP	print_number_end

		print_17:
		
		CMP	AL, 17
		JNE	print_18
		MOV	DX, OFFSET vseventeen + 2
		CALL	print_single_number
		JMP	print_number_end

		print_18:
		
		CMP	AL, 18
		JNE	print_19
		MOV	DX, OFFSET veighteen + 2
		CALL	print_single_number
		JMP	print_number_end

		print_19:
		
		CMP	AL, 19
		JNE	print_20_99
		MOV	DX, OFFSET vnineteen + 2
		CALL	print_single_number
		JMP	print_number_end


	; NUMBER FROM 20 TO 99 ;

	print_20_99:
		; MOV	BX, AX
		; [NOTE]:
		; 	DIV instruction in this case 
		; 	operate on AX register
		; 	AL := store result of integer division
		; 	AH := store rest of integer division (modulo)

		PUSH	BX
		
		MOV	BL, 10
		DIV	BL

		CMP	AL, 0d
		JE	print_number_end

		XOR	BX, BX
		MOV	BL, AL
		MOV	AL, AH
		MOV	AH, BL

		POP	BX

		CMP	AH, 2
		JNE	print_30
		MOV	DX, OFFSET vtwenty + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end

		print_30:
		
		CMP	AH, 3
		JNE	print_40
		MOV	DX, OFFSET vthirty + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end

		print_40:
		
		CMP	AH, 4
		JNE	print_50
		MOV	DX, OFFSET vfourty + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end

		print_50:
		
		CMP	AH, 5
		JNE	print_60
		MOV	DX, OFFSET vfifty + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end

		print_60:
		
		CMP	AH, 6
		JNE	print_70
		MOV	DX, OFFSET vsixty + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end

		print_70:
		
		CMP	AH, 7
		JNE	print_80
		MOV	DX, OFFSET vseventy + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end

		print_80:
		
		CMP	AH, 8
		JNE	print_90
		MOV	DX, OFFSET veighty + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end

		print_90:
		
		CMP	AH, 9
		JNE	print_30
		MOV	DX, OFFSET vnineteen + 2
		CALL	print_single_number
		CMP	AL, 0
		JNE	print_1
		JE	print_number_end


	; FINISH PRINTING ;
	print_number_end:

		POP	AX
		RET	
print_number ENDP

; [USAGE]
; 	MOV	DX, OFFSET vnumber + 2
; 	CALL	print_single_number
; [DESC]:
; 	this function print single word digit to 
; 	standard output
print_single_number PROC
	PUSH	AX

	MOV	AX, SEG DATA_SEG
	CALL	print
	CALL	print_space

	POP	AX
	RET
print_single_number ENDP

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
		MOV	BYTE PTR DS:[DI], AL	; set string length

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
; 	this procedure parse int value from given string;
; [Attention!]
; 	this procedure require STRING structure defined 
; 	at the begginnig of this file 
get_value PROC
	PUSH 	SI
	PUSH 	DI
	PUSH	AX
	
	XOR	AX, AX	; clear AX

	; CHECK NUMBERS ;

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

		MOV	DX, OFFSET error_parse_number
		CALL 	throw_exception
		
		RET

	get_value_end:

		MOV	BYTE PTR DS:[SI], AL	; set string value

		POP	AX
		POP	DI
		POP	SI
		RET
get_value ENDP

; [USAGE]:
; 	MOV  SI, OFFSET source_offset
; 	CALL get_value
; [NOTE]
; 	this procedure is mainly used in get_value proc.
check_number PROC
	MOV	AL, BYTE PTR DS:[DI]
	CALL	cmp_str
	RET
check_number ENDP


; [USAGE]:
; 	MOV si, OFFSET source_string
; 	MOV di, OFFSET destination_string
; 	CALL cmp_str
; 	<...> do with buff whatever you want <...>
; [NOTE]:
; 	this procedure return result as ZF flag
cmp_str PROC
	PUSH	SI
	PUSH	DI
	PUSH	CX
	PUSH	AX

	XOR	CX, CX	; clear cx
	XOR	AX, AX	; clear ax
	
	cmp_str_len:
		MOV	AL, BYTE PTR DS:[SI + 1]	; get first string length
		MOV	AH, BYTE PTR DS:[DI + 1]	; get second string length
		CMP	AL, AH				; compare string lengths
		JNE	cmp_str_end

	cmp_str_equal:
		XOR	CX, CX ; clear CX
		XOR	AX, AX ; clear AX

		MOV	AL, BYTE PTR DS:[SI + 1] ; get length
		MOV	CX, AX			 ; set length
		
		MOV	AX, SEG DATA_SEG	; Load data segment
		MOV	DS, AX			; move loaded data to ds
		MOV	ES, AX			; move loaded data to es

		ADD	SI, 2			; skip value bytes
		ADD	DI, 2			; skip value bytes

		CLD				; clear flag to compare forward 
		REPE	CMPSB			; repeat while equal compare string byte-by-byte
		
	cmp_str_end:

		POP	AX
		POP	CX
		POP	DI
		POP	SI
		RET	
cmp_str ENDP

; [USAGE]:
; 	MOV	WORD PTR DS:[point_x], x_value
; 	MOV	WORD PTR DS:[point_y], y_value
; 	MOV	WORD PTR DS:[point_color], color_value
; 	CALL 	draw_point
draw_point PROC
	PUSH	AX
	PUSH	BX
	PUSH	ES

	MOV	AX, 0A000h
	MOV	ES, AX

	MOV	AX, WORD PTR DS:[point_y]	; setup Y
	MOV	BX, screen_max_x
	MUL	BX				; ax = screen_max_x * y

	MOV	BX, WORD PTR DS:[point_x]	; setup X
	ADD	BX, AX				; bx = screen_max_x * y + x

	MOV	AL, BYTE PTR DS:[point_color]
	MOV	BYTE PTR ES:[BX], AL	; draw a point

	POP	ES
	POP	BX
	POP	AX
	RET
draw_point ENDP


; [USAGE]:
; 	MOV	WORD PTR DS:[ellipse_x], x_value
; 	MOV	WORD PTR DS:[ellipse_y], y_value
; 	MOV	WORD PTR DS:[point_color], color_value
; 	CALL 	draw_point
draw_symetric_points PROC
	PUSH AX
	PUSH BX
	PUSH CX
	
	MOV	AX, WORD PTR DS:[ellipse_x]
	MOV	BX, WORD PTR DS:[ellipse_y]

	;========= QUARTER I ===(x,y)====================;

	MOV	CX, AX		; setup x = x
	ADD	CX, midpoint_x

	MOV	WORD PTR DS:[point_x], CX

	MOV	CX, BX		; setup y = y
	ADD	CX, midpoint_y

	MOV	WORD PTR DS:[point_y], CX

	CALL	draw_point

	;========= QUARTER II ==(-x,y)===================;

	XOR	CX, CX
	MOV	CX, midpoint_x
	SUB	CX, AX

	MOV	WORD PTR DS:[point_x], CX

	MOV	CX, BX		; setup y = y
	ADD	CX, midpoint_y

	MOV	WORD PTR DS:[point_y], CX

	CALL	draw_point

	;========= QUARTER III ==(x,-y)==================;

	MOV	CX, AX		; setup x = x
	ADD	CX, midpoint_x

	MOV	WORD PTR DS:[point_x], CX

	XOR	CX, CX
	MOV	CX, midpoint_y
	SUB	CX, BX

	MOV	WORD PTR DS:[point_y], CX

	CALL	draw_point

	;========= QUARTER IV ==(-x,-y)===================;

	XOR	CX, CX
	MOV	CX, midpoint_x
	SUB	CX, AX

	MOV	WORD PTR DS:[point_x], CX

	XOR	CX, CX
	MOV	CX, midpoint_y
	SUB	CX, BX

	MOV	WORD PTR DS:[point_y], CX

	CALL	draw_point

	POP CX
	POP BX
	POP AX
	RET
draw_symetric_points ENDP

draw_ellipse	PROC
	PUSH	AX
	PUSH	BX
	PUSH	CX

	; ========================== SETUP CONSTANTS ================================= ;

	XOR	AX, AX
	MOV	AX, WORD PTR DS:[ellipse_width]
	SHL	AX, 1				; divide by 2 using binary shift

	MOV	WORD PTR DS:[radius_width], AX		; store counted radius_width

	XOR	AX, AX
	MOV	AX, WORD PTR DS:[ellipse_height]
	SHL	AX, 1				; divide by 2 using binary shift

	MOV	WORD PTR DS:[radius_height], AX		; store counted radius_height
	POP	CX
	POP	BX
	POP	AX
	RET
draw_ellipse	ENDP

calculate PROC
	PUSH	AX
	PUSH	BX
	PUSH	CX

	XOR	AX, AX
	XOR	BX, BX
	
	MOV	AL, BYTE PTR DS:[nfirst]	; get first value
	MOV	BL, BYTE PTR DS:[nsecond]	; get second value

	MOV	SI, OFFSET oper			; get operator
	
	calculate_add:

		MOV	DI, OFFSET oplus	; get plus string offset
		CALL	cmp_str			; check if operator is plus
		JNE	calculate_sub
		
		; COUNT SUM ;

		ADD	AX, BX
		MOV	WORD PTR DS:[result], AX
		JMP	calculate_end

	calculate_sub:
	
		MOV	DI, OFFSET ominus	; get minus string offset
		CALL	cmp_str			; check if operator is minus
		JNE	calculate_mult
	
		; COUNT SUBSTRACTION ;

		SUB	AX, BX
		MOV	WORD PTR DS:[result], AX
		JMP	calculate_end

	calculate_mult:

		MOV	DI, OFFSET otimes	; get multiplication operator
		CALL	cmp_str			; check if operator is multiplication sign
		JNE	calculate_err

		MOV	CX, BX			; move second value to CX
		MUL	CX			; multiply by sign

		MOV	WORD PTR DS:[result], AX
		JMP	calculate_end

	calculate_err:
		MOV	DX, OFFSET error_parse_operator
		CALL	throw_exception
		RET

	calculate_end:

		POP	CX
		POP	BX
		POP	AX
		RET
calculate ENDP

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
	; 2h	- parse second

	MOV	AX, SEG DATA_SEG	; Load data segment
	
	; SET INITIAL STATE ;
	XOR	BL, BL
	MOV	BL, 0h

	remove_spaces:

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
		JE	parse_second

		CMP	CL, 0
		JE	parse_finish

		INC	SI
		JMP 	skip_spaces

	
	parse_first:
		MOV	DI, OFFSET ellipse_width
		JMP	parse_word
	
	parse_second:
		MOV	DI, OFFSET ellipse_height
		JMP	parse_word

	parse_word:

		PUSH	CX
		PUSH	AX
		PUSH	BX
		
		; ========== RESTORE PREVIOUS RESULT ====================== ;
		
		XOR	AX, AX			; clear ax
		
		MOV	AX, WORD PTR DS:[DI]	; get current result stored in memory

		MOV	BX, 10
		MUL	BX			; shift digits by base (10)

		XOR	BX, BX			; clear bx
		MOV	BL, BYTE PTR DS:[SI]	; get current source digit
		
		; ========== CHECK IF DIGIT ============================== ;

		CMP	BL, '0'
		JL	parse_value_exception

		CMP	BL, '9'
		JG	parse_value_exception
		
		; ========== PARSING ===================================== ;

		SUB	BL, '0'			; parse to integer
		ADD	AX, BX			; add to current number
		MOV	WORD PTR DS:[DI], AX	; store value in memory

		INC	SI

		POP	BX
		POP	AX
		POP	CX

		; ========== CHECK IF WHITESPACE ========================== ;

		MOV	AL, BYTE PTR DS:[SI]
		
		CMP	AL, ' '		; check if space
		JE	remove_spaces
	
		CMP	AL, 09h		; check if tabulation
		JE	remove_spaces

		CMP	AL, 0dh		; check if carriage return
		JE	parse_hub

		LOOP	parse_word
		

		; CHECK IF FIRST ARGUMMENT SET ;

		XOR	AX, AX
		MOV	AX, OFFSET ellipse_width
		CMP	AX, 0
		JE	parse_exception

		; CHECK IF SECOND ARGUMMENT SET ;

		XOR	AX, AX
		MOV	AX, OFFSET ellipse_height
		CMP	AX, 0
		JE	parse_exception

		JMP	parse_finish

	parse_exception:
		MOV	DX, OFFSET error_invalid_no_args
		CALL	throw_exception

	parse_value_exception:
		POP	CX
		POP	BX
		POP	AX
		MOV	DX, OFFSET error_parse_number
		CALL	throw_exception

	skip_spaces:

		MOV	AL, byte ptr ds:[SI]
		CMP	AL, ' '		; check if space
		JE	skip_spaces_end
		CMP	AL, 09h		; check if tabulation
		JE	skip_spaces_end
		CMP	AL, '$'		; check if end
		JE	parse_finish

		JMP	parse_exception

		skip_spaces_end:
			INC	SI
			LOOP	skip_spaces
			JMP 	parse_finish

	parse_finish:
		RET

parse_input ENDP

; [USAGE]:
; 	MOV	DX, OFFSET error_message
; 	CALL	throw_exception
; 
throw_exception PROC
	CALL	print_nl
	CALL	print
	CALL	exit
	RET
throw_exception ENDP

exit PROC
	MOV	AL, 0	; set program return value
	MOV	AH, 4CH	; set DOS code (exit)
	INT	21H	; DOS interrupt
	RET
exit ENDP

CODE_SEG ENDS

;--[STACK SEGMENT]---------------------------- ;

STACK_SEG SEGMENT STACK
	DW	300 DUP(?)
WSTOS1	DW	?
STACK_SEG ENDS

END START1