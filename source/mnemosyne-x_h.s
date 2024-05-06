; ----------------------------------------------------------------
;	mnemosyne-x_h.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the asm headers for integrating MnemoSyne-X.
; ----------------------------------------------------------------

.include "mnemosyne-x_general_h.s"

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
.globl _mnemo_init


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
.globl _mnemo_finalize


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
.globl _mnemo_activateLogSeg

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
.globl _mnemo_releaseLogSeg

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
.globl mnemo_releaseLogSegHL

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
.globl mnemo_releaseAll

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
.globl _mnemo_getUsedSegments

