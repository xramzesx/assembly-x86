;--[DIRECTIVES]---------------------------- ;
.387
; =[CONSTANTS]=============================== ;
screen_max_x	EQU	320
screen_max_y	EQU	200

screen_min_x	EQU	4
screen_min_y	EQU	4

midpoint_x	EQU	screen_max_x / 2
midpoint_y	EQU	screen_max_y / 2

; =[SCAN CODES]============================== ;

scan_esc		EQU	1d	; exit
scan_q			EQU	16d	; change clean flag
scan_arrow_up		EQU	72d	; increase height
scan_arrow_down		EQU	80d	; decrease height
scan_arrow_left		EQU	75d	; decrease width
scan_arrow_right	EQU	77d	; increase widht
scan_space		EQU	57d	; next ellipse color

scan_w			EQU	17d	; next background color
scan_a			EQU	30d	; prev background color
scan_s			EQU	31d	; prev ellipse color
scan_d			EQU	32d	; next ellipse color

;--[DATA SEGMENT]---------------------------- ;
DATA_SEG SEGMENT

; =[BUFFERS]================================ ;
buff	DB 30, ?, 30 DUP('$')

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

; =[MESSAGES]================================ ;

message_intro		DB "Type required parameters (width and height): $"

; =[ERRORS]================================== ;

error_parse_number	DB "Invalid argument", 10, 13, "$" 
error_invalid_no_args	DB "Invalid number of arguments", 10, 13, "$"

; =[ELLIPSE WIDTH]============================ ;

ellipse_width	DW	0
ellipse_height	DW	0

radius_width	DW	0	; ellipse_width  / 2 == a	; for x
radius_height	DW	0	; ellipse_height / 2 == b	; for y

radius_width_pow	DW	0
radius_height_pow	DW	0

ellipse_x	DW	0	; for Bresenham algorithm x
ellipse_y	DW	0	; for Bresenham algorithm y

; =[RENDER]================================== ;

background_color	DB	1
point_x		DW	0
point_y		DW	0
point_color	DB	13

clean_screen_flag	DB	1

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

	; COPY BUFFER ;

	CLD
	REP	MOVSB


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


control_loop:

	; =========================== CLEAN SCREEN ===============================;

	MOV	AH, BYTE PTR DS:[clean_screen_flag]	; check clean flag
	CMP	AH, 0					; if flag is unset
	JE	control_draw_ellipse			; 	don't clean a screen
	CALL	clean_screen				; else: clean screen

	; =========================== DRAW ELLIPSE ===============================;

	control_draw_ellipse:
		CALL	draw_ellipse

	; =========================== GET CHAR ===================================;

	XOR	AX, AX
	INT	16h	; wait for any button

	; =========================== SCAN CODES =================================;

	XOR	AX, AX
	IN	AL, 060h	; read scan code

	; =============================  ESC  ====================================;

	CMP	AL, scan_esc	; if esc
	JE	control_exit

	; =============================   Q   ====================================;

	CMP	AL, scan_q
	JNE	control_space

	MOV	AH, BYTE PTR DS:[clean_screen_flag]
	
	unset_clean_screen_flag:
		CMP	AH, 0
		JE	set_clean_screen_flag

		MOV	BYTE PTR DS:[clean_screen_flag], 0
		JMP	control_loop_end

	set_clean_screen_flag:
		MOV	BYTE PTR DS:[clean_screen_flag], 1
		JMP	control_loop_end
	
	; ============================= SPACE ====================================;
	
	control_space:
		CMP	AL, scan_space
		JNE	control_w

		INC	BYTE PTR DS:[point_color]

		JMP	control_loop_end
	
	; =============================== B ======================================;
	
	control_w:
		CMP	AL, scan_w
		JNE	control_s

		INC	BYTE PTR DS:[background_color]

		JMP	control_loop_end

	; =============================== B ======================================;
	
	control_s:
		CMP	AL, scan_s
		JNE	control_d

		DEC	BYTE PTR DS:[background_color]

		JMP	control_loop_end

	; =============================== B ======================================;
	
	control_d:
		CMP	AL, scan_d
		JNE	control_a

		INC	BYTE PTR DS:[point_color]

		JMP	control_loop_end

	; =============================== B ======================================;
	
	control_a:
		CMP	AL, scan_a
		JNE	control_arrow_up

		DEC	BYTE PTR DS:[point_color]

		JMP	control_loop_end

	; ============================= ARROW UP =================================;
	
	control_arrow_up:
		CMP	AL, scan_arrow_up
		JNE	control_arrow_down

		MOV	SI, OFFSET ellipse_height
		CALL	increment_axis

		JMP	control_loop_end

	; =========================== ARROW DOWN =================================;
	
	control_arrow_down:
		CMP	AL, scan_arrow_down
		JNE	control_arrow_left

		MOV	SI, OFFSET ellipse_height
		CALL	decrement_axis

		JMP	control_loop_end
	; ============================= ARROW UP =================================;
	
	control_arrow_left:
		CMP	AL, scan_arrow_left
		JNE	control_arrow_right

		MOV	SI, OFFSET ellipse_width
		CALL	decrement_axis

		JMP	control_loop_end

	; =========================== ARROW DOWN =================================;
	
	control_arrow_right:
		CMP	AL, scan_arrow_right
		JNE	control_loop_end

		MOV	SI, OFFSET ellipse_width
		CALL	increment_axis

		JMP	control_loop_end


	; ========================= END CONTROL LOOP =============================;

	control_loop_end:
		JMP	control_loop

