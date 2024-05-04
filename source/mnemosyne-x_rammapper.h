/*
;----------------------------------------------------------
;		mnemosyne-x_rammapper.h
; ----------------------------------------------------------
;		240113 - danilo angelo
; ----------------------------------------------------------
;		Header for basic mapper routines.
;
;       This file is HEAVILY based on
;		FUSION-C's rammapper.s, by
;       Eric Boez &  Fernando Garcia
;		(Bitvision, 2018)
;		https://github.com/ericb59/FUSION-C-1.3
;----------------------------------------------------------
*/

#ifndef  __RAMMAPPER_H__
#define  __RAMMAPPER_H__

typedef struct {
	unsigned char slot;
	unsigned char numberOfSegments;
	unsigned char numberOfFreeSegments;
	unsigned char numberOfSystemSegments;
	unsigned char numberOfUserSegments;
	unsigned char notInUse0;
	unsigned char notInUse1;	
	unsigned char notInUse2;	
} MAPPERINFOBLOCK;


typedef struct {
	unsigned char segNumber;		// 0 if failed
	unsigned char mapperSlot;		// 0 if called as B=0, or failed
} SEGHANDLER;

/*
; ----------------------------------------------------------------
; - Init Mapper Data Structures
; ----------------------------------------------------------------
; INPUTS:
;	- Unsigned char deviceId
;
;	DeviceId:
;		00h  reserved for broadcasts
;		04h  DOS2 memory routines(USUALLY THIS!)
;		08h  RS232
;		0Ah  MSX - AUDIO
;		11h  Kanji
;		22h  UNAPI(konamiman)
;		4Dh  Memman
;		FFh  System exclusive
;
; OUTPUTS:
;   -None.
; ----------------------------------------------------------------
*/
extern void	InitRamMapperInfo( unsigned char deviceId );

/*
; ----------------------------------------------------------------
; - Get pointer to mapper base table
; ----------------------------------------------------------------
; INPUTS:
;	-None.
;
; OUTPUTS:
;	-Pointer to MAPPERINFOBLOCK
; ----------------------------------------------------------------
*/
extern MAPPERINFOBLOCK *GetRamMapperBaseTable( void );

/*
; ----------------------------------------------------------------
; - Allocate Mapper Segment
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char segmentType
;	- unsigned char slotAddress (and Allocation Strategy)
;
;	segmentType :
;		0	User segment
;		1	System segment
;
;	slotAddress (and Allocation Strategy)
;		0			Allocate primary mapper
;		F0xxSSPP:
;			PP		Primary slot
;			SS		Secondary slot
;			xx:
;				00	Allocate specified slot only
;               01	Allocate other slots than specified
;               10	Try to allocate specified slot and, if it failed, try another slot(if any)
;               11	Try to allocate other slots than specified and, if it failed, try specified slot
;			F		Slot Expanded Flag
;
; OUTPUTS:
;	- unsigned int F000SSPP yyyyyyyy
;		yyyyyyyy	Segment Number (0 if failed)
;		F000SSPP	Mapper slot address (0 if called as B = 0, or failed)
; ----------------------------------------------------------------
*/
extern unsigned int	AllocateSegment( unsigned char segmentType, unsigned char slotAddress );


/*
; ----------------------------------------------------------------
; - Free Mapper Segment
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char segmentNumber
;	- unsigned char slotAddress
;
;	slotAddress:
;		0	Primary mapper
;		>0	Other mapper
;
; OUTPUTS:
;	- bool Success
; ----------------------------------------------------------------
*/
extern unsigned char FreeSegment( unsigned char segmentNumber, unsigned char slotAddress );

/*
; ----------------------------------------------------------------
; - Get Segment Number of a Memory page
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char page (0-3)
;
; OUTPUTS:
;	- unsigned char Segment number
; ----------------------------------------------------------------
*/
extern unsigned char		Get_PN ( unsigned char page );

/*
; ----------------------------------------------------------------
; - Get Segment Number in Memory page
; ----------------------------------------------------------------
; INPUTS:
;	- unsigned char segment
;	- unsigned char page (0-3)
;
; OUTPUTS:
;	- None.
; ----------------------------------------------------------------
*/
extern void					Put_PN ( unsigned char segment, unsigned char page);

#endif
