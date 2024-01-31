; ----------------------------------------------------------------
;	mnemosyne-x_config.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the configuration of MnemoSyne-X.
; ----------------------------------------------------------------

; ----------------------------------------------------------------
;	- General Configuration.
; ----------------------------------------------------------------
MNEMO_MAPPER_DEVICE_ID		= 4									; always 4 (memory mapper)
MNEMO_INDEX_SEGMENTS		= 1									; 1 (8kSegs/128Mb) to 8 (64ksegs/1Gb)
MNEMO_PRIMARY_MAPPER_ONLY	= 0									; 1 ignores secondary mappers
MNEMO_MAIN_SWAP_PAGE		= 2
MNEMO_AUX_SWAP_PAGE			= 1


; ----------------------------------------------------------------
;	- Error messages - TO BE MOVED TO ERROR HEADER!
; ----------------------------------------------------------------
MNEMO_ERROR_NOINDEXSEG		= 1


; ----------------------------------------------------------------
;	- Derivative Configuration.
; ----------------------------------------------------------------
MNEMO_MAX_LOGICAL_MEMORY	= MNEMO_INDEX_SEGMENTS * 128		; in Mbytes				
MNEMO_MAIN_SWAP_PAGE_ADDR	= 0x4000 * MNEMO_MAIN_SWAP_PAGE
MNEMO_AUX_SWAP_PAGE_ADDR	= 0x4000 * MNEMO_AUX_SWAP_PAGE

