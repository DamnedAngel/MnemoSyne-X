; ----------------------------------------------------------------
;	mnemosyne-x_h.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the asm headers for integrating MnemoSyne-X.
; ----------------------------------------------------------------

.include "mnemosyne-x_config.s"

; ----------------------------------------------------------------
;	- Error messages
; ----------------------------------------------------------------
MNEMO_ERROR_SUCCESS					= 0
MNEMO_ERROR_NOINDEXSEG				= 1
MNEMO_ERROR_SEGOUTOFRANGE			= 2
MNEMO_ERROR_NOFREEPHYSSEG			= 3
MNEMO_ERROR_FILEOPENFAIL			= 4
MNEMO_WARN_NOSEG					= 5	
MNEMO_ERROR_BADSEGINDEX				= 6
MNEMO_ERROR_SEGREADFAIL				= 7
MNEMO_ERROR_IDXWRITEFAIL			= 8
MNEMO_WARN_OUTDATEDPSEGHANDLER		= 9
MNEMO_ERROR_READONLYSEG				= 10
MNEMO_ERROR_SEGWRITEFAIL			= 11


; ----------------------------------------------------------------
;	- Segment mode
; ----------------------------------------------------------------
MNEMO_SEGMODE_MASK					= 0b00000011

MNEMO_SEGMODE_TEMP					= 0
MNEMO_SEGMODE_READ					= 1
MNEMO_SEGMODE_FORCEDREAD			= 2
MNEMO_SEGMODE_READWRITE				= 3

MNEMO_SEGMODE_CUSTOMREAD			= 4
MNEMO_SEGMODE_CUSTOMWRITE			= 8


; ----------------------------------------------------------------
;	- LogSegHandlers offsets
; ----------------------------------------------------------------
MNEMO_LOGSEGHOFFSET_SEGHANDLER			= 0
MNEMO_LOGSEGHOFFSET_PSEGHANDLER			= 2
MNEMO_LOGSEGHOFFSET_PLOGSEGTABLEITEM	= 4
MNEMO_LOGSEGHOFFSET_LOGSEGNUMBER		= 6
MNEMO_LOGSEGHOFFSET_SEGMODE				= 8
MNEMO_LOGSEGHOFFSET_PLOADSEG			= 9
MNEMO_LOGSEGHOFFSET_PSAVESEG			= 11


; ----------------------------------------------------------------
;	- allocation status
; ----------------------------------------------------------------
MNEMO_ALLOC_MASK						= 0b00110000
MNEMO_ALLOC_KEEPPRIORITY0				= 0b00000000	; lowest priority
MNEMO_ALLOC_KEEPPRIORITY1				= 0b00010000	
MNEMO_ALLOC_KEEPPRIORITY2				= 0b00100000	; hightes priority
MNEMO_ALLOC_INUSE						= 0b00110000	


; ----------------------------------------------------------------
;	- Segment header offsets - TO BE MOVED TO INTERFACE HEADER!
; ----------------------------------------------------------------
MNEMO_SEG_HEADER_SIZE				= 8

MNEMO_SEGHDROFFSET_LOGSEGNUMBER		= 0
MNEMO_SEGHDROFFSET_SEGMODE			= 2
MNEMO_SEGHDROFFSET_PSAVESEG			= 3

MNEMO_SEGPAYLOAD_OFFSET				= MNEMO_SEG_HEADER_SIZE


; ----------------------------------------------------------------
;	- Derivative Configuration.
; ----------------------------------------------------------------
.ifne MNEMO_MAIN_SWAP_PAGE - 1
MNEMO_MAIN_SWAP_PAGE				= 2
.endif
MNEMO_AUX_SWAP_PAGE					= 3 - MNEMO_MAIN_SWAP_PAGE

MNEMO_MAX_LOGICAL_MEMORY			= MNEMO_INDEX_SEGMENTS * 128		; in Mbytes				
MNEMO_MAIN_SWAP_PAGE_ADDR			= 0x4000 * MNEMO_MAIN_SWAP_PAGE
MNEMO_AUX_SWAP_PAGE_ADDR			= 0x4000 * MNEMO_AUX_SWAP_PAGE

MNEMO_MAIN_SEGPAYLOAD				= MNEMO_MAIN_SWAP_PAGE_ADDR + MNEMO_SEGPAYLOAD_OFFSET
MNEMO_AUX_SEGPAYLOAD				= MNEMO_AUX_SWAP_PAGE_ADDR + MNEMO_SEGPAYLOAD_OFFSET


; ----------------------------------------------------------------
;	- Dirty Page Switch macros - TO BE MOVED TO INTERFACE HEADER!
; ----------------------------------------------------------------
.macro	_DirtySwitch	PAGE
.ifeq	(PAGE - 2)
	call	_dirtySwitchP2
.else
	.ifeq	(PAGE - 1)
	call	_dirtySwitchP1
	.else
	call	_dirtySwitchP0
	.endif
.endif
.endm

.macro	_DirtySwitchMain
	_DirtySwitch	MNEMO_MAIN_SWAP_PAGE
.endm

.macro	_DirtySwitchAux
	_DirtySwitch	MNEMO_AUX_SWAP_PAGE
.endm


; ----------------------------------------------------------------
;	- Get number of Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - HL
; ----------------------------------------------------------------
.macro	__mnemoGetManagedSegments
	ld		hl, (#_nPhysicalSegs)
.endm

; ----------------------------------------------------------------
;	- Get Managed Physical Memory Size
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - HL
; ----------------------------------------------------------------
.macro	__mnemoGetManagedMemorySize
	ld		hl, (#_managedMemorySize)
.endm

; ----------------------------------------------------------------
;	- Get number of Used Physical Segs
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - HL
; ----------------------------------------------------------------
.macro	__mnemoGetUsedSegments
	ld		hl, (#_nPhysicalSegsInUse)
.endm

; ----------------------------------------------------------------
;	- Init MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- [MNEMO_PRIMARY_MAPPER_ONLY = 1] None
;	- [MNEMO_PRIMARY_MAPPER_ONLY = 0] A: Use primary mappers only
;			0 = All mappers
;			1 = Primary mapper only
;
; OUTPUTS:
;   - A:  0 = Success
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
;.globl _initMnemoSyneX


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
;.globl _finalizeMnemoSyneX


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
;.globl _activateLogSeg

; ----------------------------------------------------------------
;	- Releases segment from a logSegHandler pointed by DE
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- DE: pointer to logical segment handler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - A, DE, HL
; ----------------------------------------------------------------
;.globl _mnemo_releaseLogSeg

; ----------------------------------------------------------------
;	- Releases segment from a logSegHandler pointed by HL
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- HL: pointer to logical segment handler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - A, DE, HL
; ----------------------------------------------------------------
;.globl mnemo_releaseLogSegHL

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
;.globl _mnemoGetUsedSegments

