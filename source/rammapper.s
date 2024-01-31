;----------------------------------------------------------
;		rammapper.s - by Danilo Angelo, 2024
;
;		Support basic mapper routines.
;
;       This file is HEAVILY based on
;		FUSION-C's rammapper.s, by 
;       Eric Boez &  Fernando Garcia
;		(Bitvision, 2018)
;		https://github.com/ericb59/FUSION-C-1.3
;----------------------------------------------------------

	.include "applicationsettings.s"	; must define __SDCCCALL
;	or define __SDCCCALL manually:
; __SDCCCALL = 0 (SDCCCALL(0))
; __SDCCCALL = 1 (SDCCCALL(1))

	.include "MSX/BIOS/msxbios.s"
;	or define BIOS_FCALL manually:
;BIOS_FCALL = 0xFFCA

	.area	CODE

; ----------------------------------------------------------------
; - Init Mapper Data Structures
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Device Id
;	- [__SDCCCALL(1)] a:	Device Id
;
;	DeviceId:
;		00h  reserved for broadcasts
;		04h  DOS2 memory routines (USUALLY THIS!)
;		08h  RS232
;		0Ah  MSX-AUDIO
;		11h  Kanji
;		22h  UNAPI (konamiman)
;		4Dh  Memman
;		FFh  System exclusive
; OUTPUTS:
;   - None.
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_InitRamMapperInfo::
.ifeq __SDCCCALL
	ld      hl, #2
	add     hl, sp
	ld		d, (hl)						;deviceId
.else
	ld		d, a						;deviceId
