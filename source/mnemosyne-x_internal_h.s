; ----------------------------------------------------------------
;	mnemosyne-x_internal_h.s
; ----------------------------------------------------------------
;	240116 - DamnedAngel
; ----------------------------------------------------------------
;	Macros for MnemoSyne-X.
; ----------------------------------------------------------------


.include "msxbios.s"
.include "printinterface_h.s"
.include "printdec_h.s"
.include "random_h.s"
.include "mnemosyne-x_rammapper_h.s"
.include "mnemosyne-x_general_h.s"

.globl _standardLoad
.globl _standardSave

; ----------------------------------------------------------------
;	- General Settings
; ----------------------------------------------------------------
MNEMO_MAPPER_DEVICE_ID				= 4									; always 4 (memory mapper)

; Mapper segments taken by mnemo_init for its own bookkeeping: the index
; segments, the Segment Table segment and, with MNEMO_PRIMARY_MAPPER_ONLY = 0,
; the buffer segment
.ifeq MNEMO_PRIMARY_MAPPER_ONLY
MNEMO_INTERNAL_SEGMENTS				= MNEMO_INDEX_SEGMENTS + 2
.else
MNEMO_INTERNAL_SEGMENTS				= MNEMO_INDEX_SEGMENTS + 1
.endif


; ----------------------------------------------------------------
;	- Macros
; ----------------------------------------------------------------
.macro	__PutSeg PAGE
.ifeq PAGE
	call	__PutP0
.else
	.ifeq PAGE - 1
	call	__PutP1
	.else
		.ifeq PAGE - 2
	call	__PutP2
		.endif
	.endif
.endif
.endm

.macro	__PutSegAux
	__PutSeg MNEMO_AUX_SWAP_PAGE
.endm

.macro	__PutSegMain
	__PutSeg MNEMO_MAIN_SWAP_PAGE
.endm

; -----

.macro	__GetSeg PAGE
.ifeq PAGE
	call	__GetP0
.else
	.ifeq PAGE - 1
	call	__GetP1
	.else
		.ifeq PAGE - 2
	call	__GetP2
		.else
	call	__GetP3
		.endif
	.endif
.endif
.endm

.macro	__GetSegAux
	__GetSeg MNEMO_AUX_SWAP_PAGE
.endm

.macro	__GetSegMain
	__GetSeg MNEMO_MAIN_SWAP_PAGE
.endm

; -----

.macro	__GetSlot PAGE
	ld		h, #PAGE * 0b01000000
	call	mnemo_getSlot
.endm

.macro	__GetSlotAux
	__GetSlot MNEMO_AUX_SWAP_PAGE
.endm

.macro	__GetSlotMain
	__GetSlot MNEMO_MAIN_SWAP_PAGE
.endm

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
.macro	__mnemo_getManagedSegments
	ld		de, (#_nPhysicalSegs)
.endm

; ----------------------------------------------------------------
;	- Get Managed Physical Memory Size
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: Managed Physical Memory Size
;
; CHANGES:
;   - Nothing
; ----------------------------------------------------------------
.macro	__mnemo_getManagedMemorySize
	ld		de, (#_managedMemorySize)
.endm

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
.macro	__mnemo_getUsedSegments
	ld		de, (#_nPhysicalSegsInUse)
.endm
