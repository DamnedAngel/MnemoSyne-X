; ----------------------------------------------------------------
;	mnemosyne-x-internal_h.s
; ----------------------------------------------------------------
;	240116 - DamnedAngel
; ----------------------------------------------------------------
;	Macros for MnemoSyne-X.
; ----------------------------------------------------------------


.include "msxbios.s"
.include "applicationsettings.s"
.include "printinterface.s"
.include "rammapper_h.s"
.include "mnemosyne-x_h.s"

.globl _rnd16
.globl _standardLoad
.globl _standardSave

.globl	__PutP0
.globl	__PutP1
.globl	__PutP2

.globl	__GetP0
.globl	__GetP1
.globl	__GetP2
.globl	__GetP3


; ----------------------------------------------------------------
;	- General Settings
; ----------------------------------------------------------------
MNEMO_MAPPER_DEVICE_ID				= 4									; always 4 (memory mapper)


; ----------------------------------------------------------------
;	- Derivative Configuration.
; ----------------------------------------------------------------
MNEMO_SEGHDR_LOGSEGNUMBER			= MNEMO_MAIN_SWAP_PAGE_ADDR + MNEMO_SEGHDROFFSET_LOGSEGNUMBER
MNEMO_SEGHDR_SEGMODE				= MNEMO_MAIN_SWAP_PAGE_ADDR + MNEMO_SEGHDROFFSET_SEGMODE
MNEMO_SEGHDR_PSAVESEG				= MNEMO_MAIN_SWAP_PAGE_ADDR + MNEMO_SEGHDROFFSET_PSAVESEG

MNEMO_MAX_PSEGHANDLE				= MNEMO_AUX_SWAP_PAGE_ADDR + MNEMO_MAX_PHYSICAL_SEGMENTS * 2


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

