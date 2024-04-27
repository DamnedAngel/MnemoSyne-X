; ----------------------------------------------------------------
;	mnemosyne-x-standardpersistence.s
; ----------------------------------------------------------------
;	240211 - DamnedAngel
; ----------------------------------------------------------------
;	Standard Persistence for MnemoSyne-X
; ----------------------------------------------------------------

.include "msxbios.s"
.include "mnemosyne-x-internal_h.s"

.NOFIL		.equ	0xD7

.globl		_switchAuxPage

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
.globl		primaryMapperSlot
.globl		mapperSlot
.globl		bufferSegment
.globl		usePrimaryMapperOnly
.endif

;   ==================================
;   ========== CODE SEGMENT ==========
;   ==================================
	.area _CODE

; ----------------------------------------------------------------
; ----------------------- SERVICES -------------------------------
; ----------------------------------------------------------------

; ----------------------------------------------------------------
;	- Delivers bank file to persistence routines
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - A:  0  = Success
;		  >0 = Error
;
; CHANGES:
;   - All registers, di
; ----------------------------------------------------------------
persistCommon::
	di

persistCommon_convertLSNibble::
	ld		hl, #MNEMO_MAIN_SWAP_PAGE_ADDR + 1
	ld		bc, #'0'*256+0x0a
	ld		d, #0x0f
	ld		a, (hl)
	and		d
	cp		c
	jr c,	persistCommon_convertLSNibbleSubA
	add		a, #'A'-'9'-1

persistCommon_convertLSNibbleSubA::
	add		a, b

persistCommon_convertLSNibbleEnd::
	ld		e, a

persistCommon_convertMSNibble::
	ld		a, (hl)
	rlca
	rlca
	rlca
	rlca
	and		d
	cp		c
	jr c,	persistCommon_convertMSNibbleSubA
	add		a, #'A'-'9'-1

persistCommon_convertMSNibbleSubA::
	add		a, b

persistCommon_convertMSNibbleEnd::
	ld		d, a

