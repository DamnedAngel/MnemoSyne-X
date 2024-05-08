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
.globl _mnemo_setStdPersistence


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
.globl _mnemo_setPersistence

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
;	- Releases segment from a logSegHandler pointed by DE (SDCCCALL(1))
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- DE: pointer to logical segment handler
;
; OUTPUTS:
;   - A: Error code
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
;   - A: Error code
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
.globl _mnemo_releaseAll


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
.globl _mnemo_flushAll


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
.globl _mnemo_switchAuxPage


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
.globl _mnemo_switchMainPage


; ----------------------------------------------------------------
;	- Get number of Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: number of Managed Physical Segments
;
; CHANGES:
;   - Nothing
; ----------------------------------------------------------------
.globl _mnemo_getManagedSegments


; ----------------------------------------------------------------
;	- Get number of Used Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: number of Used Managed Physical Segments
;
; CHANGES:
;   - Nothing
; ----------------------------------------------------------------
.globl _mnemo_getUsedSegments


; ----------------------------------------------------------------
;	- Get number of Free Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: Number of free segments
;
; CHANGES:
;   - HL
; ----------------------------------------------------------------
.globl _mnemo_getFreeSegments
