; ----------------------------------------------------------------
;	mnemosyne-x_config.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the configuration of MnemoSyne-X.
; ----------------------------------------------------------------

; ---------------------------------------------------------------
;	- General Configuration.
; ----------------------------------------------------------------
MNEMO_MAPPER_DEVICE_ID				= 4									; always 4 (memory mapper)
MNEMO_INDEX_SEGMENTS				= 5									; 1 (8kSegs/128Mb) to 8 (64ksegs/1Gb)
MNEMO_PRIMARY_MAPPER_ONLY			= 1									; 1 ignores secondary mappers
MNEMO_MAIN_SWAP_PAGE				= 2
MNEMO_AUX_SWAP_PAGE					= 1


; ----------------------------------------------------------------
;	- Error messages - TO BE MOVED TO INTERFACE HEADER!
; ----------------------------------------------------------------
MNEMO_ERROR_NOINDEXSEG				= 1
MNEMO_ERROR_SEGOUTOFRANGE			= 2
MNEMO_ERROR_NOFREEPHYSSEG			= 3

; ----------------------------------------------------------------
;	- Segment mode - TO BE MOVED TO INTERFACE HEADER!
; ----------------------------------------------------------------
MNEMO_SEGMODE_TEMP					= 0
MNEMO_SEGMODE_READ					= 1
MNEMO_SEGMODE_FORCEDREAD			= 2
MNEMO_SEGMODE_READWRITE				= 3

MNEMO_SEGMODE_CUSTOMREAD			= 4
MNEMO_SEGMODE_CUSTOMWRITE			= 8

; ----------------------------------------------------------------
;	- LogSegHandlers offsets - TO BE MOVED TO INTERFACE HEADER!
; ----------------------------------------------------------------
MNEMO_LOGSEGHOFFSET_SEGHANDLER			= 0
MNEMO_LOGSEGHOFFSET_PSEGHANDLER			= 2
MNEMO_LOGSEGHOFFSET_PLOGSEGTABLEITEM	= 4
MNEMO_LOGSEGHOFFSET_LOGSEGNUMBER		= 6
MNEMO_LOGSEGHOFFSET_SEGMODE				= 8
MNEMO_LOGSEGHOFFSET_PLOADSEG			= 9
MNEMO_LOGSEGHOFFSET_PSAVESEG			= 11

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
;	- Segment header offsets - TO BE MOVED TO INTERFACE HEADER!
; ----------------------------------------------------------------
MNEMO_SEGHDROFFSET_LOGSEGNUMBER		= 0
MNEMO_SEGHDROFFSET_SEGMODE			= 2
MNEMO_SEGHDROFFSET_PSAVESEG			= 3

; ----------------------------------------------------------------
;	- Derivative Configuration.
; ----------------------------------------------------------------
MNEMO_MAX_LOGICAL_MEMORY			= MNEMO_INDEX_SEGMENTS * 128		; in Mbytes				
MNEMO_MAIN_SWAP_PAGE_ADDR			= 0x4000 * MNEMO_MAIN_SWAP_PAGE
MNEMO_AUX_SWAP_PAGE_ADDR			= 0x4000 * MNEMO_AUX_SWAP_PAGE

MNEMO_SEGHDR_LOGSEGNUMBER			= MNEMO_MAIN_SWAP_PAGE_ADDR + MNEMO_SEGHDROFFSET_LOGSEGNUMBER
MNEMO_SEGHDR_SEGMODE				= MNEMO_MAIN_SWAP_PAGE_ADDR + MNEMO_SEGHDROFFSET_SEGMODE;
MNEMO_SEGHDR_PSAVESEG				= MNEMO_MAIN_SWAP_PAGE_ADDR + MNEMO_SEGHDROFFSET_PSAVESEG;