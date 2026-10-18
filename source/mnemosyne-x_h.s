; ----------------------------------------------------------------
;	mnemosyne-x_h.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the asm headers for integrating MnemoSyne-X.
;	For programs linked together with MnemoSyne-X; programs and
;	MDOs that call it through MDO hooks must include
;   mnemosyne-x_mdo_h.s instead.
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
;	- DE: pointer to a string with the databanks filename: up to 8
;			characters; a shorter name ends at its first space or zero
;
; OUTPUTS:
;   - A:  0 = Success
;		  MNEMO_ERROR_BADFILENAME = The databanks filename is empty (it
;			starts with a space or a zero)
;		  MNEMO_ERROR_NOINDEXSEG = Not enough free segments in the
;			primary mapper for the index segments
;		  MNEMO_ERROR_NOFREEPHYSSEG = No free segment left to manage
;			after the index segments
;		  Nothing is allocated when init fails.
;		  Calling it again before _mnemo_finalize is not supported (the
;		  segments of the session are leaked)
;
; CHANGES:
;   - All registers but IX (and IY if MNEMO_PRESERVE_IY = 1); AUX and
;   MAIN are restored. Interrupts may be
;	  disabled
; ----------------------------------------------------------------
.globl _mnemo_init


; ----------------------------------------------------------------
;	- Finalize MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - A: 0 = Success
;		  The error of the flush of the pending segments (see
;		  _mnemo_flushAll), or else MNEMO_ERROR_FILECLOSEFAIL. The
;		  shutdown is always completed: the segments that were not
;		  flushed are lost
;
; CHANGES:
;   - All registers but IX (and IY if MNEMO_PRESERVE_IY = 1); AUX and
;   MAIN are restored. Interrupts may be
;	  disabled
; ----------------------------------------------------------------
.globl _mnemo_finalize


; ----------------------------------------------------------------
;	- Set a bank to standard persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number (0 to MNEMO_INDEX_SEGMENTS * 32 - 1)
;
; OUTPUTS:
;	- A:  0 = Success
;		  MNEMO_ERROR_BADBANK = The bank number is out of range
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
.globl _mnemo_setStdPersistence


; ----------------------------------------------------------------
;	- Set bank persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number (0 to MNEMO_INDEX_SEGMENTS * 32 - 1)
;	- DE: pLoadSeg
;   - Stack: pSaveSeg
;
; OUTPUTS:
;	- A:  0 = Success
;		  MNEMO_ERROR_BADBANK = The bank number is out of range; nothing
;			was changed (pSaveSeg is removed from the stack anyway)
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
;   - A:  0 = Success: the logical segment is active, mapped in MAIN,
;			and the handler is updated
;		  MNEMO_ERROR_SEGOUTOFRANGE, MNEMO_ERROR_NOFREEPHYSSEG,
;		  MNEMO_ERROR_SEGALREADYACTIVE (the logical segment is already
;		  active), or an error of the segment save or load: nothing is
;		  activated, the handler is not changed and MAIN is undefined
;		  A < 0x80, A <> 0: warning, the segment is active
;
; CHANGES:
;   - All registers but IX (and IY if MNEMO_PRESERVE_IY = 1); AUX is restored. Interrupts may be disabled
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
;   - A: 0 = Success: the segment is released and the handler is
;			invalidated (its pSegHandler = 0xFFFF)
;		  MNEMO_WARN_OUTDATEDPSEGHANDLER = The handler does not hold an
;		  active segment (invalidated, never activated, released by
;		  _mnemo_releaseAll, or reused): nothing was changed
;
; CHANGES:
;   - All registers but IX (and IY if MNEMO_PRESERVE_IY = 1); AUX is restored; MAIN is untouched.
;   Interrupts may be disabled
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
;   - A: 0 = Success; MNEMO_WARN_OUTDATEDPSEGHANDLER = the handler does
;		  not hold an active segment: nothing was changed (see
;		  _mnemo_releaseLogSeg)
;
; CHANGES:
;   - All registers but IX (and IY if MNEMO_PRESERVE_IY = 1); AUX is restored; MAIN is untouched.
;   Interrupts may be disabled
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
;   - A: 0 = Success
;		  An error of the segment save: the flush stops there, the
;		  segments after it are not flushed and the failed one is still
;		  pending (the call can be repeated)
;
; CHANGES:
;   - All registers but IX (and IY if MNEMO_PRESERVE_IY = 1); AUX and MAIN are restored. Interrupts may be
;	  disabled
;   - Active segments are not flushed: only the released ones
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
;	- Get slot ID of a page
; ----------------------------------------------------------------
; INPUTS:
;	- A: page (0-3)
;
; OUTPUTS:
;   - A: slot ID formatted F000SSPP
;
; CHANGES:
;   - F, BC, DE, H
; ----------------------------------------------------------------
.globl _mnemo_getSlot


; ----------------------------------------------------------------
;	- Get the physical segment mapped in the aux page
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: SEGHANDLER of the current AUX page mapping
;		  (E: segment number, D: slot ID formatted F000SSPP)
;
; CHANGES:
;   - AF, BC, DE, H
; ----------------------------------------------------------------
.globl _mnemo_getAuxPage


; ----------------------------------------------------------------
;	- Get the physical segment mapped in the main page
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: SEGHANDLER of the current MAIN page mapping
;		  (E: segment number, D: slot ID formatted F000SSPP)
;
; CHANGES:
;   - AF, BC, DE, H
; ----------------------------------------------------------------
.globl _mnemo_getMainPage


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
