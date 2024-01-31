; ----------------------------------------------------------------
;	mnemosyne-x_init.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the implementation of _initMnemosyneX.
; ----------------------------------------------------------------

.include "msxbios.s"

	.include "MSX/BIOS/msxbios.s"
	.include "applicationsettings.s"

	.include "config/mnemosyne-x_config.s"

	.include "printinterface.s"

	.include "rammapper_h.s"
	.include "printdec_h.s"

; ----------------------------------------------------------------
;	- Macros
; ----------------------------------------------------------------
.macro	__PutPage PAGE
.ifeq PAGE
	call	__PutP0
.else
	.ifeq PAGE - 1
	call	__PutP1
	.else
		.ifeq PAGE - 2
	call	__PutP2
		.endif
	.endif
.endif
.endm

.macro	__PutPMain
	__PutPage	MNEMO_MAIN_SWAP_PAGE
.endm

.macro	__PutPAux
	__PutPage	MNEMO_AUX_SWAP_PAGE
.endm

;   ==================================
;   ========== CODE SEGMENT ==========
;   ==================================
	.area _CODE

; ----------------------------------------------------------------
;	- Init MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- A: Use primary mappers only (if MNEMO_PRIMARY_MAPPER_ONLY = 0).
;			0 = All mappers
;			1 = Primary mapper only
;
; OUTPUTS:
;   - A:  0 = Success
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_initMnemosyneX::
	di 
	push	ix

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		(#usePrimaryMapperOnly), a
.endif

	print	initializingMnemosynex
	print	mnemosynexVirtualMemSize
	ld		hl, #MNEMO_MAX_LOGICAL_MEMORY
	call	_PrintDec
	print	megaBytesMsg

	; init mapper mgr
	print	initializingMapperMsg
	ld		a, #MNEMO_MAPPER_DEVICE_ID
	call	_InitRamMapperInfo

	; get mapperBaseTable address
	call	_GetRamMapperBaseTable
	ex		de, hl
	ld		(#_pMapperBaseTable), hl

	; set mapper query tag
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	dec		a						; a = 0 => primary mapper only
	jr z,	_initMnemosyneX_setQueryTag
	ld		a, #0b00100000			; Try to specified slot and, if it failed, try another slot (if any)
_initMnemosyneX_setQueryTag:
	or		(hl)					; primary mapper slot
	ld		(#mapperQueryTag), a
.endif

	print	okMsg


	; allocate index segments
	call	_saveMemoryMap
	print	allocatingIndexSegmentsMsg
	ld		hl, #segTableSegment
	ld		b, #MNEMO_INDEX_SEGMENTS + 1

_initMnemosyneX_indexSegAllocLoop:
	exx
	xor		a						; user segment
	ld		l, a					; primary mapper only
	call	_AllocateSegment		; alternate regs are preserved
	ld		a, #MNEMO_ERROR_NOINDEXSEG
	jp c,	_initMnemosyneX_end		; No more available segments
	
	; save segHandler
	ld		a, e
	exx
	ld		(hl), a
	inc		hl
	djnz	_initMnemosyneX_indexSegAllocLoop

	print	okMsg

	; allocate all available segments
	; Note: allocate all other segments needed
	; by the application BEFORE calling _initMnemosyneX!
	print	allocatingSegmentsMsg

	; Set Segment Table segment in Aux Page
	ld		hl, (#_pMapperBaseTable)
	ld		a, (hl)					; SlotId for Primary Mapper
	ld		h, #MNEMO_AUX_SWAP_PAGE << 6	; Page
	call	BIOS_ENASLT				; enable primary mapper slot in page 1
	ld		a, (#segTableSegment)
	__PutPAux

	; segments allocation loop
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR
	push	hl
_initMnemosyneX_segAllocLoop::
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#mapperQueryTag)
	ld		l, a					; which mappers
	xor		a						; user segment
.else
	xor		a						; user segment
	ld		l, a					; which mappers
.endif
	call	_AllocateSegment
	pop		hl						; hl => next entry in segmentTable
	jr c,	_initMnemosyneX_cont	; No more available segments

	; save entry in segmentTable
	ld		(hl), e
	inc		hl
	ld		(hl), d

	; mark segment's header with logSegNumber = 0xffff (invalid) ;;'
	push	hl
	dec		hl						; hl = pSegHandler
	call	activateSegment
	ld		hl, #0xffff				; invalid logSegNumber
	ld		(#MNEMO_MAIN_SWAP_PAGE_ADDR), hl	; mark
	pop		hl
	inc		hl						; next table entry

_initMnemosyneX_printDash:
	ld		a, #'-'
	push	hl
	call	printchar
	jr		_initMnemosyneX_segAllocLoop

_initMnemosyneX_cont:
	ld		de, #MNEMO_AUX_SWAP_PAGE_ADDR
	sbc		hl, de
	srl		h
	rr		l						; hl = #segments
	push	hl
	ld		a, l
	ld		(#_numberPhysicalSegs), a
	ld		a, h
	ld		(#_numberPhysicalSegs + 1), a
	print	okMsg	

	pop		hl
	push	hl
	call	_PrintDec
	print	segmentsAllocatedMsg
	print	memoryManaged1Msg
	pop		hl
	add		hl, hl
	add		hl, hl
	add		hl, hl
	add		hl, hl
	call	_PrintDec
	print	memoryManaged2Msg

_initMnemosyneX_end:
	call	_restoreMemoryMap
	pop		ix
	ei
	ret

; ----------------------------------------------------------------
;	- Save memory map
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - Memory map variables
; ----------------------------------------------------------------
_saveMemoryMap::
	in		a, (#0xa8)
	ld		(#primarySlots), a
	ld		a, (#0xffff)
	cpl
	ld		(#secondarySlots), a
	call	__GetP0
	ld		(#segmentP0), a
	call	__GetP1
	ld		(#segmentP1), a
	call	__GetP2
	ld		(#segmentP2), a
	ret

; ----------------------------------------------------------------
;	- Restore memory map
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - Memory map restored from variables
; ----------------------------------------------------------------
_restoreMemoryMap::
	ld		a, (#primarySlots)
	out		(#0xa8), a
	ld		a, (#secondarySlots)
	ld		(#0xffff), a
	ld		a, (#segmentP0)
	call	__PutP0
	ld		a, (#segmentP1)
	call	__PutP1
	ld		a, (#segmentP2)
	call	__PutP2
	ret

; ----------------------------------------------------------------
;	- Activates a segment from a Segment Handler in page 2
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to Segment handler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
activateSegment::
	ld		a, (hl)			; segNumber
	__PutPMain

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	inc		hl
	ld		a, (hl)			; slotid
	ld		h, #MNEMO_MAIN_SWAP_PAGE << 6	; Page
	jp		BIOS_ENASLT		; select slot
.else
	ret
.endif

; ----------------------------------------------------------------
;	- Strings
; ----------------------------------------------------------------
initializingMnemosynex:	.asciz "** MnemoSyne-X Virtual Memory **\n\r"
mnemosynexVirtualMemSize:	.asciz "Virtual Memory Size is "
initializingMapperMsg:		.asciz "Initializing mapper service..."
allocatingIndexSegmentsMsg:	.asciz "Allocating index segments... "
allocatingSegmentsMsg:		.asciz "Allocating segments...\n\r=> "
segmentsAllocatedMsg:		.asciz " segments allocated.\n\r"
memoryManaged1Msg:			.asciz "Managing "
memoryManaged2Msg:			.asciz "Kbytes of physical memory.\n\r"
kiloBytesMsg:				.asciz "Kbytes.\n\r"
megaBytesMsg:				.asciz "Mbytes.\n\r"

okMsg::						.asciz " [OK]\n\r"

;   ==================================
;   ========== DATA SEGMENT ==========
;   ==================================
    .area	_DATA

_pMapperBaseTable::			.ds 2
_numberPhysicalSegs::		.ds 2
segTableSegment::			.ds 1
segIndexTable::				.ds MNEMO_INDEX_SEGMENTS

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
usePrimaryMapperOnly::		.ds 1
mapperQueryTag::			.ds 2
.endif

pLogSegHandler:				.ds 2
logSegNumber:				.ds 2
segIndexSegment:			.ds 1
pSegIndex:					.ds 2
pSegHandler:				.ds 2
pLogSegTableItem:			.ds 2
pLogSegTableSegment:		.ds 2
logSegLoaded:				.ds 1

primarySlots:				.ds 1
secondarySlots:				.ds 1
segmentP0:					.ds 1
segmentP1:					.ds 1
segmentP2:					.ds 1

