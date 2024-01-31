//-------------------------------------------------
// mdointerface.h created automatically
// by make.bat
// on 09:18:40, 2024-01-31
//
// DO NOT BOTHER EDITING THIS.
// ALL CHANGES WILL BE LOST.
//-------------------------------------------------

#ifndef  __MDOINTERFACE_H__
#define  __MDOINTERFACE_H__

#ifdef MDO_SUPPORT

#include "mdostructures.h"

extern unsigned char mdoLoad (mdoHandler*);
extern unsigned char mdoRelease (mdoHandler*);
extern unsigned char mdoLink (mdoHandler*);
extern unsigned char mdoUnlink (mdoHandler*);


#endif	//  MDO_SUPPORT

#endif	//  __MDOINTERFACE_H__

