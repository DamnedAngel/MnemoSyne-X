; ----------------------------------------------------------------
;	mnemosyne-x-standardpersistence.s
; ----------------------------------------------------------------
;	240211 - DamnedAngel
; ----------------------------------------------------------------
;	Standard Persistence for MnemoSyne-X
; ----------------------------------------------------------------

.include "msxbios.s"
.include "config/mnemosyne-x_config.s"
.include "mnemosyne-x-macros_h.s"

.NOFIL		.equ	0xD7

.globl		_switchAuxPage

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
.globl		bufferSegment
.globl		usePrimaryMapperOnly
.endif

;   ==================================
;   ========== CODE SEGMENT ==========
;   ==================================
	.area _CODE

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
	di
;	ld		(#pageAddr), hl
;	inc		hl
	ld		hl, #MNEMO_MAIN_SWAP_PAGE_ADDR + 1


_standardLoad_convertLSNibble::
	ld		bc, #'0'*256+0x0a
	ld		d, #0x0f
	ld		a, (hl)
	and		d
	cp		c
	jr c,	_standardLoad_convertLSNibbleSubA
	add		a, #'A'-'0'

_standardLoad_convertLSNibbleSubA::
	add		a, b

_standardLoad_convertLSNibbleEnd::
	ld		e, a

_standardLoad_convertMSNibble::
	ld		a, (hl)
	rlca
	rlca
	rlca
	rlca
	and		d
	cp		c
	jr c,	_standardLoad_convertMSNibbleSubA
	add		a, #'A'-'0'

_standardLoad_convertMSNibbleSubA::
	add		a, b

_standardLoad_convertMSNibbleEnd::
	ld		d, a

_standardLoad_checkCurrentFileindex::
	ld		a, (#fileExtension + 2)
	sub		d
	jr nz,	_standardLoad_checkFileHandle
	ld		a, (#fileExtension + 3)
	sub		e
	jp z,	_standardLoad_rightFileOpen

_standardLoad_checkFileHandle::
	ld		a, (#fileHandle)
	cp		#0xff
	jr z,	#_standardLoad_fileClosed

_standardLoad_wrongFileOpen::
	ld		b, a
	ld		c, #BDOS_CLOSE
	push	de
	call	BDOS_SYSCAL
	pop		de
	ld		a, #0xff
	ld		(#fileHandle), a

_standardLoad_fileClosed::
	; adjust file extension
	ld		hl, #fileExtension + 2
	ld		(hl), d
	inc		hl
	ld		(hl), e

_standardLoad_openFile::
	ld		de, #fileName
	xor		a
	ld		b, a
	ld		c, #BDOS_OPEN
	call	BDOS_SYSCAL
	or		a
	jr z,	_standardLoad_storeHandle
	cp		#.NOFIL
	jr nz,	_standardLoad_fileOpenFail

_standardLoad_createFile::
	ld		de, #fileName
	xor		a
	ld		b, a
	ld		c, #BDOS_CREATE
	call	BDOS_SYSCAL
	or		a
	jr z,	_standardLoad_openFile

_standardLoad_fileOpenFail::
	ld		hl, #fileExtension + 2
	ld		(hl), #'_'
	inc		hl
	ld		(hl), #'_'
	ld		a, #MNEMO_ERROR_FILEOPENFAIL
	ret

_standardLoad_storeHandle::
	ld		a, b
	ld		(#fileHandle), a

	; load segment index table
	ld		de, #segTable
	ld		hl, #256*4
	ld		c, #BDOS_READ
	call	BDOS_SYSCAL
	or		a
	jr z,	_standardLoad_rightFileOpen

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
	jp nz,	_common_indexWriteFail
	ld		a, #MNEMO_WARN_NOSEGINDEX
	ret

_standardLoad_rightFileOpen::
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
	jr z,	_standardLoad_noSegWarn
	ex		de, hl
	ld		a, (#fileHandle)
	ld		b, a
	xor		a
	ld		c, #BDOS_SEEK
	call	BDOS_SYSCAL		; pointer in beginning of segment
	or		a
	jr nz,	_standardLoad_segReadFail

_standardLoad_readSegment::
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	jr nz,	_standardLoad_readOnPrimaryMapper

	ld		hl, #bufferSegment
	call	_switchAuxPage

	ld		de, #MNEMO_AUX_SEGPAYLOAD
	jr		_standardLoad_doRead
.endif

_standardLoad_readOnPrimaryMapper:
	ld		de, #MNEMO_MAIN_SEGPAYLOAD

_standardLoad_doRead::
	ld		hl, #1024*16 - MNEMO_SEG_HEADER_SIZE
	ld		a, (#fileHandle)
	ld		b, a
	ld		c, #BDOS_READ
	call	BDOS_SYSCAL		; pointer in beginning of segment

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		de, #MNEMO_MAIN_SEGPAYLOAD
	ld		hl, #MNEMO_AUX_SEGPAYLOAD
	ld		bc, #1024*16 - MNEMO_SEG_HEADER_SIZE
	ldir
.endif
	or		a
	ret z

_standardLoad_segReadFail::
	ld		a, #MNEMO_ERROR_SEGREADFAIL
	ret

_standardLoad_noSegWarn::
	ld		a, #MNEMO_WARN_NOSEG
	ret

_standardLoad_badSegIndex::
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
	call	saveEntry
	ld		a, #MNEMO_ERROR_BADSEGINDEX
	ret

saveEntry::
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
	jr nz,	_common_indexWriteFail
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

_common_indexWriteFail::
	ld		a, #MNEMO_ERROR_IDXWRITEFAIL
	ret

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