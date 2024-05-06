;----------------------------------------------------------
;		printdec.s
;----------------------------------------------------------
;		240113 - danilo angelo
;----------------------------------------------------------
;		Implements:
;			void _PrintDec ( unsigned int number );
;----------------------------------------------------------
	.include "applicationsettings.s"	; or define __SDCCCALL
	.include "targetconfig.s"			; or define 

	.globl printchar

	.area _CODE

; ----------------------------------------------------------
;	void _PrintDec ( unsigned int number );
_PrintDec::
	push	ix

.ifeq __SDCCCALL
	ld		hl, #4
	add		hl, sp
	ld		a, (hl)
	inc		hl
	ld		h, (hl)
	ld		l, a				; number
.endif
	ld		e, #0				; not started

	ld		bc,	#-10000
    call	findDigit
	ld		bc,	#-1000
    call	findDigit
	ld		bc,	#-100
    call	findDigit
	ld		c,	#-10			; b = 0xff
    call	findDigit

    ;Last figure
    ld		c, b				; bc = 0xffff
	inc		e					; started
    call	findDigit

	pop		ix
	ret

; ----------------------------------------------------------
;	Find Next Digit
findDigit:  
	ld		a, #'0' - 1
   
findDigit_loop:  
	inc		a
	add		hl, bc
	jr c,	findDigit_loop
  
	sbc		hl, bc
  
	cp		#'0'
	jr nz,	findDigit_printChar

	dec		e
	inc		e
	ret z

findDigit_printChar:
	inc		e
.ifne MSXDOSPRINT
	exx
	call	printchar
	exx
.else
	push	hl
	push	de
	push	bc
	call	printchar
	pop		bc
	pop		de
	pop		hl
.endif

	ret