control_exit:
	CALL	set_text_mode

	CALL	EXIT


;=== PROCEDURES ===============================================;

;=== CHANGE MODES =============================================;

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

;=== PRINT STRINGS ============================================;

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

;=== RENDER ===================================================;

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

	MOV	CX, AX				; setup x = x
	ADD	CX, midpoint_x

	MOV	WORD PTR DS:[point_x], CX

	MOV	CX, BX				; setup y = y
	ADD	CX, midpoint_y

	MOV	WORD PTR DS:[point_y], CX

	CALL	draw_point

	;========= QUARTER II ==(-x,y)===================;

	XOR	CX, CX
	MOV	CX, midpoint_x
	SUB	CX, AX

	MOV	WORD PTR DS:[point_x], CX	; setup x = -x

	MOV	CX, BX				; setup y = y
	ADD	CX, midpoint_y

	MOV	WORD PTR DS:[point_y], CX

	CALL	draw_point

	;========= QUARTER III ==(x,-y)==================;

	MOV	CX, AX				; setup x = x
	ADD	CX, midpoint_x

	MOV	WORD PTR DS:[point_x], CX

	XOR	CX, CX
	MOV	CX, midpoint_y
	SUB	CX, BX

	MOV	WORD PTR DS:[point_y], CX	; setup y = - y

	CALL	draw_point

	;========= QUARTER IV ==(-x,-y)===================;

	XOR	CX, CX
	MOV	CX, midpoint_x
	SUB	CX, AX

	MOV	WORD PTR DS:[point_x], CX	; setup x = -x

	XOR	CX, CX
	MOV	CX, midpoint_y
	SUB	CX, BX

	MOV	WORD PTR DS:[point_y], CX	; setup y = -y

	CALL	draw_point

	POP CX
	POP BX
	POP AX
	RET
draw_symetric_points ENDP


; [USAGE]:
; 	MOV	WORD PTR DS:[ellipse_width], width_value
; 	MOV	WORD PTR DS:[ellipse_height], height_value
; 	MOV	WORD PTR DS:[point_color], color_value
; 	CALL 	draw_point
draw_ellipse	PROC
	PUSH	AX
	PUSH	BX
	PUSH	CX

	; ========================== SETUP CONSTANTS ================================= ;

	CALL	validate_ellipse_params

	XOR	AX, AX
	MOV	AX, WORD PTR DS:[ellipse_width]
	SHR	AX, 1				; divide by 2 using binary shift

	MOV	WORD PTR DS:[radius_width], AX		; store counted radius_width

	MUL	AX					; count power of radius_width
	MOV	WORD PTR DS:[radius_width_pow], AX	; store counted power

	XOR	AX, AX
	MOV	AX, WORD PTR DS:[ellipse_height]
	SHR	AX, 1				; divide by 2 using binary shift

	MOV	WORD PTR DS:[radius_height], AX		; store counted radius_height

	MUL	AX					; count power of radius_height
	MOV	WORD PTR DS:[radius_width_pow], AX	; store counted power

	; ========================== ELLIPSE DRAWING ================================= ;
	; ========================== ELLIPSE BY y(x) ================================= ;

	XOR	CX, CX
	MOV	CX, WORD PTR DS:[radius_width]

	MOV	WORD PTR DS:[ellipse_x], 0

	draw_ellipse_loop_y:
		PUSH	WORD PTR DS:[ellipse_x]

		CALL	calc_ellipse_y		; calculate ellipse y
		CALL	draw_symetric_points	; draw symetric ellipse by y

		; ============================================================= ;

		MOV	AX, WORD PTR DS:[ellipse_x]
		ADD	AX, midpoint_x
		MOV	WORD PTR DS:[ellipse_x], AX

		MOV	AX, WORD PTR DS:[ellipse_y]
		ADD	AX, midpoint_y
		MOV	WORD PTR DS:[ellipse_y], AX

		; ============================================================= ;

		POP	WORD PTR DS:[ellipse_x]

		INC	WORD PTR DS:[ellipse_x]
		LOOP	draw_ellipse_loop_y

	MOV	CX, WORD PTR DS:[radius_height]
	MOV	WORD PTR DS:[ellipse_y], 0

	; ========================== ELLIPSE BY x(y) ================================= ;

	draw_ellipse_loop_x:
		PUSH	WORD PTR DS:[ellipse_y]

		CALL	calc_ellipse_x		; calculate ellipse x
		CALL	draw_symetric_points	; draw symetric ellipse by x

		; ============================================================= ;

		MOV	AX, WORD PTR DS:[ellipse_x]
		ADD	AX, midpoint_x
		MOV	WORD PTR DS:[ellipse_x], AX

		MOV	AX, WORD PTR DS:[ellipse_y]
		ADD	AX, midpoint_y
		MOV	WORD PTR DS:[ellipse_y], AX

		; ============================================================= ;

		POP	WORD PTR DS:[ellipse_y]

		INC	WORD PTR DS:[ellipse_y]

		LOOP	draw_ellipse_loop_x

	; ============================== FINISH ====================================== ;

	POP	CX
	POP	BX
	POP	AX
	RET
