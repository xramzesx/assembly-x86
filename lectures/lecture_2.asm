; =============================================== ;
; This file contains working assembly code, that
; write some text on output
; =============================================== ;

; Data segment ;

DATA1 SEGMENT
DATA1 ENDS

; Code segment ;

CODE1 SEGMENT

; Offset START1
; Note: every offset need to be closed using END 
; keyword (see last line of this file)

START1:

	; LOAD STACK SEGMENT ;
	; TO SS ;
	MOV	AX, SEG STOS1
	MOV 	SS, AX
	MOV	SP, OFFSET WSTOS1
	
	; DISPLAY TEXT ;
	; LOAD TO AX ;
	MOV 	AX, SEG t1
	MOV	DS, AX
	MOV	DX, OFFSET t1
	MOV	AH,9	; DISPLAY TEXT DS:DX
	INT	21h;

	; END PROGRAM ;

	MOV	AL,0	; set value that OS return
	MOV	AH,4CH 	; value for ending program
	INT	21h		; DOS interrupt

; We can store our data here ;
; after instructions above ;
; whole program exit ;

t1	DB "To jest tekst! $"

CODE1 ENDS

STOS1 SEGMENT STACK
	; Here we define 300 words with initial value. ;
	; Currently we don't need to have any initial ;
	; value. ;
	DW	300 DUP(?)

; WSTOS1 is only stack name!

; Question mark here means that we define
; stack with 2 bytes without and we don't care
; what's currently inside 
WSTOS1	DW	?
STOS1 ENDS

END START1