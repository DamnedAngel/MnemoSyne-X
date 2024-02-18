; ----------------------------------------------------------------
;	mnemosyne-x.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
; ----------------------------------------------------------------

.include "msxbios.s"
.include "applicationsettings.s"
.include "printinterface.s"
.include "printdec_h.s"

.include "rammapper_h.s"

.include "config/mnemosyne-x_config.s"
.include "mnemosyne-x-macros_h.s"

.globl _rnd16
.globl _standardLoad

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
_initMnemoSyneX::
	push	ix

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		(#usePrimaryMapperOnly), a
.endif

	print	initializingMnemosynex

	; init mapper mgr
	print	initializingMapperMsg
	ld		a, #MNEMO_MAPPER_DEVICE_ID
	call	_InitRamMapperInfo

	; get mapperBaseTable address
	call	_GetRamMapperBaseTable
	ex		de, hl
	ld		(#_pMapperBaseTable), hl
	ld		a, (hl)
	ld		(#_primaryMapperSlot), a

	ld		hl, #pageConfigGlobalBuffer
	call	_savePageConfig

	; set mapper query tag
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	dec		a						; a = 0 => primary mapper only
	jr z,	_initMnemoSyneX_setQueryTag
	ld		a, #0b00100000			; Try to specified slot and, if it failed, try another slot (if any)
_initMnemoSyneX_setQueryTag:
	or		(hl)					; primary mapper slot
	ld		(#mapperQueryTag), a
.endif

	print	okMsg

	; allocate index segments
	print	allocatingIndexSegmentsMsg
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		hl, #bufferSegment
	ld		b, #MNEMO_INDEX_SEGMENTS + 2
.else
	ld		hl, #segTableSegment
	ld		b, #MNEMO_INDEX_SEGMENTS + 1
.endif

_initMnemoSyneX_indexSegAllocLoop::
	exx
	xor		a						; user segment
	ld		l, a					; primary mapper only
	call	_AllocateSegment		; alternate regs are preserved
	ld		a, #MNEMO_ERROR_NOINDEXSEG
	jp c,	_initMnemoSyneX_end		; No more available segments
	
	; save segHandler
	ld		a, e
	exx
	ld		(hl), a
	inc		hl

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#_primaryMapperSlot)
	ld		(hl), a
	inc		hl
.endif

	djnz	_initMnemoSyneX_indexSegAllocLoop

	print	okMsg

	; allocate all available segments
	; Note: allocate all other segments needed
	; by the application BEFORE calling _initMnemoSyneX!
	print	allocatingSegmentsMsg

	; Set Segment Table segment in Aux Page
	ld		hl, #segTableSegment
	call	_switchAuxPage

	; segments allocation loop
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR
	push	hl
_initMnemoSyneX_segAllocLoop::
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
	jr c,	_initMnemoSyneX_cont	; No more available segments

	; save entry in segmentTable
	ld		(hl), e
	inc		hl
	ld		(hl), d

	; mark segment's header with logSegNumber = 0xffff (invalid) ;;'
	push	hl
	dec		hl						; hl = pSegHandler
	call	_switchMainPage
	ld		hl, #0xffff				; invalid logSegNumber
	ld		(#MNEMO_MAIN_SWAP_PAGE_ADDR), hl	; mark
	pop		hl
	inc		hl						; next table entry

_initMnemoSyneX_printDash:
	ld		a, #'-'
	push	hl
	call	printchar
	jr		_initMnemoSyneX_segAllocLoop

_initMnemoSyneX_cont:
	ld		(#afterSegTable), hl
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

	print	mnemosynexVirtualMemSize
	ld		hl, #MNEMO_MAX_LOGICAL_MEMORY
	call	_PrintDec
	print	megaBytesMsg

_initMnemoSyneX_end:
	ld		hl, #pageConfigGlobalBuffer
	call	_restorePageConfig
	pop		ix
	ret

	
; ----------------------------------------------------------------
;	- Finalize MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   -None
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_finalizeMnemoSyneX::
	; TODO: Decide whether to deallocate segments.
	; In principle, that is not needed, since MSX-DOS will
	; deallocate them automatically.
	ld		hl, #pageConfigGlobalBuffer
	call	_restorePageConfig
	ret


; ----------------------------------------------------------------
;	- Activates a logical segment
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to logical segment handler
;
; OUTPUTS:
;   - A:  0 = Success
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_activateLogSeg::
	push	ix

	xor		a
	ld		(#logSegLoaded), a
	ld		(#pLogSegHandler), hl

	ld		hl, #auxSegHandlerTemp
	call	_saveAuxPageConfig

	; copy logSegHandler to page 3
	ld		de, #logSegHandler
	ld		bc, #(logSegHandler_end - logSegHandler)
	ld		hl, (#pLogSegHandler)
	ldir

	; transform logSegNumber in pLogSegTableSegment & pLogSegTableItem
	ld		hl, (#logSegNumber)
	xor		a
	sla		l
	rl		h
	rl		a
	sla		h
	rl		a
.ifne	(MNEMO_AUX_SWAP_PAGE & 2)
	inc		h
.endif
	sla		h
	rl		a				; a = logSegTableSegIndex
.ifne	(MNEMO_AUX_SWAP_PAGE & 1)
	inc		h
.endif
	rrc		h
	rrc		h				; hl = pLogSegTableItem (AUX page)
	ld		(#pLogSegTableItem), hl
	
	cp		#(MNEMO_INDEX_SEGMENTS)
	jp nc,	_activateLogSeg_segOutOfRangeError

	; activate proper logSegTableSegment
	ld		hl, #segIndexTable
;.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	add		a, a			; unit is segHandler, but in primary mapper only the slot is not used
;.endif
	add		a, l			;TODO: ld e, a + ld d, #0 + add hl, de
	ld		l, a
	adc		a, h
	sub		l   
	ld		h, a			; hl = pLogSegTableSegment
	ld		(#pLogSegTableSegment), hl		; To do: Check whether this is really needed.
	call	_switchAuxPage

	; find pSegHandler
	ld		hl, (#pLogSegTableItem)
	ld		a, (hl)
	inc		hl
	ld		h, (hl)
	ld		l, a			; hl = LogSegTable.pSegHandler
	ld		(#pSegHandler), hl

	; check whether pSegHandler is valid
	; 1. Verify whether pSegHandler is even
	and		#1
	jr nz,	_activateLogSeg_activateSegTableForSearch		; not valid

	; 2. Verify whether pSegHandler >= SegTable start
	xor		a				; clear carry flag
	ld		de, #MNEMO_AUX_SWAP_PAGE_ADDR
	sbc		hl, de
	add		hl, de			
	jr c,	_activateLogSeg_activateSegTableForSearch		; not valid

	; 3. Verify whether pSegHandler <= SegTable end
	xor		a				; clear carry flag
	ex		de, hl
	ld		hl, (#afterSegTable)
	ex		de, hl
	sbc		hl, de
	add		hl, de			
	jr nc,	_activateLogSeg_activateSegTableForSearch		; not valid

	; activate setTableSegment
	push	hl
	ld		hl, #segTableSegment
	call	_switchAuxPage

	; activate target segment
	pop		hl
	call	_switchMainPage

	; check if target segment contains correct logSegNumber
	; (equal to logSegHandler.logSegNumber)
	xor		a
	ld		hl, (#logSegNumber)
	ex		de, hl
	ld		hl, (#MNEMO_SEGHDR_LOGSEGNUMBER)
	sbc		hl, de
	jr nz,	_activateLogSeg_searchFreeSeg		; nope

	; logSeg already loaded
	ld		a, #1
	ld		(#logSegLoaded), a
	jp		_activateLogSeg_updateSegmentHeader

_activateLogSeg_activateSegTableForSearch:
	ld		hl, #segTableSegment
	call	_switchAuxPage

_activateLogSeg_searchFreeSeg:
	; define random starting point for free segment search
	call	_rnd16
	ld		a, (#_numberPhysicalSegs)
	ld		c, a
	exx
	ld		c, a
	ld		a, (#_numberPhysicalSegs + 1)
	ld		b, a
	exx
	ld		b, a
	or		a				; reset carry flag

_activateLogSeg_rndLoop:
	; makes random point within Segment Table
	srl		d
	rr		e
	or		a				; reset carry flag
	sla		c
	rl		b
	jr nc,	_activateLogSeg_rndLoop
	sla		e
	rl		d				; de = pSegHandler (search starting pointer) - MNEMO_AUX_SWAP_PAGE_ADDR
	inc		de				; de = p(SegHandler.mapperSlot) - MNEMO_AUX_SWAP_PAGE_ADDR

	; search free segment
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR
	add		hl, de			; hl = p(SegHandler.mapperSlot)
	ld		de, #0xffff		; invalid pSegHandler
	ld		c, #0x30			; best status

_activateLogSeg_searchLoop:
	ld		a, (hl)
	and		#0b00110000		; seg status
	cp		c
	jr nc,	_activateLogSeg_searchLoop_cont1

	; found a better candidate
	ld		c, a
	ld		d, h
	ld		e, l
	or		a
	jr z,	_activateLogSeg_activateSegment		; priority 0, position chosen

_activateLogSeg_searchLoop_cont1:
	dec		hl
	ld		a, h
	sub		#<MNEMO_AUX_SWAP_PAGE
	or		l
	jr nz,	_activateLogSeg_searchLoop_cont2
	ld		hl, (#afterSegTable)
	dec		hl

_activateLogSeg_searchLoop_cont2:
	dec		hl	
	exx
	dec		bc
	ld		a, b
	or		c				; all table positions were checked?
	exx
	jr nz,	_activateLogSeg_searchLoop	; not yet, continue search

	; end of segTable
	ld		a, c
	cp		#0x30
	jp z,	_activateLogSeg_noFreePhysSegError

_activateLogSeg_activateSegment:
	; update logSegHandler with segHandler
	; de = p(SegHandler.mapperSlot)
	dec		de				; de = pSegHandler
	ex		de, hl
	ld		(#pSegHandler), hl
	; activate segment
	call	_switchMainPage

	; check whether selected segment should be saved
	; check logSegNumber
	; TODO: compare HL to DE with SBC/sub
	ld		hl, #MNEMO_SEGHDR_LOGSEGNUMBER
	ld		a, #0xff
	cp		(hl)
	jr nz,	_activateLogSeg_checkWriteMode
	inc		hl
	cp		(hl)
	jr z,	_activateLogSeg_updateSegmentHeader	; invalid segment, skip save
_activateLogSeg_checkWriteMode:
	ld		a, (#MNEMO_SEGHDR_SEGMODE)
	ld		b, a
	and		#3				; test RW mode
	cp		#MNEMO_SEGMODE_READWRITE
	jr z,	_activateLogSeg_updateSegmentHeader	; no write, skip save

_activateLogSeg_save:
	; check if custom write routine
	ld		a, b
	and		#MNEMO_SEGMODE_CUSTOMWRITE
	jr z,	_activateLogSeg_standardSave
	
	; custom save
	ld		hl, #_activateLogSeg_updateSegmentHeader
	push	hl						; return point
	ld		hl, (#MNEMO_SEGHDR_PSAVESEG)
	ld		e, (hl)
	inc		hl
	ld		d, (hl)					; de = custom save routine
;	ld		hl, #MNEMO_MAIN_SWAP_PAGE_ADDR
;	push	de						; prepare call
	ret								; call de (THIS IS NOT A REAL RET!)

_activateLogSeg_standardSave:
;	ld		hl, #MNEMO_MAIN_SWAP_PAGE_ADDR
;	call	_standardSave

_activateLogSeg_updateSegmentHeader:
	ld		hl, (#logSegNumber)
	ld		(#MNEMO_SEGHDR_LOGSEGNUMBER), hl
	ld		a, (#logSegMode)
	ld		(#MNEMO_SEGHDR_SEGMODE), a
	ld		hl, (#pSaveSeg)
	ld		(#MNEMO_SEGHDR_PSAVESEG), hl

_activateLogSeg_updateSegTable:
	ld		hl, (#pSegHandler)
	ld		a, (hl)
	ld		(#segNumber), a
	inc		hl
	ld		a, (hl)
	or		#0b00110000		; In use
	ld		(hl), a
	ld		(#mapperSlot), a

_activateLogSeg_updateLogSegTable::
	exx
	ld		hl, (#pLogSegTableSegment)
	call	_switchAuxPage
	exx
	dec		hl
	ex		de, hl
	ld		hl, (#pLogSegTableItem)
	ld		(hl), e
	inc		hl
	ld		(hl), d

_activateLogSeg_checkReadMode::
	ld		a, (#logSegMode)
	ld		b, a
	and		#3
	jr z,	_activateLogSeg_end					; Mode 0 (TEMPMEM): no load
	cp		#MNEMO_SEGMODE_FORCEDREAD
	jr z,	_activateLogSeg_load				; Mode 2 (FORCEREAD): load 
	ld		a, (#logSegLoaded)					; Mode 1 (READ) or 3 (READWRITE)
	or		a									;	If segment in memory,
	jr nz,	_activateLogSeg_end					;	no load.

_activateLogSeg_load:
	; check if custom load routine
	ld		a, b
	and		#MNEMO_SEGMODE_CUSTOMREAD
	jr z,	_activateLogSeg_standardLoad
	
	; custom load
	ld		hl, #_activateLogSeg_end
	push	hl						; return point
	ld		hl, (#pLoadSeg)
	ld		e, (hl)
	inc		hl
	ld		d, (hl)					; de = custom load routine
;	ld		hl, #MNEMO_MAIN_SWAP_PAGE_ADDR
;	push	de						; prepare call
	ret								; call de (THIS IS NOT A REAL RET!)

_activateLogSeg_standardLoad:
;	ld		hl, #MNEMO_MAIN_SWAP_PAGE_ADDR
	call	_standardLoad

_activateLogSeg_end:
	ld		hl, #auxSegHandlerTemp
	call	_switchAuxPage

	; update logSegHandler from page 3
	ld		hl, #logSegHandler
	ld		de, (pLogSegHandler)
	ld		bc, #(logSegHandler_params - logSegHandler)
	ldir

	pop		ix
	ret

_activateLogSeg_segOutOfRangeError:
	ld		a, #MNEMO_ERROR_SEGOUTOFRANGE
	jr		_activateLogSeg_end

_activateLogSeg_noFreePhysSegError:
	ld		a, #MNEMO_ERROR_NOFREEPHYSSEG
	jr		_activateLogSeg_end

; ----------------------------------------------------------------
;	- Enable a segment from a Segment Handler in aux page
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
_switchAuxPage::
	ld		a, (hl)			; segNumber
	__PutSegAux

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	ret nz
	inc		hl
	ld		a, (hl)			; slotid
	ld		h, #MNEMO_AUX_SWAP_PAGE << 6	; Page
	jp		BIOS_ENASLT		; select slot
.else
	ret
.endif

; ----------------------------------------------------------------
;	- Enable a segment from a Segment Handler in main page
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
_switchMainPage::
	ld		a, (hl)			; segNumber
	__PutSegMain

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	ret nz
	inc		hl
	ld		a, (hl)			; slotid
	ld		h, #MNEMO_MAIN_SWAP_PAGE << 6	; Page
	jp		BIOS_ENASLT		; select slot
.else
	ret
.endif

; ----------------------------------------------------------------
;	- Save AUX and MAIN pages configurations
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pBuffer (4 bytes)
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - All secondary registers; HL+=3
; ----------------------------------------------------------------
_savePageConfig::
	call	_saveAuxPageConfig
	inc		hl
	jr		_saveMainPageConfig

; ----------------------------------------------------------------
;	- Save Aux Page configuration
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pSegHandler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - All secondary registers; HL+=1
; ----------------------------------------------------------------
_saveAuxPageConfig::
	exx
 	__GetSegAux
	exx
 	ld		(hl), a
 
	exx
 	__GetSlotAux
	exx
	inc		hl
 	ld		(hl), a
 
	ret

; ----------------------------------------------------------------
;	- Save Main Page configuration
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pSegHandler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - All secondary registers; HL+=1
; ----------------------------------------------------------------
_saveMainPageConfig::
	exx
	__GetSegMain
	exx
	ld		(hl), a

	exx
	__GetSlotMain
	exx
	inc		hl
	ld		(hl), a
 
 	ret


; ----------------------------------------------------------------
;	- Restore AUX and MAIN pages configurations
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pBuffer (4 bytes; 2 x segHandler)
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_restorePageConfig::
	push	hl
	call	_switchAuxPage
	pop		hl
	inc		hl
	inc		hl
	jp		_switchMainPage
 

; ----------------------------------------------------------------
;	- Get slot ID of any page
; ----------------------------------------------------------------
; INPUTS:
;	- h: memory address high byte (bits 6-7: page)
;
; OUTPUTS:
;   - a: slot ID formatted F000SSPP
;
; CHANGES:
;   - f, bc, de
; ----------------------------------------------------------------
_getSlot::
;	call	BIOS_RSLREG
	in		a, (#0xa8)
	bit		7, h
	jr z,	_getSlot_primaryShiftContinue
	rrca
	rrca
	rrca
	rrca

_getSlot_primaryShiftContinue:
	bit		6, h
	jr z,	_getSlot_primaryShiftDone
	rrca
	rrca

_getSlot_primaryShiftDone:
	and		#0b00000011
	ld		c, a
	ld		b, #0
	ex		de, hl
	ld		hl, #BIOS_EXPTBL
	add		hl, bc
	ex		de, hl
	ld		a, (de)
	and		#0x80
	or		c
	ret p

	ld		c, a
	inc		de  ; move to SLTTBL
	inc		de
	inc		de
	inc		de
	ld		a, (de)
	bit		7, h
	jr z,	_getSlot_secondaryShiftContinue
	rrca
	rrca
	rrca
	rrca

_getSlot_secondaryShiftContinue:
	bit		6, h
	jr nz,	_getSlot_secondaryShiftDone
	rlca
	rlca

_getSlot_secondaryShiftDone:
	and		#0x00001100
	or		c
	ret

; ----------------------------------------------------------------
;	- Strings
; ----------------------------------------------------------------
initializingMnemosynex::		.asciz "** MnemoSyne-X Virtual Memory **\n\r"
mnemosynexVirtualMemSize::		.asciz "Virtual Memory Size is "
initializingMapperMsg::			.asciz "Initializing mapper service..."
allocatingIndexSegmentsMsg::	.asciz "Allocating index segments... "
allocatingSegmentsMsg::			.asciz "Allocating segments...\n\r=> "
segmentsAllocatedMsg::			.asciz " segments allocated.\n\r"
memoryManaged1Msg::				.asciz "Managing "
memoryManaged2Msg::				.asciz "Kbytes of physical memory.\n\r"
megaBytesMsg::					.asciz "Mbytes.\n\r"

okMsg::							.asciz " [OK]\n\r"

;   ==================================
;   ========== DATA SEGMENT ==========
;   ==================================
	.area	_DATA

pLogSegHandler:				.ds 2

logSegHandler:
segHandler:
segNumber:					.ds 1
mapperSlot:					.ds 1
pSegHandler:				.ds 2
pLogSegTableItem:			.ds 2		; TODO: Check if this can be dropped from the handler
logSegHandler_params:
logSegNumber:				.ds 2
logSegMode:					.ds 1
pLoadSeg:					.ds	2
pSaveSeg:					.ds 2
logSegHandler_end:

_pMapperBaseTable::			.ds 2
_primaryMapperSlot::		.ds 1
_numberPhysicalSegs::		.ds 2

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
bufferSegment::				.ds 2
segTableSegment::			.ds 2
segIndexTable::				.ds MNEMO_INDEX_SEGMENTS * 2
.else
segTableSegment::			.ds 1
segIndexTable::				.ds MNEMO_INDEX_SEGMENTS
.endif

afterSegTable::				.ds 2

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
usePrimaryMapperOnly::		.ds 1
mapperQueryTag::			.ds 2
.endif

segIndexSegment:			.ds 1
pSegIndex:					.ds 2
pLogSegTableSegment:		.ds 2
logSegLoaded:				.ds 1

pageConfigTempBuffer::
	auxSegHandlerTemp::		.ds 2
	mainSegHandlerTemp::	.ds 2
pageConfigGlobalBuffer::
	auxSegHandlerGlobal::	.ds 2
	mainSegHandlerGlobal::	.ds 2

mainPageAddr::				.ds	2	; TODO: Decide whether this is going to be used
auxPageAddr::				.ds	2	; TODO: Decide whether this is going to be used
