;----------------------------------------------------------
;	mnemosyne-x_rammapper_h
; ----------------------------------------------------------
;	240114 - DamnedAngel
; ----------------------------------------------------------
;	Support basic mapper routines.
;----------------------------------------------------------

; ----------------------------------------------------------------
; - Init Mapper Data Structures
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Device Id
;	- [__SDCCCALL(1)] a:	Device Id
;
;	DeviceId:
;		00h  reserved for broadcasts
;		04h  DOS2 memory routines (USUALLY THIS!)
;		08h  RS232
;		0Ah  MSX-AUDIO
;		11h  Kanji
;		22h  UNAPI (konamiman)
;		4Dh  Memman
;		FFh  System exclusive
; OUTPUTS:
;   - None.
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _InitRamMapperInfo

; ----------------------------------------------------------------
; - Get pointer to mapper base table
; ----------------------------------------------------------------
; INPUTS:
;	- None.
; OUTPUTS:
;	- [__SDCCCALL(0)] hl:	Pointer to mapper base table
;	- [__SDCCCALL(1)] de:	Pointer to mapper base table
; CHANGES:
;   - hl, de (__SDCCCALL(1) only)
; ----------------------------------------------------------------
.globl _GetRamMapperBaseTable

; ----------------------------------------------------------------
; - Allocate Mapper Segment
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Segment Type
;	- [__SDCCCALL(0)] SP+3: Slot Address and Allocation Strategy
;	- [__SDCCCALL(1)] a:	Segment Type
;	- [__SDCCCALL(1)] l:	Slot Address and Allocation Strategy
;
;	Segment Type:
;		0	User segment
;		1	System segment
;
;	Slot Address and Allocation Strategy
;		0			Allocate primary mapper
;		F0xxSSPP:
;			PP		Primary slot
;			SS		Secondary slot
;			xx:
;				00	Allocate specified slot only
;               01	Allocate other slots than specified
;               10	Try to allocate specified slot and, if it failed, try another slot (if any)
;               11	Try to allocate other slots than specified and, if it failed, try specified slot
;			F		Slot Expanded Flag
; OUTPUTS:
;	- [__SDCCCALL(0)] hl:	F000SSPP yyyyyyyy
;	- [__SDCCCALL(1)] de:	F000SSPP yyyyyyyy
;		yyyyyyyy	Segment Number	(0 if failed)
;		F000SSPP	Mapper slot address (0 if called as B=0, or failed)
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _AllocateSegment

; ----------------------------------------------------------------
; - Free Mapper Segment
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Segment Number
;	- [__SDCCCALL(0)] SP+3: Mapper Slot Address
;	- [__SDCCCALL(1)] a:	Segment Number
;	- [__SDCCCALL(1)] l:	Mapper Slot Address
;
;	Mapper Slot Address:
;		0	Primary mapper
;		>0	Other mapper
;
; OUTPUTS:
;	- [__SDCCCALL(0)] a:	Success
;	- [__SDCCCALL(1)] l:	Success
;
;	Success:
;		0	False, fail
;		1	True, success
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _FreeSegment

; ----------------------------------------------------------------
; - Get Segment Number of a Memory page
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Memory Page (0-3)
;	- [__SDCCCALL(1)] a:	Memory Page (0-3)
;
; OUTPUTS:
;	- [__SDCCCALL(0)] a:	Segment number
;	- [__SDCCCALL(1)] l:	Segment number
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _Get_PN

; ----------------------------------------------------------------
; - Put Segment Number in Memory page
; ----------------------------------------------------------------
; INPUTS:
;	- [__SDCCCALL(0)] SP+2: Segment Number
;	- [__SDCCCALL(0)] SP+3: Page
;	- [__SDCCCALL(1)] a:	Segment Number
;	- [__SDCCCALL(1)] l:	Page
;
; OUTPUTS:
;	- None.
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _Put_PN

; ----------------------------------------------------------------
; - Put Segment Number in Memory page (Direct ASM call)
; ----------------------------------------------------------------
; INPUTS:
;	- a:	Segment Number
;	- b:	Page
;
; OUTPUTS:
;	- None.
;
; CHANGES:
;   - All registers
; ----------------------------------------------------------------
.globl _Put_PN_ab

;.globl _rammapper_table


; BIOS CALLS
.globl __Allocate
.globl __Free
.globl __Read
.globl __Write
.globl __Call_Seg
.globl __Calls
.globl __PutPH
.globl __GetPH
.globl __PutP0
.globl __GetP0
.globl __PutP1
.globl __GetP1
.globl __PutP2
.globl __GetP2
.globl __PutP3
.globl __GetP3
