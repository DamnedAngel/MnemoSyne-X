; ----------------------------------------------------------------
;	mnemosyne-x_dirty_h.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the asm headers for MnemoSyne-X 
;	dirty operation.
;	These are faster, but very dangerous slot switching routines,
;	which must be used with extreme care.
; ----------------------------------------------------------------

; ----------------------------------------------------------------
;	- Dirty Page Switch macros
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
.globl _saveMemoryMap

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
.globl _restoreMemoryMap

; ----------------------------------------------------------------
;	- Enable a segment from a Segment Handler in page 0
;		BYPASSING THE BIOS!
;	- To use this in a block of code:
;	1. di
;	2. _saveMemoryMap
;	3. _dirtySwith at will
;	4. _restoreMemoryMap
;	5. ei
;	OBS: AVOID BIOS CALLS IN THE BLOCK!
;		 BIOS WILL NOT KNOW THAT THE PAGE HAS BEEN SWITCHED!
;		 THUS ALSO DONT USE NORMAL _switch ROUTINES IN THE BLOCK!  
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to Segment handler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - HL, BC, A
; ----------------------------------------------------------------
.globl _dirtySwitchP0

; ----------------------------------------------------------------
;	- Enable a segment from a Segment Handler in page 1
;		BYPASSING THE BIOS!
;	- To use this in a block of code:
;	1. di
;	2. _saveMemoryMap
;	3. _dirtySwith at will
;	4. _restoreMemoryMap
;	5. ei
;	OBS: AVOID BIOS CALLS IN THE BLOCK!
;		 BIOS WILL NOT KNOW THAT THE PAGE HAS BEEN SWITCHED!
;		 THUS ALSO DONT USE NORMAL _switch ROUTINES IN THE BLOCK!  
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to Segment handler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - HL, BC, A
; ----------------------------------------------------------------
.globl _dirtySwitchP1

; ----------------------------------------------------------------
;	- Enable a segment from a Segment Handler in page 2
;		BYPASSING THE BIOS!
;	- To use this in a block of code:
;	1. di
;	2. _saveMemoryMap
;	3. _dirtySwith at will
;	4. _restoreMemoryMap
;	5. ei
;	OBS: AVOID BIOS CALLS IN THE BLOCK!
;		 BIOS WILL NOT KNOW THAT THE PAGE HAS BEEN SWITCHED!
;		 THUS ALSO DONT USE NORMAL _switch ROUTINES IN THE BLOCK!  
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to Segment handler
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - HL, BC, A
; ----------------------------------------------------------------
.globl _dirtySwitchP2