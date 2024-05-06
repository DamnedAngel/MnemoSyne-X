; ----------------------------------------------------------------
;	mnemosyne-x_dirty.s
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	This file contains the implementation of faster, but very
;	dangerous slot switching routines, which must be used with
;	extreme care.
; ----------------------------------------------------------------

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
_saveMemoryMap::
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	in		a, (#0xa8)
	ld		(#primarySlots), a
	ld		a, (#0xffff)
	cpl
	ld		(#secondarySlots), a
.endif
	call	__GetP0
	ld		(#segmentP0), a
	call	__GetP1
	ld		(#segmentP1), a
	call	__GetP2
	ld		(#segmentP2), a
	ret

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
_restoreMemoryMap::
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#primarySlots)
	out		(#0xa8), a
	ld		a, (#secondarySlots)
	ld		(#0xffff), a
.endif
	ld		a, (#segmentP0)
	call	__PutP0
	ld		a, (#segmentP1)
	call	__PutP1
	ld		a, (#segmentP2)
	call	__PutP2
	ret

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
_dirtySwitchP0::
	; switch segment
	ld		a, (hl)			; segNumber
	out		(0xfc), a

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	ret nz

	; switch primary slot
	inc		hl
	ld		a, (hl)			; slotid
	ld		b, a
	and		#0b00000011
	ld		c, a
	in		a, (#0xa8)
	and		#0b11111100
	or		c
	out		(#0xa8), a
	ld		a, #0x80
	and		b
	ret z

	; switch secondary slot
	ld		a, b			; slotid
	and		#0b00001100
	srl		a
	srl		a
	ld		c, a
	ld		a, (#0xffff)			; slotid
	cpl
	and		#0b11111100
	or		c
	ld		(#0xffff), a
.endif
	ret

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
_dirtySwitchP1::
	; switch segment
	ld		a, (hl)			; segNumber
	out		(0xfd), a

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	ret nz

	; switch primary slot
	inc		hl
	ld		a, (hl)			; slotid
	ld		b, a
	and		#0b00000011
	sla		a
	sla		a
	ld		c, a
	in		a, (#0xa8)
	and		#0b11110011
	or		c
	out		(#0xa8), a
	ld		a, #0x80
	and		b
	ret z

	; switch secondary slot
	ld		a, b			; slotid
	and		#0b00001100
	ld		c, a
	ld		a, (#0xffff)			; slotid
	cpl
	and		#0b11110011
	or		c
	ld		(#0xffff), a
.endif
	ret

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
_dirtySwitchP2::
	; switch segment
	ld		a, (hl)			; segNumber
	out		(0xfe), a

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
	ld		a, (#usePrimaryMapperOnly)
	or		a
	ret nz

	; switch primary slot
	inc		hl
	ld		a, (hl)			; slotid
	ld		b, a
	and		#0b00000011
	rla
	rla
	rla
	rla
	ld		c, a
	bit		7, b
	jr nz,	_dirtySwitchP2_cont
	in		a, (#0xa8)
	and		#0b11001111
	or		c
	out		(#0xa8), a
	ret

_dirtySwitchP2_cont:
	rla
	rla
	or		c
	ld		c, a
	in		a, (#0xa8)
	ld		d, a
	and		#0b00001111
	or		c
	out		(#0xa8), a
	ld		e, a

	; switch secondary slot
	ld		a, b			; slotid
	and		#0b00001100
	rla
	rla
	ld		c, a
	ld		a, (#0xffff)			; slotid
	cpl
	and		#0b11001111

_dirtySwitch_commonEnd:
	or		c
	ld		(#0xffff), a
	ld		a, e
	and		#0b00111111
	ld		e, a
	ld		a, d
	and		#0b11000000
	or		e
	out		(#0xa8), a
.endif
	ret


;   ==================================
;   ========== DATA SEGMENT ==========
;   ==================================
    .area	_DATA

.ifeq MNEMO_PRIMARY_MAPPER_ONLY
primarySlots:				.ds 1
secondarySlots:				.ds 1
.endif
segmentP0:					.ds 1
segmentP1:					.ds 1
segmentP2:					.ds 1