draw_ellipse	ENDP

;=== CLEANING =================================================;

; [USAGE]:
;	MOV	BYTE PTR DS:[background_color], background_color_value
;	CALL	clean_screen
;
clean_screen PROC
	PUSH	AX
	PUSH	ES

	MOV	AX, 0A000h	; offset to video mapped memory
	MOV	ES, AX		; move mapped offset to ES
	MOV	AX, 0		; setup (x,y)=(0,0)
	MOV	DI, AX		; load coords to DI

	MOV	AL, BYTE PTR DS:[background_color]	; SETUP COLOR

	MOV	CX, screen_max_y * screen_max_x		; setup max coords value

	REP	STOSB	; point the whole screen with grey
			; store AL value as whole string
	POP	ES
	POP	AX
	RET
clean_screen ENDP

;=== CALCULATIONS =============================================;

calc_ellipse_y PROC
	FINIT	; reset fpu

	FILD	WORD PTR DS:[ellipse_x]	; x
	FMUL	ST(0), ST(0)		; x * x

	FILD	WORD PTR DS:[radius_width]	; a
	FMUL	ST(0), ST(0)			; a * a

	FSUB	ST(0), ST(1)			; a * a - x * x
	
	FSQRT					; sqrt(a * a - x * x)

	FILD	WORD PTR DS:[radius_height]	; b
	FMUL					; b * sqrt(a * a - x * x)

	FILD	WORD PTR DS:[radius_width]	; a
	FDIVP	ST(1), ST(0)			; b / a * sqrt(a * a - x * x)

	FIST	WORD PTR DS:[ellipse_y]		; store new y value

	RET
calc_ellipse_y ENDP

calc_ellipse_x PROC
	FINIT	; reset fpu

	FILD	WORD PTR DS:[ellipse_y]	; y
	FMUL	ST(0), ST(0)		; y * y

	FILD	WORD PTR DS:[radius_height]	; b
	FMUL	ST(0), ST(0)			; b * b

	FSUB	ST(0), ST(1)			; b * b - y * y
	
	FSQRT					; sqrt(b * b - y * y)

	FILD	WORD PTR DS:[radius_width]	; a
	FMUL					; a * sqrt(b * b - y * y)

	FILD	WORD PTR DS:[radius_height]	; b
	FDIVP	ST(1), ST(0)			; a / b * sqrt(b * b - y * y)

	FIST	WORD PTR DS:[ellipse_x]		; store new x value

	RET
calc_ellipse_x ENDP

;=== UTILS ===========================================;

validate_ellipse_params PROC
	PUSH	AX

	
	validate_width_max:
		MOV	AX, WORD PTR DS:[ellipse_width]

		CMP	AX, screen_max_x	; if less than screen_max_x
		JLE	validate_width_min	; jump to validate min

		MOV	WORD PTR DS:[ellipse_width], screen_max_x - 1

		JMP	validate_height_max

	validate_width_min:
		CMP	AX, screen_min_x
		JGE	validate_height_max
		
		MOV	WORD PTR DS:[ellipse_width], screen_min_x

		JMP	validate_height_max

	validate_height_max:
		MOV	AX, WORD PTR DS:[ellipse_height]

		CMP	AX, screen_max_y	; if less than screen_max_x
		JLE	validate_height_min	; jump to validate min

		MOV	WORD PTR DS:[ellipse_height], screen_max_y - 1

		JMP	validate_height_min
		
	
	validate_height_min:
		CMP	AX, screen_min_y
		JGE	validate_end

		MOV	WORD PTR DS:[ellipse_height], screen_min_y

		JMP	validate_end


	validate_end:
		POP	AX
		RET
validate_ellipse_params ENDP

; [USAGE]:
; 	MOV si, OFFSET source_axis
; 	CALL increment_axis
increment_axis PROC
	INC	WORD PTR DS:[SI]
	INC	WORD PTR DS:[SI]
	RET
increment_axis ENDP

; [USAGE]:
; 	MOV si, OFFSET source_axis
; 	CALL decrement_axis
decrement_axis PROC
	DEC	WORD PTR DS:[SI]
	DEC	WORD PTR DS:[SI]
	RET
decrement_axis ENDP

;=== BUFFER PARSING ===========================================;

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

;=== EXIT & EXCEPTIONS ========================================;

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