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
.globl _initMnemoSyneX

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
.globl _activateLogSeg

; ----------------------------------------------------------------
;	- Releases a segment related to a logical segment number
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- DE: logical segment number
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - A, DE, HL
; ----------------------------------------------------------------
.globl _releaseSeg

; ----------------------------------------------------------------
;	- Releases a segment from a logical segment handler
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
.globl _releaseLogSeg

; ----------------------------------------------------------------
;	- Releases a segment related to a logical segment number in HL
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- HL: logical segment number
;
; OUTPUTS:
;   - None
;
; CHANGES:
;   - A, DE, HL
; ----------------------------------------------------------------
.globl _releaseSeg_HL

; ----------------------------------------------------------------
;	- Releases a segment from a logical segment handler in HL
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
.globl _releaseLogSeg


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
.globl _mnemoGetUsedSegments::
	__mnemoGetUsedSegments
	ex		de, hl
	__mnemoGetManagedSegments
	or		a					; set carry flag
	sbc		hl, de
	ret
