// ----------------------------------------------------------
//		msxdosapp.c - by Danilo Angelo, 2020 - 2023
//
//		MSX - DOS program example
//		C version
// ----------------------------------------------------------

#include "MSX/BIOS/msxbios.h"
#include "targetconfig.h"
#include "applicationsettings.h"
#include "printinterface.h"
#include "printdec.h"
#include "mnemosyne-x.h"

LOGSEGHANDLER seg0, seg1, seg2;

#define 			Poke( address, data )	( *( (volatile unsigned char*)(address) ) = ( (unsigned char)(data) ) )
#define 			Pokew( address, data )	( *( (volatile unsigned int*)(address) ) = ( (unsigned int)(data) ) )
#define 			Peek( address )			( *( (volatile unsigned char*)(address) ) )
#define 			Peekw( address )		( *( (volatile unsigned int*)(address) ) )


#define 			MNEMO_MAIN_SWAP_PAGE_ADDR	0x8000
#define				MNEMO_MAIN_SEGPAYLOAD		MNEMO_MAIN_SWAP_PAGE_ADDR + 16

#define 			TEST_SEGMENTS				512
#define 			FIRST_TEST_SEGMENT			2048
#define 			LAST_TEST_SEGMENT			4096
#define				TEST_RANGE					(LAST_TEST_SEGMENT - FIRST_TEST_SEGMENT + 1)

extern unsigned int rnd16(void);

unsigned char b[(((unsigned int)TEST_RANGE) / 8) + 1];

void setFlag(unsigned int i) {
	unsigned int index = i / 8;
	unsigned int offset = i % 8;
	b[index] |= 1 << offset;
}

void resetFlag(unsigned int i) {
	unsigned int index = i / 8;
	unsigned int offset = i % 8;
	b[index] &= !(1 << offset);
}

bool getFlag(unsigned int i) {
	unsigned int index = i / 8;
	unsigned int offset = i % 8;
	return ((b[index] & (1 << offset)) > 0);
}

// ----------------------------------------------------------
// Generic example of using MnemoSyne-X.
// ----------------------------------------------------------

void printManagedSegs(void) {
	unsigned int ts = mnemo_getManagedSegments();
	print(" - Managed segments: \0");
	PrintDec(ts);
	print("\r\n\0");
}

void printUsedSegs(void) {
	unsigned int ts = mnemo_getUsedSegments();
	print(" - Used segments: \0");
	PrintDec(ts);
	print("\r\n\0");
}

void printFreeSegs(void) {
	unsigned int ts = mnemo_getFreeSegments();
	print(" - Free segments: \0");
	PrintDec(ts);
	print("\r\n\0");
}

