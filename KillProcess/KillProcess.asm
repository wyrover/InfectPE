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

.const
SeDebugName		db	'SeDebugPrivilege',0
szText			db	'All the processes has been terminated.',0
szCaption		db	'lazy_cat',0
szAppName 		db	'main',0
szKeyCounts		db	'ProcessCounts',0
szKeyName		db	'ProcessName',0
szSleep			db	'SleepMilliseconds',0
szIni			db	'\KillProcess.ini',0

.data?
szIniPath		db	256	dup (0)
szProcesses		db	512	dup (0)
dwCount			dd	0
dwMilliseconds 		dd	0

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
			
			; Read config file.
			invoke	GetCurrentDirectory,256,offset szIniPath
			invoke	_imp__strcat,offset szIniPath,offset szIni
			invoke	GetPrivateProfileInt,offset szAppName,offset szKeyCounts,0,offset szIniPath
			or	eax,eax
			jz	exit
			mov	dwCount,eax
			invoke	GetPrivateProfileInt,offset szAppName,offset szSleep,0,offset szIniPath
			mov	dwMilliseconds,eax
			invoke	GetPrivateProfileString,offset szAppName,offset szKeyName,NULL,offset szProcesses,sizeof szProcesses,offset szIniPath
			; Replace ',' with 0
			lea	esi,szProcesses
			or	ecx,0FFFFFFFFh
			mov	al,','
		replace:
			cmp	BYTE PTR [esi],al
			jnz	@F
			mov	BYTE PTR [esi],0
		@@:
			inc	esi
			cmp	BYTE PTR [esi],0
			jnz	replace
			; Kill them.
			mov	ecx,dwCount
			lea	esi,szProcesses
			.while	ecx
				push	ecx
				.while	1
					push	esi
					call	GetProcessIdByName
					.break	.if	eax == 0
					invoke	OpenProcess,PROCESS_ALL_ACCESS,NULL,eax
					invoke	TerminateProcess,eax,0
					invoke	Sleep,dwMilliseconds
				.endw
				invoke	_imp__strlen,esi
				inc	eax
				add	esi,eax
				pop	ecx
				dec	ecx
			.endw
			invoke	MessageBox,NULL,addr szText,addr szCaption,MB_ICONINFORMATION
		exit:
			invoke	ExitProcess,0
start			endp
end			start