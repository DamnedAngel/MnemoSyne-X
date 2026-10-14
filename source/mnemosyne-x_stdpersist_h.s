; ----------------------------------------------------------------
;	mnemosyne-x-standardpersistence_h.s
; ----------------------------------------------------------------
;	240211 - DamnedAngel
; ----------------------------------------------------------------
;	Standard Persistence for MnemoSyne-X
; ----------------------------------------------------------------


; ----------------------------------------------------------------
;	- Standard segment load routine for MnemoSyne-X
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
.globl _standardLoad


; ----------------------------------------------------------------
;	- Standard segment save routine for MnemoSyne-X
; ----------------------------------------------------------------
; INPUTS:
;	- A:  0 = Dont check bank
;		  >0 = Only save if correct bank is active
;
; OUTPUTS:
;   - A:  0  = Success
;		  >0 = Error
;
; CHANGES:
;   - All registers, di
; ----------------------------------------------------------------
.globl _standardSave


; ----------------------------------------------------------------
;	- Standard ensure routine for MnemoSyne-X: writes the buffers
;	  of the open Databank file to disk
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - A:  0  = Success (or no Databank file open)
;		  >0 = Error
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _standardEnsure


; ----------------------------------------------------------------
;	- Standard close routine for MnemoSyne-X: closes the open
;	  Databank file
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - A:  0  = Success (or no Databank file open)
;		  >0 = Error
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _standardClose
