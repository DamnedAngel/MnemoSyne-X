/*
; ----------------------------------------------------------------
;	mnemosyne-x,h
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

#include "rammapper.h"

typedef unsigned char (*LoadSeg) (unsigned page, unsigned int logSeg);
typedef unsigned char (*SaveSeg) (unsigned page);

typedef struct {
	SEGHANDLER segHandler;
	unsigned int logSegNumber;
	unsigned char mode;
	LoadSeg loadSeg;
	SaveSeg saveSeg;
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
extern void initMnemosyneX(void) __sdcccall(1);
#else
extern unsigned char initMnemosyneX(bool) __sdcccall(1);
#endif

/*
; ----------------------------------------------------------------
;	- Activates a logical segment in a segment
; ----------------------------------------------------------------
; INPUTS:
;	- LOGSEGHANDLER* pLogSegHandler: pointer to logical segment handler
;
; OUTPUTS:
;   - unsigned char:	0 = success
; ----------------------------------------------------------------
*/
unsigned char activateLogSeg (LOGSEGHANDLER* pLogSegHandler) __sdcccall(1);

/*
; ----------------------------------------------------------------
;	- Releases a segment related to a logical segment number
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char priority: Release priority (0 - 2)
;	- unsigned int* logSegNumber: logical segment number
;
; OUTPUTS:
;   - None
; ----------------------------------------------------------------
*/
void releaseSeg(unsigned char priority, SEGHANDLER* pSegHandler) __sdcccall(1);

/*
; ----------------------------------------------------------------
;	- Releases a segment from a logical segment handler
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char priority: Release priority (0 - 2)
;	- LOGSEGHANDLER* pLogSegHandler: pointer to logical segment handler
;
; OUTPUTS:
;   - None
; ----------------------------------------------------------------
*/
void releaseLogSeg (unsigned char priority, LOGSEGHANDLER* pSDPHandler) __sdcccall(1);

#endif	//  ____MNEMOSYNEX_H__
