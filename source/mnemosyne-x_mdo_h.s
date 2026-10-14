; ----------------------------------------------------------------
;	mnemosyne-x_mdo_h.s
; ----------------------------------------------------------------
;	261014 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the asm headers for programs and MDOs that
;	call MnemoSyne-X through MDO hooks (MnemoSyne-X in an MDO).
;	Programs linked together with MnemoSyne-X include
;	mnemosyne-x_h.s instead.
;
;	The project that links the MnenoSyne-X library must declare
;   all MnemoSyne-X hooks in its MDOSettings.txt
;   (see README, "Using MnemoSyne-X in an MDO"); 
;   Child MDOs inherit them from the parent.
;
;	For the routines' parameters signature, please refer to 
;	documentation in mnemosyne-x_h.s.
; ----------------------------------------------------------------

.include "mnemosyne-x_general_h.s"


; Init MnemoSyne-X
.globl _mnemo_init_hook

; Finalize MnemoSyne-X
.globl _mnemo_finalize_hook


; Set a bank to standard persistence
.globl _mnemo_setStdPersistence_hook

; Set bank persistence
.globl _mnemo_setPersistence_hook


; Activates a logical segment
.globl _mnemo_activateLogSeg_hook

; Releases segment from a logSegHandler pointed by DE (SDCCCALL(1))
.globl _mnemo_releaseLogSeg_hook

; Releases segment from a logSegHandler pointed by HL
.globl _mnemo_releaseLogSegHL_hook

; Releases all active segments
.globl _mnemo_releaseAll_hook

; Flushes all pending, released segments to disk
.globl _mnemo_flushAll_hook


; Enable a segment from a Segment Handler in aux page
.globl _mnemo_switchAuxPage_hook

; Enable a segment from a Segment Handler in main page
.globl _mnemo_switchMainPage_hook

; Get slot ID of a page
.globl _mnemo_getSlot_hook

; Get the physical segment mapped in the aux page
.globl _mnemo_getAuxPage_hook

; Get the physical segment mapped in the main page
.globl _mnemo_getMainPage_hook


; Get number of Managed Physical Segments
.globl _mnemo_getManagedSegments_hook

; Get number of Used Managed Physical Segments
.globl _mnemo_getUsedSegments_hook

; Get number of Free Managed Physical Segments
.globl _mnemo_getFreeSegments_hook
