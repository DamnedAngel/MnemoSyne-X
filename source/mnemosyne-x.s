; ----------------------------------------------------------------
;	mnemosyne-x.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
; ----------------------------------------------------------------

.include "mnemosyne-x-internal_h.s"

;   ==================================
;   ========== CODE SEGMENT ==========
;   ==================================
	.area _CODE


; ----------------------------------------------------------------
; ----------------------- SERVICES -------------------------------
; ----------------------------------------------------------------

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
;	call	BIOS_RSLREG
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
	and		#0x00001100
	or		c
	ret


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
mnemo_allocationInitialServices::
	ld		(#pLogSegHandler), hl

	; copy logSegHandler to page 3
	ld		de, #logSegHandler
	ld		bc, #(logSegHandler_end - logSegHandler)
;	ld		hl, (#pLogSegHandler)
	ldir

mnemo_allocationInitialServices2::
	ld		(#logSegLoaded), a

mnemo_allocationInitialServices3::
	ld		hl, #auxSegHandlerTemp
	jp		_saveAuxPageConfig


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
mnemo_commonSave::
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
	call	_switchMainPage

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
	call	_switchAuxPage
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
	xor		a
	ld		(#_nPhysicalSegsInUse), a

	print	initializingMnemosynex

	; init mapper mgr
	print	initializingMapperMsg
	ld		a, #MNEMO_MAPPER_DEVICE_ID
	call	_InitRamMapperInfo

	; get mapperBaseTable address
	call	_GetRamMapperBaseTable
	ex		de, hl
	ld		(#_pMapperBaseTable), hl
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (hl)
	ld		(#primaryMapperSlot), a
.endif

	; save page layout
	ld		hl, #pageConfigGlobalBuffer
	call	_savePageLayout

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
	ld		a, (#primaryMapperSlot)
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

_initMnemoSyneX_initBankPersistTable::
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
	ld		hl, (#afterSegTable)
	jr c,	_initMnemoSyneX_cont	; No more available segments

	; save entry in segmentTable
	ld		(hl), e
	inc		hl
	ld		(hl), d

	; mark segment header with logSegNumber = 0xffff (invalid)
	dec		hl						; hl = pSegHandler
	call	_switchMainPage
	ld		hl, #0xffff				; invalid logSegNumber
	ld		(#MNEMO_MAIN_SWAP_PAGE_ADDR), hl	; mark

	; set hooks jp in segment header
	ld		a, #0xc3				; jp
	ld		(#MNEMO_SEGHDR_LOADHOOK), a
	ld		(#MNEMO_SEGHDR_SAVEHOOK), a

_initMnemoSyneX_printDash:
	ld		a, #'-'
	call	printchar

_initMnemoSyneX_inPhysSegCounter:
	ld		hl, (#afterSegTable)
	inc		hl						; next table entry
	inc		hl
	ld		(#afterSegTable), hl
	ld		de, #MNEMO_MAX_PSEGHANDLE
	or		a
	sbc		hl, de
	add		hl, de
	jr c, 	_initMnemoSyneX_segAllocLoop

_initMnemoSyneX_cont:
	or		a
	ld		de, #MNEMO_AUX_SWAP_PAGE_ADDR
	sbc		hl, de
	srl		h
	rr		l						; hl = #segments
	ld		(#_nPhysicalSegs), hl
	push	hl
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
	ld		(#_managedMemorySize), hl
	call	_PrintDec
	print	memoryManaged2Msg

	print	mnemosynexVirtualMemSize
	ld		hl, #MNEMO_MAX_LOGICAL_MEMORY
	call	_PrintDec
	print	megaBytesMsg

_initMnemoSyneX_end:
	ld		hl, #pageConfigGlobalBuffer
	call	_restorePageLayout
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
	push	ix
	ld		hl, #pageConfigGlobalBuffer
	call	_restorePageLayout
	pop		ix
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

	call	mnemo_allocationInitialServices

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
	xor		a				; clear carry flag (TODO: CHECK if necessary!)
	ld		de, #MNEMO_AUX_SWAP_PAGE_ADDR
	sbc		hl, de
	add		hl, de			
	jr c,	_activateLogSeg_activateSegTableForSearch		; not valid

	; 3. Verify whether pSegHandler <= SegTable end
	xor		a				; clear carry flag  (TODO: CHECK if necessary!)
	ex		de, hl
	ld		hl, (#afterSegTable)
	ex		de, hl
	sbc		hl, de
	add		hl, de			
	jr nc,	_activateLogSeg_activateSegTableForSearch		; not valid

	; activate segTableSegment
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
	jp		_activateLogSeg_updateSegmentMode

_activateLogSeg_activateSegTableForSearch:
	ld		hl, #segTableSegment
	call	_switchAuxPage

_activateLogSeg_searchFreeSeg:
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

_activateLogSeg_rndLoop:
	; makes random point within Segment Table
	srl		d
	rr		e
	or		a						; reset carry flag
	sla		c
	rl		b
	jr nc,	_activateLogSeg_rndLoop
	sla		e
	rl		d						; de = pSegHandler (search starting pointer) - MNEMO_AUX_SWAP_PAGE_ADDR
	inc		de						; de = p(SegHandler.mapperSlot) - MNEMO_AUX_SWAP_PAGE_ADDR

	; search free segment
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR
	add		hl, de					; hl = p(SegHandler.mapperSlot)
	ld		de, #0xffff				; invalid pSegHandler
	ld		c, #MNEMO_ALLOC_INUSE	; best status

_activateLogSeg_searchLoop:
	ld		a, (hl)
	and		#MNEMO_ALLOC_MASK		; seg status
	cp		c
	jr nc,	_activateLogSeg_searchLoop_cont1

	; found a better candidate
	ld		c, a
	ld		d, h
	ld		e, l
	or		a						; TODO: Is this needed?!?!?!?!
	jr z,	_activateLogSeg_activateSegment		; priority 0, position chosen

_activateLogSeg_searchLoop_cont1:
	dec		hl
	ld		a, h
	sub		#>MNEMO_AUX_SWAP_PAGE_ADDR
	or		l
	jr nz,	_activateLogSeg_searchLoop_cont2
	ld		hl, (#afterSegTable)

_activateLogSeg_searchLoop_cont2:
	dec		hl	
	exx
	dec		bc
	ld		a, b
	or		c					; all table positions were checked?
	exx
	jr nz,	_activateLogSeg_searchLoop	; not yet, continue search

	; end of segTable
	ld		a, c
	cp		#MNEMO_ALLOC_INUSE
	jp z,	_activateLogSeg_noFreePhysSegError

_activateLogSeg_activateSegment:
	; update logSegHandler with segHandler
	; de = p(SegHandler.mapperSlot)
	dec		de					; de = pSegHandler
	ex		de, hl				; hl = pSegHandler

	; save
	xor		a					; dont check bank
	call	mnemo_commonSave	; activate main seg and save if needed
	bit		MNEMO_ERROR_BIT, a
	jr nz,	_activateLogSeg_restoreAuxSeg

_activateLogSeg_updateSegmentHeader:
	ld		hl, (#logSegNumber)
	ld		(#MNEMO_SEGHDR_LOGSEGNUMBER), hl

_activateLogSeg_updateSegmentMode:
	ld		a, (#logSegMode)
	ld		(#MNEMO_SEGHDR_SEGMODE), a

_activateLogSeg_updateSegTable:
	ld		hl, (#pSegHandler)
	ld		a, (hl)
	ld		(#segNumber), a
	inc		hl
	ld		a, (hl)
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	or		#MNEMO_ALLOC_INUSE		; In use
	ld		(hl), a
	ld		(#mapperSlot), a

_activateLogSeg_updatePersistence::
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

_activateLogSeg_updateUsedSegs::
	ld		hl, (#_nPhysicalSegsInUse)
	inc		hl
	ld		(#_nPhysicalSegsInUse), hl
	
_activateLogSeg_updateLogSegTable:
	ld		hl, (#pLogSegTableSegment)
	call	_switchAuxPage
	exx									; restore
	dec		hl
	ex		de, hl
	ld		hl, (#pLogSegTableItem)
	ld		(hl), e
	inc		hl
	ld		(hl), d

_activateLogSeg_checkReadMode::
	ld		a, (#logSegMode)
	and		#3
	jr z,	_activateLogSeg_restoreAuxSeg		; Mode 0 (TEMPMEM): no load
	cp		#MNEMO_SEGMODE_FORCEDREAD
	jr z,	_activateLogSeg_load				; Mode 2 (FORCEREAD): load 
	ld		a, (#logSegLoaded)					; Mode 1 (READ) or 3 (READWRITE)
	or		a									;	If segment in memory,
	ld		a, #0
	jr nz,	_activateLogSeg_restoreAuxSeg		;	no load.

_activateLogSeg_load:
	call	MNEMO_SEGHDR_LOADHOOK

_activateLogSeg_restoreAuxSeg::
	push	af
	ld		hl, #auxSegHandlerTemp
	call	_switchAuxPage
	pop		af
	bit		MNEMO_ERROR_BIT, a
	jr nz,	_activateLogSeg_end

_activateLogSeg_updateLogSegHandler::
	; update logSegHandler from page 3
	ld		hl, #logSegHandler
	ld		de, (pLogSegHandler)
	ld		bc, #(logSegHandler_params - logSegHandler)
	ldir

_activateLogSeg_end::
	pop		ix
	ret

_activateLogSeg_segOutOfRangeError:
	ld		a, #MNEMO_ERROR_SEGOUTOFRANGE
	jr		_activateLogSeg_end

_activateLogSeg_noFreePhysSegError:
	ld		a, #MNEMO_ERROR_NOFREEPHYSSEG
	jr		_activateLogSeg_end


; ----------------------------------------------------------------
;	- Releases segment from a logSegHandler pointed by DE
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- DE: pLogSegHandler
;
; OUTPUTS:
;   - None
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

mnemo_releaseLogSegHL_cont::
	call	mnemo_allocationInitialServices
	
	; assert segNumber
	ld		hl, #segTableSegment
	call	_switchAuxPage
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

	; update release priority
	ld		hl, #auxSegHandlerTemp
	call	_switchAuxPage
	ld		hl, (#pLogSegHandler)
	inc		hl
	ld		a, (#mapperSlot)
	ld		(hl), a
	xor		a
	pop		ix
	ret

mnemo_releaseLogSegHL_outdatedSegHandler::
	ld		a, #MNEMO_WARN_OUTDATEDPSEGHANDLER

mnemo_restoreAuxPageAndReturnStatus::				
	push	af
	ld		hl, #auxSegHandlerTemp
	call	_switchAuxPage
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
	call	_switchAuxPage
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR + 1
	ld		a, (#releasePriority)
	ld		b, a
	ld		de, (#afterSegTable)

_mnemo_releaseAll_loop::
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

_mnemo_releaseAll_next::
	inc		hl
	inc		hl
	or		a						; reset carry
	sbc		hl, de
	add		hl, de
	jr c,	_mnemo_releaseAll_loop

	ld		hl, #auxSegHandlerTemp
	call	_switchAuxPage
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
	call	_switchAuxPage
	ld		hl, #MNEMO_AUX_SWAP_PAGE_ADDR

_mnemo_flushAll_loop::
	xor		a			; do not check bank
	push	hl
	call	mnemo_commonSave
	pop		hl
	cp		#MNEMO_ERROR_SEGINUSE
	jr z,	_mnemo_flush_next
	bit		MNEMO_ERROR_BIT, a
	jr nz,	mnemo_restoreAuxPageAndReturnStatus	; same ending

_mnemo_flush_next::
	inc		hl
	inc		hl
	or		a							; reset carry
	ld		de, (#afterSegTable)
	sbc		hl, de
	add		hl, de
	jr c,	_mnemo_flushAll_loop

	; Ensure last files buffers are written to disk
	;ld		a, (#fileHandle)
	ld		b, a
	ld		c, #BDOS_ENSURE
	call	BDOS_SYSCAL
	or		a
	jr z,	mnemo_restoreAuxPageAndReturnStatus		; same ending
	ld		a, #MNEMO_ERROR_SEGWRITEFAIL
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
_savePageLayout::
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
_restorePageLayout::
	push	hl
	call	_switchAuxPage
	pop		hl
	inc		hl
	inc		hl
	jp		_switchMainPage


; ----------------------------------------------------------------
;	- Get number of Free Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - HL: Number of free segments
;
; CHANGES:
;   - DE
; ----------------------------------------------------------------
_mnemoGetFreeSegments::
	__mnemoGetUsedSegments
	ex		de, hl
	__mnemoGetManagedSegments
	or		a					; set carry flag
	sbc		hl, de
	ret


; ----------------------------------------------------------------
;	- Set a bank to standard persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number
;
; OUTPUTS:
;	- None
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
_mnemoSetStandardPersistence::
	ld		de, #0
	push	de


; ----------------------------------------------------------------
;	- Set bank persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number
;	- DE: pLoadSeg
;   - Stack: pSaveSeg
;
; OUTPUTS:
;	- None
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
_mnemoSetPersistence::
	; Set Segment Table segment in Aux Page
	push	de
	push	af
	ld		hl, #segTableSegment
	call	_switchAuxPage

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
	ret


; ----------------------------------------------------------------
;	- Strings
; ----------------------------------------------------------------
initializingMnemosynex::		.asciz "** MnemoSyne-X Virtual Memory **\r\n"
mnemosynexVirtualMemSize::		.asciz "Virtual Memory Size is "
initializingMapperMsg::			.asciz "Initializing mapper service..."
allocatingIndexSegmentsMsg::	.asciz "Allocating index segments... "
allocatingSegmentsMsg::			.asciz "Allocating segments...\r\n=> "
segmentsAllocatedMsg::			.asciz " segments allocated.\r\n"
memoryManaged1Msg::				.asciz "Managing "
memoryManaged2Msg::				.asciz "Kbytes of physical memory.\r\n"
megaBytesMsg::					.asciz "Mbytes.\r\n"

okMsg::							.asciz " [OK]\r\n"

;   ==================================
;   ========== DATA SEGMENT ==========
;   ==================================
	.area	_DATA

;
; buffer and indexes
;
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

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
primaryMapperSlot::			.ds 1
usePrimaryMapperOnly::		.ds 1
mapperQueryTag::			.ds 2
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
pLogSegHandler::			.ds 2
logSegHandler::
segHandler::
segNumber::					.ds 1
mapperSlot::				.ds 1
pSegHandler::				.ds 2
pLogSegTableItem::			.ds 2		; TODO: Check if this can be dropped from the handler
logSegHandler_params::
logSegNumber::				.ds 2
logSegMode::				.ds 1
logSegHandler_end::