void useMnemoSyneX(void) {
	// ----------------------------------------------------------
	// Use MnemoSyne-X
	// ----------------------------------------------------------

	mnemo_init(false, "MNEMOSYN");
	printManagedSegs();
	printFreeSegs();

	// activate segment 1024
	print("Activating seg. 1024.\r\n\0");
	seg0.logSegNumber = 1024;
	seg0.segMode = MNEMO_SEGMODE_READWRITE;
	mnemo_activateLogSeg(&seg0);
	Pokew(MNEMO_MAIN_SEGPAYLOAD, 1024);
	printFreeSegs();

	// activate segment 1025
	print("Activating seg. 1025.\r\n\0");
	seg1.logSegNumber = 1025;
	seg1.segMode = MNEMO_SEGMODE_READWRITE;
	mnemo_activateLogSeg(&seg1);
	Pokew(MNEMO_MAIN_SEGPAYLOAD, 1025);
	printFreeSegs();

	// switch back to segment 1024
	print("Switching back to seg. 1024.\r\n\0");
	mnemo_switchMainPage(&seg0);
	print("Signature: \0");
	PrintDec(Peekw(MNEMO_MAIN_SEGPAYLOAD));
	print("\r\n\0");

	// release segment 1024
	print("Releasing seg. 1024.\r\n\0");
	mnemo_releaseLogSeg(MNEMO_ALLOC_KEEPPRIORITY2, &seg0);
	printFreeSegs();

	// activate segment 1026
	print("Activating seg. 1026.\r\n\0");
	seg2.logSegNumber = 1026;
	seg2.segMode = MNEMO_SEGMODE_READWRITE;
	mnemo_activateLogSeg(&seg2);
	Pokew(MNEMO_MAIN_SEGPAYLOAD, 1026);
	printFreeSegs();

	// release all segments
	print("Releasing all segs.\r\n\0");
	mnemo_releaseAll(MNEMO_ALLOC_KEEPPRIORITY0);
	printFreeSegs();

	// Flush all segments
	print("Flushing all segs.\r\n\0");
	mnemo_flushAll();
	printFreeSegs();

	print("-------------------\r\n\0");
	print("--- STRESS TEST ---\r\n\0");
	print("-------------------\r\n\0");

	unsigned char e;

	for (unsigned int i = 0; i <= (((unsigned int)TEST_RANGE) / 8); i++) {
		b[i] = 0;
	}

	unsigned int mask = 0;
	unsigned int ts = TEST_RANGE - 1;
	while (ts) {
		mask = (mask << 1) + 1;
		ts = ts >> 1;
	}

	print("Allocating segments...\r\n\0");

	for (int i = 0; i < TEST_SEGMENTS; i++) {
		unsigned int rw;
		do {
			rw = rnd16() & mask;
		} while (rw >= TEST_RANGE);
		unsigned int lsn = rw + FIRST_TEST_SEGMENT;
		unsigned char rb = ((unsigned char)(rnd16())) & MNEMO_ALLOC_MASK;

		seg0.logSegNumber = lsn;
		seg0.segMode = MNEMO_SEGMODE_READWRITE;
		e = mnemo_activateLogSeg(&seg0);
		if (e > 1) {
			//			PrintDec(lsn);
			print(" - Act. Error (1) \0");
			PrintDec(((unsigned int)e));
			print("\r\n\0");
		}
		else {
			setFlag(rw);
			Pokew(MNEMO_MAIN_SEGPAYLOAD, lsn);
			e = mnemo_releaseLogSeg(MNEMO_ALLOC_KEEPPRIORITY1, &seg0);
			if (e > 1) {
				PrintDec(lsn);
				print(" - Rel. Error \0");
				PrintDec(((unsigned int)e));
				print("\r\n\0");
			}
		}


		if ((i & 15) == 15) {
			PrintDec(i + 1);
			print("\r\0");
		}
	}
	print("\r\n\0");

	print("Releasing all segments...\r\n\0");
	mnemo_releaseAll(0x10);
	print("Flushing all segments...\r\n\0");
	mnemo_flushAll();
	printFreeSegs();


	print("Testing segments...\r\n\0");

	unsigned int errors = 0;
	unsigned int segc = 0;
	for (unsigned int lsn = FIRST_TEST_SEGMENT; lsn <= LAST_TEST_SEGMENT; lsn++) {
		unsigned int i = lsn - FIRST_TEST_SEGMENT;
		if (getFlag(i)) {
			segc++;
			seg0.logSegNumber = lsn;
			seg0.segMode = MNEMO_SEGMODE_READ;
			e = mnemo_activateLogSeg(&seg0);
			if (e) {
				PrintDec(lsn);
				print(" - Act. Error (2) \0");
				PrintDec(((unsigned int)e));
				print("\r\n\0");
			}
			else {
				if (Peekw(MNEMO_MAIN_SEGPAYLOAD) != lsn) {
					errors++;
					PrintDec(lsn);
					print(" - Data Error \0");
					PrintDec(Peekw(MNEMO_MAIN_SEGPAYLOAD));
					print("\r\n\0");
				}
				e = mnemo_releaseLogSeg(1, &seg0);
				if (e) {
					PrintDec(lsn);
					print(" - Rel. Error \0");
					PrintDec(((unsigned int)e));
					print("\r\n\0");
				}
			}
		}

		if ((i & 63) == 63) {
			PrintDec(i + 1);
			print(" - \0");
			PrintDec(segc);
			print("\r\0");
		}
	}

	print("\r\n\0");

	print("-------\r\n Stress test errors: \0");
	PrintDec(errors);
	print("\r\n\-------\r\n\0");


	// activate segment 1024
	print("Activating seg. 1024.\r\n\0");
	seg0.logSegNumber = 1024;
	seg0.segMode = MNEMO_SEGMODE_READ;
	mnemo_activateLogSeg(&seg0);
	print("Signature: \0");
	PrintDec(Peekw(MNEMO_MAIN_SEGPAYLOAD));
	print("\r\n\0");
	printFreeSegs();

	// activate segment 1025
	print("Activating seg. 1025.\r\n\0");
	seg0.logSegNumber = 1025;
	seg0.segMode = MNEMO_SEGMODE_READ;
	mnemo_activateLogSeg(&seg0);
	print("Signature: \0");
	PrintDec(Peekw(MNEMO_MAIN_SEGPAYLOAD));
	print("\r\n\0");
	printFreeSegs();

	// activate segment 1026
	print("Activating seg. 1026.\r\n\0");
	seg0.logSegNumber = 1026;
	seg0.segMode = MNEMO_SEGMODE_READ;
	mnemo_activateLogSeg(&seg0);
	print("Signature: \0");
	PrintDec(Peekw(MNEMO_MAIN_SEGPAYLOAD));
	print("\r\n\0");
	printFreeSegs();

	mnemo_finalize();
}

// ----------------------------------------------------------
//	This is the main function for your C MSX APP!
//
//	Your fun starts here!!!
//	Replace the code below with your art.
// 
//	Note: Only use argv and argc if you enabled
//	CMDLINE_PARAMETERS on TargetConfig_XXXXX.txt
unsigned char main(char** argv, int argc) {
	print("MnemoSyne-X Static Demo app\r\n\0");
	print("Damned Angel - 2024\r\n\0");

#ifdef CMDLINE_PARAMETERS
	print("Parameters:\r\n\0");
	for (int i = 0; i < argc; i++) {
		print(argv[i]);
		print(linefeed);
	}
	print(linefeed);
#endif

	useMnemoSyneX();

#ifdef MDO_SUPPORT
	//	useMDO returns errorcode, but in this
	//  example we will ignore it and return
	//	#0xa0 error code for all MDO errors.
	//  Remove it if you're not using MDOs.
	extern unsigned char useMDO(void);
	if (useMDO()) {
		return 0xa0;
	}
	else {
		return 0;
	}
#else
	return 0;
#endif
}

