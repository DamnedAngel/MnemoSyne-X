;----------------------------------------------------------
;		msxdosovl.s - by Danilo Angelo, 2020-2023
;
;		MnemoSyne-X MDO
;----------------------------------------------------------

	.include "MSX/BIOS/msxbios.s"
	.include "targetconfig.s"
	.include "applicationsettings.s"
	.include "printinterface.s"

	.area	_CODE

; ----------------------------------------------------------
;	This is the custom initialization function for your C MDO.
;	Invoked when the MDO is loaded.
_initialize::
    print	_initializemsg
	ret

; ----------------------------------------------------------
;	This is the custom finalization function for your C MDO!
;	Invoked when the MDO is unloaded.
_finalize::
    print	_finalizemsg
	ret

; ----------------------------------------------------------
;	This is the custom activation function for your C MDO!
;	Invoked when the MDO is linked.
_activate::
    print	_activatemsg
	ret

; ----------------------------------------------------------
;	This is the custom deactivation function for your C MDO!
;	Invoked when the MDO is unlinked.
_deactivate::
    print	_deactivatemsg
	ret

; ----------------------------------------------------------
;	Messages
_initializemsg::
.asciz		"MnemoSyne-X MDO initialized!\r\n"
_finalizemsg::
.ascii		"MnemoSyne-X MDO finalized!\r\n\0"
_activatemsg::
.ascii		"MnemoSyne-X MDO activated!\r\n\0"
_deactivatemsg::
.ascii		"MnemoSyne-X MDO deactivated!\r\n\0"
