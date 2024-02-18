; ----------------------------------------------------------------
;	mnemosyne-x-macros_h.s
; ----------------------------------------------------------------
;	240116 - DamnedAngel
; ----------------------------------------------------------------
;	Macros for MnemoSyne-X.
; ----------------------------------------------------------------

.globl	__PutP0
.globl	__PutP1
.globl	__PutP2

.globl	__GetP0
.globl	__GetP1
.globl	__GetP2
.globl	__GetP3

.globl	_getSlot

.globl  _switchAuxPage
.globl  _switchMainPage


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
	call	_getSlot
.endm

.macro	__GetSlotAux
	__GetSlot MNEMO_AUX_SWAP_PAGE
.endm

.macro	__GetSlotMain
	__GetSlot MNEMO_MAIN_SWAP_PAGE
.endm