.endif

	; initialize pointer to mapper base table
	push 	ix
	xor		a
	ld		e, #1						;function
	call	BIOS_FCALL
	ld		(#_rammapper_table), hl

	; initialize mapper routines table
	xor		a
	ld		de, #0x0402
	call	BIOS_FCALL
	ld		(#_rammapper_routinestable),hl
	ld		de,#__Allocate
	ld		bc,#(3*16)
	ldir
	
	pop		ix
	ret


; ----------------------------------------------------------------
; - Get pointer to mapper base table
; ----------------------------------------------------------------
; INPUTS:
;	- None.
; OUTPUTS:
;	- [__SDCCCALL(0)] hl:	Pointer to mapper base table
;	- [__SDCCCALL(1)] de:	Pointer to mapper base table
; CHANGES:
;   - hl, de (__SDCCCALL(1) only)
; ----------------------------------------------------------------
_GetRamMapperBaseTable::
	ld		hl,(#_rammapper_table)
.ifne __SDCCCALL
	ld		d, h
	ld		e, l
.endif
	ret


; ----------------------------------------------------------------
; - Allocate Mapper Segment
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Segment Type
;	- [__SDCCCALL(0)] SP+3: Slot Address and Allocation Strategy
;	- [__SDCCCALL(1)] a:	Segment Type
;	- [__SDCCCALL(1)] l:	Slot Address and Allocation Strategy
;
;	Segment Type:
;		0	User segment
;		1	System segment
;
;	Slot Address and Allocation Strategy
;		0			Allocate primary mapper
;		F0xxSSPP:
;			PP		Primary slot
;			SS		Secondary slot
;			xx:
;				00	Allocate specified slot only
;               01	Allocate other slots than specified
;               10	Try to allocate specified slot and, if it failed, try another slot (if any)
;               11	Try to allocate other slots than specified and, if it failed, try specified slot
;			F		Slot Expanded Flag
; OUTPUTS:
;	- [__SDCCCALL(0)] hl:	F000SSPP yyyyyyyy
;	- [__SDCCCALL(1)] de:	F000SSPP yyyyyyyy
;		yyyyyyyy	Segment Number	(0 if failed)
;		F000SSPP	Mapper slot address (0 if called as B=0, or failed)
;	- Carry flag:	set if failed
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_AllocateSegment::
.ifeq __SDCCCALL
	ld      hl, #2
	add     hl, sp
	ld		a, (hl)						; segmentType
	inc		hl
	ld		b, (hl)						; slotAddress
.else
	ld		b, l						; slotAddress
.endif

	push 	ix
	call	__Allocate
	pop		ix

	jr nc, _AllocateSegment_end
	xor		a
	ld		b, a
	scf

_AllocateSegment_end:
.ifeq __SDCCCALL
	ld		l, a
	ld		h, b
.else
	ld		e, a
	ld		d, b
.endif
	ret


; ----------------------------------------------------------------
; - Free Mapper Segment
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Segment Number
;	- [__SDCCCALL(0)] SP+3: Mapper Slot Address
;	- [__SDCCCALL(1)] a:	Segment Number
;	- [__SDCCCALL(1)] l:	Mapper Slot Address
;
;	Mapper Slot Address:
;		0	Primary mapper
;		>0	Other mapper
;
; OUTPUTS:
;	- [__SDCCCALL(0)] a:	Success
;	- [__SDCCCALL(1)] l:	Success
;
;	Success:
;		0	False, fail
;		1	True, success
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_FreeSegment::
.ifeq __SDCCCALL
	ld      hl, #2
	add     hl, sp
	ld		a, (hl)						; segment number
	inc		hl
	ld		b, (hl)						; mapper
.else
	ld		b, l						; mapper
.endif
	and		#0b10001111					; make xxx irrelevant. TO DO: check if need

	push 	ix
	call	__Free
	pop		ix

	xor		a							; Zero, false, fail
	ret nc
	inc		a							; One, true, success
	ret

; ----------------------------------------------------------------
; - Get Segment Number of a Memory page
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Memory Page (0-3)
;	- [__SDCCCALL(1)] a:	Memory Page (0-3)
;
; OUTPUTS:
;	- [__SDCCCALL(0)] a:	Segment number
;	- [__SDCCCALL(1)] l:	Segment number
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_Get_PN::
.ifeq __SDCCCALL
	ld      hl, #2
	add     hl, sp
	ld		a, (hl)						; XXXX
.endif

	push 	ix
	ld		hl,#_Get_PN_return
	push	hl
	or		a
	jp		z,__GetP0
	dec		a
	jp		z,__GetP1
	dec		a
	jp		z,__GetP2
	jp		__GetP3
	
_Get_PN_return:
.ifeq __SDCCCALL
	ld		l, a
.endif

	pop ix
	ret


; ----------------------------------------------------------------
; - Put Segment Number in Memory page
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Segment Number
;	- [__SDCCCALL(0)] SP+3: Page
;	- [__SDCCCALL(1)] a:	Segment Number
;	- [__SDCCCALL(1)] l:	Page
;
; OUTPUTS:
;	- None.
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_Put_PN::
.ifeq __SDCCCALL
	ld      hl, #2
	add     hl, sp
	ld		a, (hl)						; segmentNumber
	inc		hl
	ld		b, (hl)						; page
.else
	ld		b, l						; page
.endif

_Put_PN_ab::
	push 	ix
	ld		hl,#_Put_PN_return
	push	hl

	inc		b
	dec		b
	jp		z,__PutP0
	dec		b
	jp		z,__PutP1
	dec		b
	jp		z,__PutP2
	jp		__PutP3
	
_Put_PN_return:
	pop ix
	ret



; ----------------------------------------------------------------
	.area	DATA

_rammapper_table:			.dw	#0

_rammapper_routinestable:	.dw	#0

__Allocate::
	.ds	3
__Free::
	.ds	3
__Read::
	.ds	3
__Write::
	.ds	3
__Call_Seg::
	.ds	3
__Calls::
	.ds	3
__PutPH::
	.ds	3
__GetPH::
	.ds	3
__PutP0::
	.ds	3
__GetP0::
	.ds	3
__PutP1::
	.ds	3
__GetP1::
	.ds	3
__PutP2::
	.ds	3
__GetP2::
	.ds	3
__PutP3::
	.ds	3
__GetP3::
	.ds	3
