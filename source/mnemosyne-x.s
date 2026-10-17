; ----------------------------------------------------------------
;	mnemosyne-x.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
; ----------------------------------------------------------------

.include "mnemosyne-x_internal_h.s"
.include "mnemosyne-x_stdpersist_h.s"

.macro __MNEMOPRINT a
.ifeq (MNEMO_VERBOSE_MODE - 1)
	print	a
.endif
.endm

.macro __MNEMOPRINTDEC
.ifeq (MNEMO_VERBOSE_MODE - 1)
	call	_PrintDec
.endif
.endm

;   ==================================
;   ========== CODE SEGMENT ==========
;   ==================================
	.area _CODE

; ----------------------------------------------------------------
; ----------------------- SERVICES -------------------------------
; ----------------------------------------------------------------

; ----------------------------------------------------------------
;	- Get slot ID of a page (public entry)
; ----------------------------------------------------------------
; INPUTS:
;	- a: page (0-3)
;
; OUTPUTS:
;   - a: slot ID formatted F000SSPP
;
; CHANGES:
;   - f, bc, de, h
; ----------------------------------------------------------------
_mnemo_getSlot::
	rrca
	rrca
	ld		h, a

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
mnemo_getSlot:
	in		a, (#0xa8)
	bit		7, h
	jr z,	mnemo_getSlot_primaryShiftContinue
	rrca
	rrca
	rrca
	rrca

mnemo_getSlot_primaryShiftContinue:
	bit		6, h
	jr z,	mnemo_getSlot_primaryShiftDone
	rrca
	rrca

mnemo_getSlot_primaryShiftDone:
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
	jr z,	mnemo_getSlot_secondaryShiftContinue
	rrca
	rrca
	rrca
	rrca

mnemo_getSlot_secondaryShiftContinue:
	bit		6, h
	jr nz,	mnemo_getSlot_secondaryShiftDone
	rlca
	rlca

mnemo_getSlot_secondaryShiftDone:
	and		#0b00001100
	or		c
	ret


; ----------------------------------------------------------------
;	- Get the physical segment mapped in the aux page
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: SEGHANDLER of the current AUX page mapping
;		  (E: segment number, D: slot ID formatted F000SSPP),
;
; CHANGES:
;   - AF, BC, DE, H
; ----------------------------------------------------------------
_mnemo_getAuxPage::
	__GetSlotAux
	ld		d, a
	__GetSegAux
	ld		e, a
	ret

; ----------------------------------------------------------------
;	- Get the physical segment mapped in the main page
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: SEGHANDLER of the current MAIN page mapping
;		  (E: segment number, D: slot ID formatted F000SSPP),
;
; CHANGES:
;   - AF, BC, DE, H
; ----------------------------------------------------------------
_mnemo_getMainPage::
	__GetSlotMain
	ld		d, a
	__GetSegMain
	ld		e, a
	ret


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
mnemo_savePageLayout:
	call	mnemo_saveAuxPageConfig
	inc		hl
	jr		mnemo_saveMainPageConfig

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
mnemo_saveAuxPageConfig:
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
mnemo_saveMainPageConfig:
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
mnemo_restorePageLayout:
	push	hl
	call	_mnemo_switchAuxPage
	pop		hl
	inc		hl
	inc		hl
	jp		_mnemo_switchMainPage
	
	
; ----------------------------------------------------------------
;	- Common allocation initial services
; ----------------------------------------------------------------
; INPUTS:
;	- A:  logSegLoaded or release priority
;	- HL: pLogSegHandler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
mnemo_allocationInitialServices:
	ld		(#pLogSegHandler), hl

	; copy logSegHandler to page 3
	ld		de, #logSegHandler
	ld		bc, #(logSegHandler_end - logSegHandler)
;	ld		hl, (#pLogSegHandler)
	ldir

mnemo_allocationInitialServices2:
	ld		(#logSegLoaded), a

mnemo_allocationInitialServices3:
	ld		hl, #auxSegHandlerTemp
	jp		mnemo_saveAuxPageConfig


; ----------------------------------------------------------------
;	- Common save
; ----------------------------------------------------------------
; INPUTS:
;	- A:  0 = Dont check bank
;		  >0 = Only save if correct bank is active
;	- HL: pSegHandler
;
; OUTPUTS:
;   - A: return code
;	- if A = 0:
;		- 
;		- pSegHandler->mapperSlot marked as flushed
;
; CHANGES:
;   - All regs, segment selected in Main Page
; ----------------------------------------------------------------
mnemo_commonSave:
	ld		(#pSegHandler), hl
	ld		(#checkBank), a

	; store mapperslot
	inc		hl
	ld		a, (hl)
	ld		(#mapperSlot), a

	; check if segment is still in use
	and		#MNEMO_ALLOC_MASK
	cp		#MNEMO_ALLOC_INUSE
	ld		a, #MNEMO_ERROR_SEGINUSE
	ret z

	; activate main segment
	dec		hl
	call	_mnemo_switchMainPage

	; check if segment is already flushed
	ld		a, (#mapperSlot)
	bit		MNEMO_FLUSH_BIT, a
	ld		a, #MNEMO_WARN_ALREADYFLUSHED
	ret nz

	; check whether logSegNumber is valid
	ld		hl, (#MNEMO_SEGHDR_LOGSEGNUMBER)
	ld		de, #0xffff
	or		a
	sbc		hl, de
	ld		a, #MNEMO_WARN_INVALIDSEG
	ret z

	; check whether segment is 'writable'
	ld		a, (#MNEMO_SEGHDR_SEGMODE)
	ld		b, a
	and		#MNEMO_SEGMODE_MASK
	cp		#MNEMO_SEGMODE_READWRITE
	ld		a, #MNEMO_WARN_NOWRITABLESEG
	ret nz

	; check if custom write routine
	ld		a, (#checkBank)
	call	MNEMO_SEGHDR_SAVEHOOK

mnemo_commonSave_markFlushed:
	or		a
	ret nz
	
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage
	ld		hl, (#pSegHandler)
	inc		hl
	ld		a, (hl)
	or		#MNEMO_FLUSH
	ld		(hl), a
	xor		a
	ret


; ----------------------------------------------------------------
; ----------------------- ENGINE ---------------------------------
; ----------------------------------------------------------------

; ----------------------------------------------------------------
;	- Init MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- A: Use primary mappers only (if MNEMO_PRIMARY_MAPPER_ONLY = 0).
;			0 = All mappers
;			1 = Primary mapper only
;	- DE: pointer to a string with the databanks filename: up to 8
;			characters; a shorter name ends at its first space or zero
;
; OUTPUTS:
;   - A:  0 = Success
;		  MNEMO_ERROR_BADFILENAME = The databanks filename is empty (it
;			starts with a space or a zero)
;		  MNEMO_ERROR_NOINDEXSEG = Not enough free segments in the
;			primary mapper for the index segments
;		  MNEMO_ERROR_NOFREEPHYSSEG = No free segment left to manage
;			after the index segments
;		  Nothing is allocated when init fails.
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_mnemo_init::
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	push	af						; A (mappers to use): the name check changes A
.endif
	; copy filename (8 bytes at most are read)
	ld		hl, #fileName
	ex		de, hl
	ld		bc, #8
	ldir

	; the name ends at its first space or zero: fileNameLength = its characters
	ld		hl, #fileName
	ld		b, #8
_mnemo_init_nameLengthLoop:
	ld		a, (hl)
	or		a
	jr z,	_mnemo_init_nameLengthEnd
	cp		#' '
	jr z,	_mnemo_init_nameLengthEnd
	inc		hl
	djnz	_mnemo_init_nameLengthLoop
_mnemo_init_nameLengthEnd:
	ld		de, #fileName
	or		a
	sbc		hl, de
	ld		a, l
	ld		(#fileNameLength), a
	or		a
	jr nz,	_mnemo_init_nameOk
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	pop		af
.endif
	ld		a, #MNEMO_ERROR_BADFILENAME
	ret								; empty name: nothing was done yet

_mnemo_init_nameOk:
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	pop		af
	ld		(#usePrimaryMapperOnly), a
.endif
	push	ix
	ld hl,	#0
	ld		(#_nPhysicalSegsInUse), hl
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	dec		hl
	ld		(#auxPageSlot), hl	; auxPageSlot, mainPageSlot = unknown
.endif

	__MNEMOPRINT	initializingMnemosynexMsg

	; init mapper mgr
	__MNEMOPRINT	initializingMapperMsg
	ld		a, #MNEMO_MAPPER_DEVICE_ID
	call	_InitRamMapperInfo

	; get mapperBaseTable address
	call	_GetRamMapperBaseTable
	ex		de, hl
	ld		(#_pMapperBaseTable), hl
	ld		a, (hl)
	ld		(#primaryMapperSlot), a

	; save page layout
	ld		hl, #pageConfigGlobalBuffer
	call	mnemo_savePageLayout

	; set mapper query tag
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	dec		a						; a = 0 => primary mapper only
	jr z,	_mnemo_init_setQueryTag
	ld		a, #0b00100000			; Try to specified slot and, if it failed, try another slot (if any)
_mnemo_init_setQueryTag:
	or		(hl)					; primary mapper slot
	ld		(#mapperQueryTag), a
.endif

	__MNEMOPRINT	okMsg

	; check the free segments BEFORE allocating any: the index segments
	; always come from the primary mapper (first entry of the mapper
	; table: slot, segments, free segments, ...) and at least one physical
	; segment must remain
	ld		hl, (#_pMapperBaseTable)
	inc		hl
	inc		hl
	ld		a, (hl)					; free segments of the primary mapper
	cp		#MNEMO_INTERNAL_SEGMENTS
	ld		a, #MNEMO_ERROR_NOINDEXSEG
	jp c,	_mnemo_init_end

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	jr nz,	_mnemo_init_checkPhysSeg

	; all mappers: sum the free segments of every entry of the table
	; (the table ends with a zero slot)
	ld		hl, (#_pMapperBaseTable)
	ld		de, #0
_mnemo_init_sumFreeSegsLoop:
	ld		a, (hl)
	or		a
	jr z,	_mnemo_init_sumFreeSegsEnd
	inc		hl
	inc		hl
	ld		a, e
	add		a, (hl)					; free segments of this mapper
	ld		e, a
	ld		a, d
	adc		a, #0
	ld		d, a
	ld		bc, #6					; next entry (8 bytes)
	add		hl, bc
	jr		_mnemo_init_sumFreeSegsLoop

_mnemo_init_sumFreeSegsEnd:
	ld		a, e
	sub		#(MNEMO_INTERNAL_SEGMENTS + 1)
	ld		a, d
	sbc		a, #0
	jr		_mnemo_init_checkPhysSegResult

_mnemo_init_checkPhysSeg:
.endif
	; primary mapper only: its free segments must also hold a physical segment
	ld		hl, (#_pMapperBaseTable)
	inc		hl
	inc		hl
	ld		a, (hl)
	cp		#(MNEMO_INTERNAL_SEGMENTS + 1)

_mnemo_init_checkPhysSegResult:
	ld		a, #MNEMO_ERROR_NOFREEPHYSSEG
	jp c,	_mnemo_init_end

	; allocate index segments
	__MNEMOPRINT	allocatingIndexSegmentsMsg
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		hl, #bufferSegment
.else
	ld		hl, #segTableSegment
.endif
	ld		b, #MNEMO_INTERNAL_SEGMENTS

_mnemo_init_indexSegAllocLoop:
	exx
	xor		a						; user segment
	ld		l, a					; primary mapper only
	call	_AllocateSegment		; alternate regs are preserved
	ld		a, #MNEMO_ERROR_NOINDEXSEG
	jp c,	_mnemo_init_end		; No more available segments
	
	; save segHandler
	ld		a, e
	exx
	ld		(hl), a
	inc		hl

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#primaryMapperSlot)
	ld		(hl), a
	inc		hl
.endif

	djnz	_mnemo_init_indexSegAllocLoop

	__MNEMOPRINT	okMsg

	; allocate all available segments
	; Note: allocate all other segments needed
	; by the application BEFORE calling _mnemo_init!
	__MNEMOPRINT	allocatingSegmentsMsg

	; Set Segment Table segment in Aux Page
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage

_mnemo_init_initBankPersistTable:
	ld		hl, #_standardLoad
	ld		(#MNEMO_BANK_PERSISTENCE_TABLE), hl
	ld		hl, #_standardSave
	ld		(#MNEMO_BANK_PERSISTENCE_TABLE+2), hl
	ld		hl, #MNEMO_BANK_PERSISTENCE_TABLE
	ld		de, #MNEMO_BANK_PERSISTENCE_TABLE + 4
	ld		bc, #(MNEMO_NUM_BANKS * 4) - 4
	ldir

	; segments allocation loop
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR
	ld		(#afterSegTable), hl
_mnemo_init_segAllocLoop:
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#mapperQueryTag)
.else
	ld		a, (#primaryMapperSlot)	; primary mapper slot only: DOS2 returns its slot ID
.endif
	ld		l, a					; which mappers
	xor		a						; user segment
	call	_AllocateSegment
	ld		hl, (#afterSegTable)
	jr c,	_mnemo_init_cont	; No more available segments

	; save entry in segmentTable
	ld		(hl), e
	inc		hl
	ld		(hl), d

	; mark segment header with logSegNumber = 0xffff (invalid)
	dec		hl						; hl = pSegHandler
	call	_mnemo_switchMainPage
	ld		hl, #0xffff				; invalid logSegNumber
	ld		(#MNEMO_MAIN_SWAP_PAGE_ADDR), hl	; mark

	; set hooks jp in segment header
	ld		a, #0xc3				; jp
	ld		(#MNEMO_SEGHDR_LOADHOOK), a
	ld		(#MNEMO_SEGHDR_SAVEHOOK), a

.ifeq (MNEMO_VERBOSE_MODE - 1)
_mnemo_init_printDash:
	ld		a, #'-'
	call	printchar
.endif

_mnemo_init_inPhysSegCounter:
	ld		hl, (#afterSegTable)
	inc		hl						; next table entry
	inc		hl
	ld		(#afterSegTable), hl
	ld		de, #MNEMO_MAX_PSEGHANDLE
	or		a
	sbc		hl, de
	add		hl, de
	jr c, 	_mnemo_init_segAllocLoop

_mnemo_init_cont:
	or		a
	ld		de, #MNEMO_AUX_SWAP_PAGE_ADDR
	sbc		hl, de
	srl		h
	rr		l						; hl = #segments
	ld		(#_nPhysicalSegs), hl

.ifeq (MNEMO_VERBOSE_MODE - 1)
	push	hl
	__MNEMOPRINT	okMsg	
	pop		hl

	push	hl
	__MNEMOPRINTDEC
	__MNEMOPRINT	segmentsAllocatedMsg
	__MNEMOPRINT	memoryManaged1Msg
	pop		hl
.endif

	add		hl, hl
	add		hl, hl
	add		hl, hl
	add		hl, hl
	ld		(#_managedMemorySize), hl
	__MNEMOPRINTDEC
	__MNEMOPRINT	memoryManaged2Msg

	__MNEMOPRINT	mnemosynexVirtualMemSizeMsg
	ld		hl, #MNEMO_MAX_LOGICAL_MEMORY
	__MNEMOPRINTDEC
	__MNEMOPRINT	megaBytesMsg

	xor		a			; success (A = 0)
_mnemo_init_end::
	ld		hl, #pageConfigGlobalBuffer
	push	af
	call	mnemo_restorePageLayout
	pop		af
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
_mnemo_finalize::
	__MNEMOPRINT	finalizingMnemosynexMsg

	; release and flush all segments
	__MNEMOPRINT	releasingAllSegmentsMsg
	ld		a, #MNEMO_ALLOC_KEEPPRIORITY0
	call	_mnemo_releaseAll
	__MNEMOPRINT	okMsg

	__MNEMOPRINT	flushingAllSegmentsMsg
	call	_mnemo_flushAll
	__MNEMOPRINT	okMsg

	; close the standard persistence's Databank file
	call	_standardClose

	push	ix

	; free the physical segments (Segment Table in aux page)
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR

_mnemo_finalize_freePhysSegLoop:
	ld		de, (#afterSegTable)
	or		a
	sbc		hl, de
	add		hl, de
	jr nc,	_mnemo_finalize_freeIndexSegs
	ld		a, (hl)					; segment number
	inc		hl
	ld		e, (hl)					; slot (allocation bits masked by _FreeSegment)
	inc		hl
	push	hl
	ld		l, e
	call	_FreeSegment
	pop		hl
	jr		_mnemo_finalize_freePhysSegLoop

	; free the index segments (and the Segment Table segment,
	; still mapped in aux page until the page layout is restored)
_mnemo_finalize_freeIndexSegs:
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		hl, #bufferSegment
.else
	ld		hl, #segTableSegment
.endif
	ld		b, #MNEMO_INTERNAL_SEGMENTS

_mnemo_finalize_freeIndexSegLoop:
	ld		a, (hl)					; segment number
	inc		hl
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		e, (hl)					; slot
	inc		hl
.else
	ld		e, #0					; primary mapper
.endif
	push	hl
	push	bc
	ld		l, e
	call	_FreeSegment
	pop		bc
	pop		hl
	djnz	_mnemo_finalize_freeIndexSegLoop

	ld		hl, #pageConfigGlobalBuffer
	call	mnemo_restorePageLayout
	pop		ix

	__MNEMOPRINT	mnemosynexShutDownMsg
	ret


; ----------------------------------------------------------------
;	- Set a bank to standard persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number
;
; OUTPUTS:
;	- A:  0 = Success
;		  MNEMO_ERROR_BADBANK = The bank number is out of range (see
;			_mnemo_setPersistence)
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
_mnemo_setStdPersistence::
	; pSaveSeg goes under the return address, as the caller of
	; _mnemo_setPersistence pushes it
	pop		hl						; return address
	ld		de, #_standardSave
	push	de						; pSaveSeg
	push	hl
	ld		de, #_standardLoad		; pLoadSeg
	; falls through to _mnemo_setPersistence (A = bank)


; ----------------------------------------------------------------
;	- Set bank persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number (0 to MNEMO_INDEX_SEGMENTS * 32 - 1)
;	- DE: pLoadSeg
;   - Stack: pSaveSeg
;
; OUTPUTS:
;	- A:  0 = Success
;		  MNEMO_ERROR_BADBANK = The bank number is out of range; nothing
;			was changed (pSaveSeg is removed from the stack anyway)
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
_mnemo_setPersistence::
.ifne	(MNEMO_INDEX_SEGMENTS - 8)
	; with 8 index segments every bank number (0-255) is valid
	cp		#MNEMO_NUM_BANKS
	jr c,	_mnemo_setPersistence_bankOk
	pop		hl						; return address
	pop		de						; pSaveSeg: clean stack as per sdcccall 1
	push	hl
	ld		a, #MNEMO_ERROR_BADBANK
	ret
_mnemo_setPersistence_bankOk:
.endif
	; Set Segment Table segment in Aux Page
	push	de
	push	af
	ld		hl, #auxSegHandlerTemp
	call	mnemo_saveAuxPageConfig
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage

	; find	Persistence entry address
	pop		af
	ld		l, a
	ld		h, #0
	add		hl, hl
	add		hl, hl
	ld		de, #MNEMO_BANK_PERSISTENCE_TABLE
	add		hl, de

	pop		de			; pLoadSeg
	ld		(hl), e
	inc		hl
	ld		(hl), d
	inc		hl
	pop		bc			; return addr
	pop		de			; pSaveSeg - clean stack as per sdcccall 1
	push	bc			; return addr
	ld		(hl), e
	inc		hl
	ld		(hl), d

	; restore Aux Page
	ld		hl, #auxSegHandlerTemp
	call	_mnemo_switchAuxPage
	xor		a
	ret
	
	
; ----------------------------------------------------------------
;	- Activates a logical segment
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to logical segment handler
;
; OUTPUTS:
;   - A:  0 = Success: the logical segment is active, mapped in MAIN,
;			and the handler is updated
;		  MNEMO_ERROR_SEGOUTOFRANGE, MNEMO_ERROR_NOFREEPHYSSEG,
;		  MNEMO_ERROR_SEGALREADYACTIVE (the logical segment is already
;		  active), or an error of the segment save or load: nothing is
;		  activated, the handler is not changed and MAIN is undefined
;		  A < 0x80, A <> 0: warning, the segment is active
;
; CHANGES:
;   - All registers but IX; AUX is restored. Interrupts may be disabled
; ----------------------------------------------------------------
_mnemo_activateLogSeg::
	push	ix
	xor		a

	call	mnemo_allocationInitialServices

.ifeq	(MNEMO_INDEX_SEGMENTS - 8)
	; 0xFFFF (invalid logSegNumber) is inside the range of 8 index segments
	ld		hl, (#logSegNumber)
	inc		hl
	ld		a, h
	or		l
	jp z,	_mnemo_activateLogSeg_segOutOfRangeError
.endif

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
	jp nc,	_mnemo_activateLogSeg_segOutOfRangeError

	; activate proper logSegTableSegment
	ld		hl, #logSegIndexTable
;.ifne MNEMO_INDEX_SEGMENTS - 1				; TODO: uncomment this
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	add		a, a			; unit is segHandler, but in primary mapper only the slot is not used
.endif
	add		a, l			;TODO: ld e, a + ld d, #0 + add hl, de
	ld		l, a
	adc		a, h
	sub		l   
	ld		h, a			; hl = pLogSegTableSegment
;.endif
	ld		(#pLogSegTableSegment), hl
	call	_mnemo_switchAuxPage

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
	jr nz,	_mnemo_activateLogSeg_activateSegTableForSearch		; not valid

	; 2. Verify whether pSegHandler >= SegTable start
	xor		a				; clear carry flag (TODO: CHECK if necessary!)
	ld		de, #MNEMO_AUX_SWAP_PAGE_ADDR
	sbc		hl, de
	add		hl, de			
	jr c,	_mnemo_activateLogSeg_activateSegTableForSearch		; not valid

	; 3. Verify whether pSegHandler <= SegTable end
	xor		a				; clear carry flag  (TODO: CHECK if necessary!)
	ex		de, hl
	ld		hl, (#afterSegTable)
	ex		de, hl
	sbc		hl, de
	add		hl, de			
	jr nc,	_mnemo_activateLogSeg_activateSegTableForSearch		; not valid

	; activate segTableSegment
	push	hl
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage

	; activate target segment
	pop		hl
	call	_mnemo_switchMainPage

	; check if target segment contains correct logSegNumber
	; (equal to logSegHandler.logSegNumber)
	xor		a
	ld		hl, (#logSegNumber)
	ex		de, hl
	ld		hl, (#MNEMO_SEGHDR_LOGSEGNUMBER)
	sbc		hl, de
	jr nz,	_mnemo_activateLogSeg_searchFreeSeg		; nope

	; logSeg already in memory: it cannot be activated twice
	ld		hl, (#pSegHandler)
	inc		hl
	ld		a, (hl)
	and		#MNEMO_ALLOC_MASK
	cp		#MNEMO_ALLOC_INUSE
	ld		a, #MNEMO_ERROR_SEGALREADYACTIVE
	jp z,	_mnemo_activateLogSeg_restoreAuxSeg		; nothing was changed

	; logSeg already loaded
	ld		a, #1
	ld		(#logSegLoaded), a
	jp		_mnemo_activateLogSeg_updateSegmentMode

_mnemo_activateLogSeg_activateSegTableForSearch:
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage

_mnemo_activateLogSeg_searchFreeSeg:
	; define random starting point for free segment search
	call	_rnd16
	ld		a, (#_nPhysicalSegs)
	ld		c, a
	exx
	ld		c, a
	ld		a, (#_nPhysicalSegs + 1)
	ld		b, a
	exx
	ld		b, a
	or		a						; reset carry flag

_mnemo_activateLogSeg_rndLoop:
	; makes random point within Segment Table
	srl		d
	rr		e
	or		a						; reset carry flag
	sla		c
	rl		b
	jr nc,	_mnemo_activateLogSeg_rndLoop
	sla		e
	rl		d						; de = pSegHandler (search starting pointer) - MNEMO_AUX_SWAP_PAGE_ADDR
	inc		de						; de = p(SegHandler.mapperSlot) - MNEMO_AUX_SWAP_PAGE_ADDR

	; search free segment
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR
	add		hl, de					; hl = p(SegHandler.mapperSlot)
	ld		de, #0xffff				; invalid pSegHandler
	ld		c, #MNEMO_ALLOC_INUSE	; best status

_mnemo_activateLogSeg_searchLoop:
	ld		a, (hl)
	and		#MNEMO_ALLOC_MASK		; seg status
	cp		c
	jr nc,	_mnemo_activateLogSeg_searchLoop_cont1

	; found a better candidate
	ld		c, a
	ld		d, h
	ld		e, l
	or		a						; TODO: Is this needed?!?!?!?!
	jr z,	_mnemo_activateLogSeg_activateSegment		; priority 0, position chosen

_mnemo_activateLogSeg_searchLoop_cont1:
	dec		hl
	ld		a, h
	sub		#>MNEMO_AUX_SWAP_PAGE_ADDR
	or		l
	jr nz,	_mnemo_activateLogSeg_searchLoop_cont2
	ld		hl, (#afterSegTable)

_mnemo_activateLogSeg_searchLoop_cont2:
	dec		hl	
	exx
	dec		bc
	ld		a, b
	or		c					; all table positions were checked?
	exx
	jr nz,	_mnemo_activateLogSeg_searchLoop	; not yet, continue search

	; end of segTable
	ld		a, c
	cp		#MNEMO_ALLOC_INUSE
	jp z,	_mnemo_activateLogSeg_noFreePhysSegError

_mnemo_activateLogSeg_activateSegment:
	; update logSegHandler with segHandler
	; de = p(SegHandler.mapperSlot)
	dec		de					; de = pSegHandler
	ex		de, hl				; hl = pSegHandler

	; save
	xor		a					; dont check bank
	call	mnemo_commonSave	; activate main seg and save if needed
	bit		MNEMO_ERROR_BIT, a
	jp nz,	_mnemo_activateLogSeg_restoreAuxSeg

_mnemo_activateLogSeg_updateSegmentHeader:
	ld		hl, (#logSegNumber)
	ld		(#MNEMO_SEGHDR_LOGSEGNUMBER), hl

_mnemo_activateLogSeg_updateSegmentMode:
	ld		a, (#logSegMode)
	ld		(#MNEMO_SEGHDR_SEGMODE), a

_mnemo_activateLogSeg_updateSegTable:
	ld		hl, (#pSegHandler)
	ld		a, (hl)
	ld		(#segNumber), a
	inc		hl
	ld		a, (hl)
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	or		#MNEMO_ALLOC_INUSE		; In use
	ld		(hl), a
	ld		(#mapperSlot), a

_mnemo_activateLogSeg_updatePersistence:
	exx									; backup
	ld		a, (#MNEMO_SEGHDR_LOGSEGNUMBER + 1)
	ld		l, a
	ld		h, #0
	add		hl, hl
	add		hl, hl
	ld		de, #MNEMO_BANK_PERSISTENCE_TABLE
	add		hl, de
	ld		de, #MNEMO_SEGHDR_PLOADSEG
	ld		bc, #2
	ldir
	inc		de
	ld		c, #2
	ldir

_mnemo_activateLogSeg_updateUsedSegs:
	ld		hl, (#_nPhysicalSegsInUse)
	inc		hl
	ld		(#_nPhysicalSegsInUse), hl
	
_mnemo_activateLogSeg_updateLogSegTable:
	ld		hl, (#pLogSegTableSegment)
	call	_mnemo_switchAuxPage
	exx									; restore
	dec		hl
	ex		de, hl
	ld		hl, (#pLogSegTableItem)
	ld		(hl), e
	inc		hl
	ld		(hl), d

_mnemo_activateLogSeg_checkReadMode:
	ld		a, (#logSegMode)
	and		#3
	jr z,	_mnemo_activateLogSeg_restoreAuxSeg		; Mode 0 (TEMPMEM): no load
	cp		#MNEMO_SEGMODE_FORCEDREAD
	jr z,	_mnemo_activateLogSeg_load				; Mode 2 (FORCEREAD): load 
	ld		a, (#logSegLoaded)					; Mode 1 (READ) or 3 (READWRITE)
	or		a									;	If segment in memory,
	ld		a, #0
	jr nz,	_mnemo_activateLogSeg_restoreAuxSeg		;	no load.

_mnemo_activateLogSeg_load:
	call	MNEMO_SEGHDR_LOADHOOK
	bit		MNEMO_ERROR_BIT, a
	jr z,	_mnemo_activateLogSeg_restoreAuxSeg

	; the load failed: undo the activation (the segment becomes free,
	; with an invalid logSegNumber, and the logical segment is unmapped)
	push	af
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage
	ld		hl, (#pSegHandler)
	push	hl
	call	_mnemo_switchMainPage
	ld		hl, #0xffff
	ld		(#MNEMO_SEGHDR_LOGSEGNUMBER), hl
	pop		hl
	inc		hl
	ld		a, (hl)
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	or		#MNEMO_ALLOC_KEEPPRIORITY0
	ld		(hl), a
	ld		hl, (#_nPhysicalSegsInUse)
	dec		hl
	ld		(#_nPhysicalSegsInUse), hl
	ld		hl, (#pLogSegTableSegment)
	call	_mnemo_switchAuxPage
	ld		hl, (#pLogSegTableItem)
	ld		a, #0xff
	ld		(hl), a
	inc		hl
	ld		(hl), a
	pop		af

_mnemo_activateLogSeg_restoreAuxSeg:
	push	af
	ld		hl, #auxSegHandlerTemp
	call	_mnemo_switchAuxPage
	pop		af
	bit		MNEMO_ERROR_BIT, a
	jr nz,	_mnemo_activateLogSeg_end

_mnemo_activateLogSeg_updateLogSegHandler:
	; update logSegHandler from page 3
	ld		hl, #logSegHandler
	ld		de, (pLogSegHandler)
	ld		bc, #(logSegHandler_params - logSegHandler)
	ldir

_mnemo_activateLogSeg_end:
	pop		ix
	ret

_mnemo_activateLogSeg_segOutOfRangeError:
	ld		a, #MNEMO_ERROR_SEGOUTOFRANGE
	jr		_mnemo_activateLogSeg_end

_mnemo_activateLogSeg_noFreePhysSegError:
	ld		a, #MNEMO_ERROR_NOFREEPHYSSEG
	jr		_mnemo_activateLogSeg_restoreAuxSeg	; the search mapped the segment table in aux page


; ----------------------------------------------------------------
;	- Releases segment from a logSegHandler pointed by DE (SDCCCALL(1))
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- DE: pLogSegHandler
;
; OUTPUTS:
;   - A: Error code
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_mnemo_releaseLogSeg::
	ex		de, hl

; ----------------------------------------------------------------
;	- Releases segment from a logSegHandler pointed by HL
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- HL: pointer to logical segment handler
;
; OUTPUTS:
;   - A: Error code
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
mnemo_releaseLogSegHL::
	push	ix

	; assure priority <= 2
	ld		b, a
	and		#MNEMO_ALLOC_MASK
	cp		#MNEMO_ALLOC_INUSE
	ld		a, b
	jr nz,	mnemo_releaseLogSegHL_cont
	sub		#MNEMO_ALLOC_KEEPPRIORITY1		; priority from 3 to 2

mnemo_releaseLogSegHL_cont:
	call	mnemo_allocationInitialServices
	
	; assert segNumber
	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage
	ld		hl, (#pSegHandler)
	ld		a, (#segNumber)
	cp		(hl)
	jr nz,	mnemo_releaseLogSegHL_outdatedSegHandler
	inc		hl
	ld		a, (hl)
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	ld		e, a
	ld		a, (#mapperSlot)
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	cp		e
	jr nz,	mnemo_releaseLogSegHL_outdatedSegHandler

	; update release priority in temp structure
	exx
	ld		hl, #releasePriority
	or		(hl)
	exx
	ld		(hl), a
	ld		(#mapperSlot), a

	; update used segments
	ld		hl, (#_nPhysicalSegsInUse)
	dec		hl
	ld		(#_nPhysicalSegsInUse), hl
	
	; update release priority
	ld		hl, #auxSegHandlerTemp
	call	_mnemo_switchAuxPage
	ld		hl, (#pLogSegHandler)
	inc		hl
	ld		a, (#mapperSlot)
	ld		(hl), a
	xor		a
	pop		ix
	ret

mnemo_releaseLogSegHL_outdatedSegHandler:
	ld		a, #MNEMO_WARN_OUTDATEDPSEGHANDLER

mnemo_restoreAuxPageAndReturnStatus:				
	push	af
	ld		hl, #auxSegHandlerTemp
	call	_mnemo_switchAuxPage
	pop		af
	pop		ix
	ret

; ----------------------------------------------------------------
;	- Releases all active segments
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_mnemo_releaseAll::
	push	ix

	call	mnemo_allocationInitialServices2

	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR + 1
	ld		a, (#releasePriority)
	ld		b, a
	ld		de, (#afterSegTable)

_mnemo_releaseAll_loop:
	; check if active
	ld		a, (hl)
	ld		c, a
	and		#MNEMO_ALLOC_MASK
	cp		#MNEMO_ALLOC_INUSE
	jr nz,	_mnemo_releaseAll_next	; already released; do nothing
	
	; update release priority
	ld		a, c
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	or		b
	ld		(hl), a

	; update used segments
	exx
	ld		hl, (#_nPhysicalSegsInUse)
	dec		hl
	ld		(#_nPhysicalSegsInUse), hl
	exx

_mnemo_releaseAll_next:
	inc		hl
	inc		hl
	or		a						; reset carry
	sbc		hl, de
	add		hl, de
	jr c,	_mnemo_releaseAll_loop

	ld		hl, #auxSegHandlerTemp
	call	_mnemo_switchAuxPage
	pop		ix
	ret


; ----------------------------------------------------------------
;	- Flushes all pending, released segments to disk
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - A: Error code
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
_mnemo_flushAll::
	push	ix

	call	mnemo_allocationInitialServices3

	ld		hl, #segTableSegment
	call	_mnemo_switchAuxPage
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR

_mnemo_flushAll_loop:
	xor		a			; do not check bank
	push	hl
	call	mnemo_commonSave
	pop		hl
	cp		#MNEMO_ERROR_SEGINUSE
	jr z,	_mnemo_flush_next
	bit		MNEMO_ERROR_BIT, a
	jr nz,	mnemo_restoreAuxPageAndReturnStatus	; same ending

_mnemo_flush_next:
	inc		hl
	inc		hl
	or		a							; reset carry
	ld		de, (#afterSegTable)
	sbc		hl, de
	add		hl, de
	jr c,	_mnemo_flushAll_loop

	; Ensure last file buffers of the standard persistence are
	; written to disk (custom persistence has not Ensure ATM).
	call	_standardEnsure
	jr		mnemo_restoreAuxPageAndReturnStatus		; same ending


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
;   - Interrupts disabled if a slot change was needed
; ----------------------------------------------------------------
_mnemo_switchAuxPage::
	ld		a, (hl)			; segNumber
	__PutSegAux

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	ret nz
	inc		hl
	ld		a, (hl)			; slotid
	and		#MNEMO_SLOTID_MASK
	ld		hl, #auxPageSlot
	cp		(hl)
	ret z					; slot already selected
	ld		(hl), a
	ld		h, #MNEMO_AUX_SWAP_PAGE << 6	; Page
	jp		BIOS_ENASLT		; select slot (returns with di)
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
;   - Interrupts disabled if a slot change was needed
; ----------------------------------------------------------------
_mnemo_switchMainPage::
	ld		a, (hl)			; segNumber
	__PutSegMain

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	ret nz
	inc		hl
	ld		a, (hl)			; slotid
	and		#MNEMO_SLOTID_MASK
	ld		hl, #mainPageSlot
	cp		(hl)
	ret z					; slot already selected
	ld		(hl), a
	ld		h, #MNEMO_MAIN_SWAP_PAGE << 6	; Page
	jp		BIOS_ENASLT		; select slot (returns with di)
.else
	ret
.endif


; ----------------------------------------------------------------
;	- Get number of Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: number of Managed Physical Segments
;
; CHANGES:
;   - Nothing
; ----------------------------------------------------------------
_mnemo_getManagedSegments::
	__mnemo_getManagedSegments
	ret


; ----------------------------------------------------------------
;	- Get number of Used Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: number of Used Managed Physical Segments
;
; CHANGES:
;   - Nothing
; ----------------------------------------------------------------
_mnemo_getUsedSegments::
	__mnemo_getUsedSegments
	ret


; ----------------------------------------------------------------
;	- Get number of Free Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: Number of free segments
;
; CHANGES:
;   - HL
; ----------------------------------------------------------------
_mnemo_getFreeSegments::
	__mnemo_getManagedSegments
	ex		de, hl
	__mnemo_getUsedSegments
	or		a					; reset carry flag
	sbc		hl, de
	ex		de, hl
	ret


; ----------------------------------------------------------------
;	- Strings
; ----------------------------------------------------------------
.ifeq (MNEMO_VERBOSE_MODE - 1)
initializingMnemosynexMsg:		.asciz "** MnemoSyne-X Virtual Memory **\r\n"
mnemosynexVirtualMemSizeMsg:	.asciz "Virtual Memory Size is "
initializingMapperMsg:			.asciz "Initializing mapper service..."
allocatingIndexSegmentsMsg:		.asciz "Allocating index segments... "
allocatingSegmentsMsg:			.asciz "Allocating segments...\r\n=> "
segmentsAllocatedMsg:			.asciz " segments allocated.\r\n"
memoryManaged1Msg:				.asciz "Managing "
memoryManaged2Msg:				.asciz "Kbytes of physical memory.\r\n"
megaBytesMsg:					.asciz "Mbytes.\r\n"
finalizingMnemosynexMsg:		.asciz "** Shutting MnemoSyne-X down **\r\n"
releasingAllSegmentsMsg:		.asciz "Releasing all segments... "
flushingAllSegmentsMsg:			.asciz "Flushing all segments... "
mnemosynexShutDownMsg:			.asciz "MnemoSyne-X shut down.\r\n"

okMsg:							.asciz " [OK]\r\n"
.endif


;   ==================================
;   ========== DATA SEGMENT ==========
;   ==================================
	.area	_DATA

;
; buffer and indexes
;

fileName::					.ascii	'THETRIAL'
fileNameLength::			.ds 1
fileExtension::				.asciz	'.___'

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
bufferSegment::				.ds 2
segTableSegment::			.ds 2
logSegIndexTable::			.ds MNEMO_INDEX_SEGMENTS * 2
.else
segTableSegment::			.ds 1
logSegIndexTable::			.ds MNEMO_INDEX_SEGMENTS
.endif
afterSegTable::				.ds 2

;
; variables
;
_pMapperBaseTable::			.ds 2
_nPhysicalSegs::			.ds 2
_managedMemorySize::		.ds 2
_nPhysicalSegsInUse::		.ds 2
primaryMapperSlot::			.ds 1

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
usePrimaryMapperOnly::		.ds 1
mapperQueryTag::			.ds 2
auxPageSlot::				.ds 1	; slot selected in aux page by MnemoSyne-X
mainPageSlot::				.ds 1	; slot selected in main page by MnemoSyne-X
.endif

segIndexSegment::			.ds 1
pSegIndex::					.ds 2
pLogSegTableSegment::		.ds 2
releasePriority::
logSegLoaded::				.ds 1
checkBank::					.ds 1

pageConfigTempBuffer::
	auxSegHandlerTemp::		.ds 2
	mainSegHandlerTemp::	.ds 2
pageConfigGlobalBuffer::
	auxSegHandlerGlobal::	.ds 2
	mainSegHandlerGlobal::	.ds 2

;
; temporary logSegHandler
;
pLogSegHandler:				.ds 2
logSegHandler:
segHandler:
segNumber:					.ds 1
mapperSlot::				.ds 1
pSegHandler:				.ds 2
pLogSegTableItem:			.ds 2		; TODO: Check if this can be dropped from the handler
logSegHandler_params:
logSegNumber:				.ds 2
logSegMode:					.ds 1
logSegHandler_end:
