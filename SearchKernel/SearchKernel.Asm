.586
.model	flat,stdcall
option	casemap:none

include		windows.inc

.data
hKernel		dd	0	; kernel32.dll模块句柄

szLoadLibrary	db	'LoadLibraryA',0
pLoadLibraryA	dd	0

szGetProcAddr	db	'GetProcAddress',0	
pGetProcAddress	dd	0

szUser32	db	'user32.dll',0
hUser32		dd	0

szMessage	db	'MessageBoxA',0
pMessageBpx	dd	0

szText		db	'This is just a test.',0
szCaption	db	'lazy_cat',0



.code

; 字符串比较
pe_strcmp		proc	string1:PTR BYTE, string2:PTR BYTE
			pushad
			mov	esi,string1
			mov	edi,string2
			.while	TRUE
				mov	al,byte ptr [esi]
				mov	ah,byte ptr [edi]
				.if	al != ah
					popad
					mov	eax,FALSE
					ret
				.endif
				.break	.if	al == 0
				inc	esi
				inc	edi
			.endw
			popad
			mov	eax,TRUE
			ret
pe_strcmp		endp


; 从Kernel32.dll的导出表中搜索LoadLibraryA和GetProcAddress地址
FindBaseFuncAddress	proc	@hKernel:DWORD, @pLoadLibraryA:ptr DWORD, @pGetProcAddress:ptr DWORD
			LOCAL	nShouldFound:BYTE
			pushad
			mov	nShouldFound,2
			mov	edi,@hKernel
			assume	edi:ptr IMAGE_DOS_HEADER
			mov	edi,[edi].e_lfanew
			add	edi,@hKernel
			assume	edi:ptr IMAGE_NT_HEADERS
			add	edi,18h
			assume	edi:ptr IMAGE_OPTIONAL_HEADER
			lea	edi,[edi].DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT]
			assume	edi:ptr IMAGE_DATA_DIRECTORY
			mov	edi,[edi].VirtualAddress
			add	edi,@hKernel
			assume	edi:ptr IMAGE_EXPORT_DIRECTORY
			mov	ecx,[edi].NumberOfNames
			mov	esi,[edi].AddressOfFunctions
			add	esi,@hKernel ; 函数地址数组
			mov	edi,[edi].AddressOfNames
			add	edi,@hKernel ; 函数名称数组
			.while	ecx
				mov	ebx,dword ptr [edi]
				add	ebx,@hKernel
				mov	edx,@pLoadLibraryA
				mov	edx,dword ptr [edx]
				.if	!edx
					invoke	pe_strcmp,addr szLoadLibrary,ebx
					.if	eax
						mov	eax,dword ptr[esi]
						add	eax,@hKernel
						mov	edx,@pLoadLibraryA
						mov	dword ptr[edx],eax
						mov	dl,nShouldFound
						dec	dl
						mov	nShouldFound,dl
					.endif
				.endif
				
				mov	edx,@pGetProcAddress
				mov	edx,dword ptr [edx]
				.if	!edx
					invoke	pe_strcmp,addr szGetProcAddr,ebx
					.if	eax
						mov	eax,dword ptr[esi]
						add	eax,@hKernel
						mov	edx,@pGetProcAddress
						mov	dword ptr[edx],eax
						mov	dl,nShouldFound
						dec	dl
						mov	nShouldFound,dl
					.endif
				.endif
				.break	.if	nShouldFound == 0
				add	edi,4
				add	esi,4
				dec	ecx
			.endw			
			popad
			ret
FindBaseFuncAddress 	endp

; 定位Kernel32.dll模块句柄
FindKernel32Base	proc	dwESP:DWORD
			mov	eax,dwESP
			and	eax,0FFFF0000h
			.while	eax
				.if	WORD PTR [eax] == 5A4Dh
					mov	ebx,eax
					assume	ebx:PTR IMAGE_DOS_HEADER
					mov	ebx,[ebx].e_lfanew
					add	ebx,eax
					.if	DWORD PTR [ebx] == 4550h
						ret
					.endif	
				.endif
				sub	eax,10000h
				.break	.if	eax < 70000000h
			.endw
			xor	eax,eax
			ret
FindKernel32Base 	endp

start			proc
			mov	eax,[esp]
			invoke	FindKernel32Base,eax
			.if	eax
				mov	hKernel,eax
			.endif
			invoke	FindBaseFuncAddress,hKernel,addr pLoadLibraryA,addr pGetProcAddress
			push	offset szUser32
			call	pLoadLibraryA
			mov	hUser32,eax
			push	offset szMessage
			push	eax
			call	pGetProcAddress
			mov	pMessageBpx,eax
			push	0
			push	offset szCaption
			push	offset szText
			push	0
			call	pMessageBpx
			ret
start 			endp
end			start