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
MNEMO_MAIN_SWAP_PAGE				= 1									; Either 1 or 2. Anything else means 2.
MNEMO_INDEX_SEGMENTS				= 8									; 1 (8kSegs/128Mb) to 8 (64ksegs/1Gb)
MNEMO_PRIMARY_MAPPER_ONLY			= 1									; 1 ignores secondary mappers
MNEMO_MAX_PHYSICAL_SEGMENTS			= 3072								; 3072 (48Mb) = max. Anything above this will default to 3072
