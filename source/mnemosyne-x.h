/*
; ----------------------------------------------------------------
;	mnemosyne-x.h
; ----------------------------------------------------------------
;	240123 - DamnedAngel
; ----------------------------------------------------------------
;	MnemoSyne-X: a virtual memory system for MSX.
;	This file contains the C headers for integrating MnemoSyne-X.
; ----------------------------------------------------------------
*/

#ifndef  __MNEMOSYNEX_H__							
#define  __MNEMOSYNEX_H__

#include "stdbool.h"
#include "mnemosyne-x_rammapper.h"

#define				MNEMO_ALLOC_MASK			0b00110000
#define				MNEMO_SEGMODE_TEMP			0
#define				MNEMO_SEGMODE_READ			1
#define				MNEMO_SEGMODE_FORCEDREAD	2
#define				MNEMO_SEGMODE_READWRITE		3

#define				MNEMO_ALLOC_KEEPPRIORITY0	0b00000000	// lowest priority
#define				MNEMO_ALLOC_KEEPPRIORITY1	0b00010000
#define				MNEMO_ALLOC_KEEPPRIORITY2	0b00100000	// highest priority

typedef struct {
	SEGHANDLER segHandler;
	SEGHANDLER* pSegHandler;
	void* pLogSegTableItem;
	unsigned int logSegNumber;
	unsigned char segMode;
} LOGSEGHANDLER;

/*
; ----------------------------------------------------------------
;	- Init MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- bool primaryMapperOnly
;			false = All mappers
;			true  = Primary mapper only
;			(ignored if MNEMO_PRIMARY_MAPPER_ONLY = 1)
;	- char*: databanks filename: up to 8 characters; a shorter name
;			ends at its first space or zero (8 bytes are read)
;
; OUTPUTS:
;   - unsigned char:  0 = Success
;			MNEMO_ERROR_BADFILENAME = The databanks filename is empty
;			(it starts with a space or a zero)
; ----------------------------------------------------------------
*/
extern unsigned char mnemo_init(bool primaryMapperOnly, char* databankName) __sdcccall(1);

/*
; ----------------------------------------------------------------
;	- Finalize MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - unsigned char:  0 = Success
;			The error of the flush of the pending segments (see
;			mnemo_flushAll), or else MNEMO_ERROR_FILECLOSEFAIL. The
;			shutdown is always completed: the segments that were not
;			flushed are lost
; ----------------------------------------------------------------
*/
extern unsigned char mnemo_finalize(void) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Set a bank to standard persistence
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char bank: Bank number (0 to MNEMO_INDEX_SEGMENTS * 32 - 1)
;
; OUTPUTS:
;	- unsigned char:  0 = Success
;			MNEMO_ERROR_BADBANK = The bank number is out of range
; ----------------------------------------------------------------
*/
extern unsigned char mnemo_setStdPersistence(unsigned char bank) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Set bank persistence
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char bank: Bank number (0 to MNEMO_INDEX_SEGMENTS * 32 - 1)
;	- MNEMO_LOADSEG pLoadSeg: routine that loads a segment
;	- MNEMO_SAVESEG pSaveSeg: routine that saves a segment
;
; OUTPUTS:
;	- unsigned char:  0 = Success
;			MNEMO_ERROR_BADBANK = The bank number is out of range; nothing
;			was changed
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
*/
typedef unsigned char (*MNEMO_LOADSEG)(void) __sdcccall(1);
typedef unsigned char (*MNEMO_SAVESEG)(unsigned char checkBank) __sdcccall(1);
extern unsigned char mnemo_setPersistence(unsigned char bank, MNEMO_LOADSEG pLoadSeg, MNEMO_SAVESEG pSaveSeg) __sdcccall(1);


/*
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
; ----------------------------------------------------------------
*/
extern unsigned char mnemo_activateLogSeg (LOGSEGHANDLER* pLogSegHandler) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Releases segment from a logSegHandler
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;	- DE: pointer to logical segment handler
;
; OUTPUTS:
;   - A:  0 = Success: the segment is released and the handler is
;			invalidated (its pSegHandler = 0xFFFF)
;		  MNEMO_WARN_OUTDATEDPSEGHANDLER = The handler does not hold an
;		  active segment (invalidated, never activated, released by
;		  mnemo_releaseAll, or reused): nothing was changed
; ----------------------------------------------------------------
*/
extern unsigned char mnemo_releaseLogSeg(unsigned char priority, LOGSEGHANDLER* pSegHandler) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Releases all active segments
; ----------------------------------------------------------------
; INPUTS:
;	- A: Release priority (0 - 2)
;
; OUTPUTS:
;   - None. The handlers of the released segments are not invalidated:
;	  they must not be released afterwards
; ----------------------------------------------------------------
*/
extern void mnemo_releaseAll(unsigned char priority) __sdcccall(1);


/*
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
;   Active segments are not flushed: only the released ones. The AUX
;   and MAIN pages are restored
; ----------------------------------------------------------------
*/
extern unsigned char mnemo_flushAll(void) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Enable a segment from a Segment Handler in aux page
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to Segment handler
;
; OUTPUTS:
;   - None
;
; NOTES:
;   - Interrupts disabled if a slot change was needed
; ----------------------------------------------------------------
*/
extern void mnemo_switchAuxPage(LOGSEGHANDLER*) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Enable a segment from a Segment Handler in main page
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to Segment handler
;
; OUTPUTS:
;   - None
;
; NOTES:
;   - Interrupts disabled if a slot change was needed
; ----------------------------------------------------------------
*/
extern void mnemo_switchMainPage(LOGSEGHANDLER*) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Get slot ID of a page
; ----------------------------------------------------------------
; INPUTS:
;	- A: page (0-3)
;
; OUTPUTS:
;   - A: slot ID formatted F000SSPP
; ----------------------------------------------------------------
*/
extern unsigned char mnemo_getSlot(unsigned char page) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Get the physical segment mapped in the aux page
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: SEGHANDLER of the current AUX page mapping
;		  (low byte: segment number, high byte: slot ID)
; ----------------------------------------------------------------
*/
extern unsigned int mnemo_getAuxPage(void) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Get the physical segment mapped in the main page
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: SEGHANDLER of the current MAIN page mapping
;		  (low byte: segment number, high byte: slot ID)
; ----------------------------------------------------------------
*/
extern unsigned int mnemo_getMainPage(void) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Get number of Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: number of Managed Physical Segments
; ----------------------------------------------------------------
*/
extern unsigned int mnemo_getManagedSegments(void) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Get number of Used Managed Physical Segments
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   - DE: number of Used Managed Physical Segments
; ----------------------------------------------------------------
*/
extern unsigned int mnemo_getUsedSegments(void) __sdcccall(1);


/*
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
*/
extern unsigned int mnemo_getFreeSegments(void) __sdcccall(1);


#endif	//  ____MNEMOSYNEX_H__