persistCommon_checkCurrentFileindex::
	ld		a, (#fileExtension + 2)
	sub		d
	jr nz,	persistCommon_checkFileHandle
	ld		a, (#fileExtension + 3)
	sub		e
	jp z,	persistCommon_rightFileOpen

persistCommon_checkFileHandle::
	ld		a, (#fileHandle)
	cp		#0xff
	jr z,	#persistCommon_fileClosed

persistCommon_wrongFileOpen::
	ld		b, a
	ld		c, #BDOS_CLOSE
	push	de
	call	BDOS_SYSCAL
	pop		de
	or		a
	jr nz,	persistCommon_fileCloseFail

	; invalidate handle
	ld		a, #0xff
	ld		(#fileHandle), a

persistCommon_fileClosed::

	
	; adjust file extension
	ld		hl, #fileExtension + 2
	ld		(hl), d
	inc		hl
	ld		(hl), e

persistCommon_openFile::
	ld		de, #fileName
	xor		a
	ld		c, #BDOS_OPEN
	call	BDOS_SYSCAL
	or		a
	jr z,	persistCommon_storeHandle
	cp		#.NOFIL
	jr nz,	persistCommon_fileOpenFail

persistCommon_createFile::
	; create file
	ld		de, #fileName
	xor		a
	ld		b, a
	ld		c, #BDOS_CREATE
	call	BDOS_SYSCAL
	or		a
	jr nz,	persistCommon_fileOpenFail

	; close file handle (open leaves the file handle open even if it fails)
	ld		c, #BDOS_CLOSE
	call	BDOS_SYSCAL
	or		a
	jr nz,	persistCommon_fileCloseFail
	jr		persistCommon_openFile

persistCommon_fileOpenFail::
	ld		hl, #fileExtension + 2
	ld		(hl), #'_'
	inc		hl
	ld		(hl), #'_'
	ld		a, #MNEMO_ERROR_FILEOPENFAIL
	ret

persistCommon_fileCloseFail::
	ld		a, #MNEMO_ERROR_FILECLOSEFAIL
	ret

persistCommon_storeHandle::
	ld		a, b
	ld		(#fileHandle), a
	ld		a, (#MNEMO_SEGHDR_LOGSEGNUMBER + 1)
	ld		(#bankNumber), a

	; load segment index table
	ld		de, #segTable
	ld		hl, #256*4
	ld		c, #BDOS_READ
	call	BDOS_SYSCAL
	or		a
	jr z,	persistCommon_rightFileOpen

	; bad or non-existent index table. (Re)create it.
	; reset index in memory	
	ld		hl, #segTable
	ld		de, #segTable + 1
	ld		bc, #4 * 256 - 1
	ld		(hl), #0
	ldir

	; save index
	ld		a, (#fileHandle)
	ld		b, a
	xor		a
	ld		d, a
	ld		e, a
	ld		h, a
	ld		l, a
	ld		c, #BDOS_SEEK
	call	BDOS_SYSCAL		; pointer in beginning of file
	ld		a, (#fileHandle)
	ld		b, a
	ld		de, #segTable
	ld		hl, #256 * 4
	ld		c, #BDOS_WRITE
	call	BDOS_SYSCAL		; write index
	or		a
	jp nz,	persistCommon_indexWriteFail

persistCommon_rightFileOpen::
	ld		hl, #MNEMO_MAIN_SWAP_PAGE_ADDR
;	inc		hl				; (hl) = segIndex
	ld		l, (hl)
	ld		h, #0			; hl = segIndex
	add		hl, hl
	add		hl, hl			; hl = indexOffset = segIndex * 4
	ld		(#indexOffset), hl
	ex		de, hl
	ld		hl, #segTable
	add		hl, de			; hl = indexAddr; (hl) = segOffset (4 bytes)
	ld		(#indexAddr), hl
	ld		e, (hl)
	inc		hl
	ld		d, (hl)
	inc		hl
	ld		a, (hl)
	inc		hl
	ld		h, (hl)
	ld		l, a			; de:hl = segOffset
	or		e
	or		d
	or		h
	ld		a, #MNEMO_WARN_NOSEG
	ret z

persistCommon_searchSegInFile::
;	ex		de, hl
	ld		a, (#fileHandle)
	ld		b, a
	xor		a
	ld		c, #BDOS_SEEK
	call	BDOS_SYSCAL		; pointer in beginning of segment
	or		a
	ret z

persistCommon_badSegIndex::
	; fix (reset) entry
	ld		hl, (#indexAddr)
	xor		a
	ld		(hl), a
	inc		hl
	ld		(hl), a
	inc		hl
	ld		(hl), a
	inc		hl
	ld		(hl), a			; entry reset
	call	persistCommon_saveEntry
	ld		a, #MNEMO_ERROR_BADSEGINDEX
	ret
	
persistCommon_saveEntry::
	; point to entry
	ld		a, (#fileHandle)
	ld		b, a
	xor		a
	ld		d, a
	ld		e, a
	ld		hl, (#indexOffset)
	ld		c, #BDOS_SEEK
	call	BDOS_SYSCAL
	or		a
	jr nz,	persistCommon_indexWriteFail
	; write entry
	ld		a, (#fileHandle)
	ld		b, a
	ld		hl, (#indexAddr)
	ex		de, hl
	ld		hl, #4
	ld		c, #BDOS_WRITE
	call	BDOS_SYSCAL		; write index
	or		a
	ret z

persistCommon_indexWriteFail::
	ld		a, #MNEMO_ERROR_IDXWRITEFAIL
	ret


; ----------------------------------------------------------------
; ----------------------- ENGINE ---------------------------------
; ----------------------------------------------------------------

; ----------------------------------------------------------------
;	- Standard segment load routine for MnemoSine-X
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - A:  0  = Success
;		  >0 = Error
;
; CHANGES:
;   - All registers, di
; ----------------------------------------------------------------
_standardLoad::
	call	persistCommon
	or		a
	ret nz

_standardLoad_readSegment::
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	jr nz,	_standardLoad_readToMainPage

	; check whether seg is on primary mapper anyway
	ld		a, (#mapperSlot)
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	ld		hl, #primaryMapperSlot
	sub		(hl)
	ld		(#isSecondaryMapper), a
	jr z,	_standardLoad_readToMainPage

	ld		hl, #bufferSegment
	call	_switchAuxPage

	ld		de, #MNEMO_AUX_SEGPAYLOAD
	jr		_standardLoad_doRead
.endif

_standardLoad_readToMainPage::
	ld		de, #MNEMO_MAIN_SEGPAYLOAD

_standardLoad_doRead::
	ld		hl, #MNEMO_SEGPAYLOAD_SIZE
	ld		a, (#fileHandle)
	ld		b, a
	ld		c, #BDOS_READ
	call	BDOS_SYSCAL		; pointer in beginning of segment
	or		a
	ld		a, #MNEMO_ERROR_SEGREADFAIL
	ret nz

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#isSecondaryMapper)
	or		a
	jr z,	_standardLoad_end
	ld		de, #MNEMO_MAIN_SEGPAYLOAD
	ld		hl, #MNEMO_AUX_SEGPAYLOAD
	ld		bc, #MNEMO_SEGPAYLOAD_SIZE
	ldir
_standardLoad_end::
.endif
	xor		a
	ret

; ----------------------------------------------------------------
;	- Standard segment save routine for MnemoSine-X
; ----------------------------------------------------------------
; INPUTS:
;	- A:  0 = Dont check bank
;		  >0 = Only save if correct bank is active
;
; OUTPUTS:
;   - A:  0  = Success
;		  >0 = Error
;
; CHANGES:
;   - All registers, di
; ----------------------------------------------------------------
_standardSave::
	or		a
	jr z,	_standardSave_assertReadWrite

	; check file open
	ld		a, (#fileHandle)	; 0xff if file not open
	inc		a
	ld		a, #MNEMO_WARN_BANKNOTACTIVE
	ret c

	; check file open
	ld		a, (#MNEMO_SEGHDR_LOGSEGNUMBER + 1)
	ld		hl, #bankNumber
	cp		(hl)
	ld		a, #MNEMO_WARN_BANKNOTACTIVE
	ret nz

_standardSave_assertReadWrite::
	; assert seg is marked as readwrite
	ld		a, (#MNEMO_SEGHDR_SEGMODE)
	and		#MNEMO_SEGMODE_MASK
	cp		#MNEMO_SEGMODE_READWRITE
	ld		a, #MNEMO_ERROR_READONLYSEG
	ret nz

	call	persistCommon
	ld		(#temp1), a
	or		a
	jr z,	_standardSave_saveSegment
	bit		MNEMO_ERROR_BIT, a
	ret nz

	; first time saving this segment. Go to EOF
	ld		a, (#fileHandle)
	ld		b, a
	ld		d, #0
	ld		e, d
	ld		h, d
	ld		l, d
	ld		a, #2
	ld		c, #BDOS_SEEK
	call	BDOS_SYSCAL
	ld		a, #MNEMO_ERROR_SEGWRITEFAIL
	ret nz

	; temporarily save offset
	ld		b, h
	ld		c, l
	ld		hl, #temp4
	ld		(hl), e
	inc		hl
	ld		(hl), d
	inc		hl
	ld		(hl), c
	inc		hl
	ld		(hl), b

_standardSave_saveSegment::
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	jr nz,	_standardSave_saveFromMainPage

	; check whether seg is on primary mapper anyway
	ld		a, (#mapperSlot)
	and		#~(MNEMO_ALLOC_MASK + MNEMO_FLUSH)
	ld		hl, #primaryMapperSlot
	sub		(hl)
	jr z,	_standardSave_saveFromMainPage

	ld		hl, #bufferSegment
	call	_switchAuxPage

	ld		de, #MNEMO_AUX_SEGPAYLOAD
	ld		hl, #MNEMO_MAIN_SEGPAYLOAD
	ld		bc, #MNEMO_SEGPAYLOAD_SIZE
	ldir

	ld		de, #MNEMO_AUX_SEGPAYLOAD
	jr		_standardSave_doSave
.endif

_standardSave_saveFromMainPage:
	ld		de, #MNEMO_MAIN_SEGPAYLOAD

_standardSave_doSave::
	ld		hl, #MNEMO_SEGPAYLOAD_SIZE
	ld		a, (#fileHandle)
	ld		b, a
	ld		c, #BDOS_WRITE
	call	BDOS_SYSCAL		; pointer in beginning of segment
	or		a
	ld		a, #MNEMO_ERROR_SEGWRITEFAIL
	ret nz	
	ld		a, (#temp1)
	or		a
	ret z

_standardSave_saveIndex::
	ld		de, (#indexAddr)
	ld		hl, #temp4
	ld		bc, #4
	ldir
	jp		persistCommon_saveEntry

fileHandle::				.db		#0xff
fileName::					.ascii	'THETRIAL'
fileExtension::				.asciz	'.___'

;   ==================================
;   ========== DATA SEGMENT ==========
;   ==================================
	.area	_DATA

segTable::					.ds		256 * 4
indexOffset::				.ds		2
indexAddr::					.ds		2
isSecondaryMapper::			.ds		1
temp1::						.ds		1
temp4::						.ds		4
bankNumber::				.ds		1