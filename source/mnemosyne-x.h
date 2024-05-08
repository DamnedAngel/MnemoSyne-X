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
;	- [MNEMO_PRIMARY_MAPPER_ONLY = 1] None
;	- [MNEMO_PRIMARY_MAPPER_ONLY = 0] bool primaryMapperOnly
;			false = All mappers
;			true  = Primary mapper only
;
; OUTPUTS:
;   - unsigned char:  0 = Success
; ----------------------------------------------------------------
*/
#ifdef MNEMO_PRIMARY_MAPPER_ONLY
extern void mnemo_init(void) __sdcccall(1);
#else
extern unsigned char mnemo_init(bool) __sdcccall(1);
#endif

/*
; ----------------------------------------------------------------
;	- Finalize MnemoSyne-X.
; ----------------------------------------------------------------
; INPUTS:
;	- None
;
; OUTPUTS:
;   -None
; ----------------------------------------------------------------
*/
extern void mnemo_finalize(void) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Set a bank to standard persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number
;
; OUTPUTS:
;	- None
; ----------------------------------------------------------------
*/
extern void mnemo_setStdPersistence(unsigned char) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Set bank persistence
; ----------------------------------------------------------------
; INPUTS:
;	- A: Bank number
;	- DE: pLoadSeg
;   - Stack: pSaveSeg
;
; OUTPUTS:
;	- None
;
; CHANGES:
;   - All regs
; ----------------------------------------------------------------
*/
extern void mnemo_setPersistence(unsigned char, unsigned int*, unsigned int*) __sdcccall(1);


/*
; ----------------------------------------------------------------
;	- Activates a logical segment
; ----------------------------------------------------------------
; INPUTS:
;	- HL: pointer to logical segment handler
;
; OUTPUTS:
;   - A:  0 = Success
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
;   - A:  0 = Success
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
;   - None
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
;   - A: Error code
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
; ----------------------------------------------------------------
*/
extern void mnemo_switchMainPage(LOGSEGHANDLER*) __sdcccall(1);


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
