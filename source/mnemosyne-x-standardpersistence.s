; ----------------------------------------------------------------
;	mnemosyne-x-standardpersistence.s
; ----------------------------------------------------------------
;	240211 - DamnedAngel
; ----------------------------------------------------------------
;	Standard Persistece for MnemoSyne-X
; ----------------------------------------------------------------

.include "msxbios.s"
;.include "applicationsettings.s"
;.include "printinterface.s"

.include "config/mnemosyne-x_config.s"

;.include "rammapper_h.s"
;.include "printdec_h.s"

; ----------------------------------------------------------------
;	- MnemoSyne-X's standard segment load routine. ;'
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
_standardLoad::
	ld	(hl)