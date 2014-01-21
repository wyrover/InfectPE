
// AntiSDTHookDlg.cpp : implementation file
//

#include "stdafx.h"
#include "AntiSDTHook.h"
#include "AntiSDTHookDlg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CAntiSDTHookDlg dialog




CAntiSDTHookDlg::CAntiSDTHookDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CAntiSDTHookDlg::IDD, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
    m_pListCtrl = NULL;
}

void CAntiSDTHookDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAntiSDTHookDlg, CDialog)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
    // add by lazy_cat
    ON_NOTIFY(NM_CUSTOMDRAW, IDC_LIST_SSDT, OnListCtrlDrawItemColor)
	//}}AFX_MSG_MAP
    ON_BN_CLICKED(IDC_BUTTON_RESTORE, &CAntiSDTHookDlg::OnBnClickedButtonRestore)
    ON_BN_CLICKED(IDC_BUTTON_RESTOREALL, &CAntiSDTHookDlg::OnBnClickedButtonRestoreall)
END_MESSAGE_MAP()


// CAntiSDTHookDlg message handlers

BOOL CAntiSDTHookDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon

    // Debug priviledge
    HANDLE hToken;
    OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES,&hToken);
    LUID uid;
    LookupPrivilegeValue(NULL, SE_DEBUG_NAME, &uid);
    TOKEN_PRIVILEGES tp = { 0 };
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    tp.Privileges[0].Luid = uid;
    tp.PrivilegeCount = 1;	
    AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(tp), NULL, NULL);
    CloseHandle(hToken);

    m_pListCtrl = (CListCtrl*)GetDlgItem(IDC_LIST_SSDT);
    m_pListCtrl->SetExtendedStyle(LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);
    struct  {
        TCHAR   *szHeader;
        int     nWidth;
    } stCols[] = { 
        TEXT("SvcNo."), 50, 
        TEXT("Function"), 200,
        TEXT("Address"), 90,
        TEXT("Original Address"), 90,
        TEXT("Module"), 240
    };
    for (int i = 0; i < sizeof(stCols) / sizeof(stCols[0]); i++)
        m_pListCtrl->InsertColumn(i, stCols[i].szHeader, LVCFMT_LEFT, stCols[i].nWidth);

    //
    // Get function name from ntdll.dll
    //
    HMODULE  hNtdll = LoadLibrary(TEXT("ntdll.dll"));
    // Locate to NTDLL.DLL's export table
    PIMAGE_EXPORT_DIRECTORY pExportDirectory = (PIMAGE_EXPORT_DIRECTORY)((BYTE*)hNtdll + ((PIMAGE_OPTIONAL_HEADER)((BYTE*)hNtdll + ((PIMAGE_DOS_HEADER)hNtdll)->e_lfanew + sizeof(DWORD) + sizeof(IMAGE_FILE_HEADER)))->DataDirectory[0].VirtualAddress);
    CHAR    **pNameArray = (CHAR**)((BYTE*)hNtdll + pExportDirectory->AddressOfNames);
    DWORD   *pFuncAddrArray = (DWORD*)((BYTE*)hNtdll + pExportDirectory->AddressOfFunctions);
    USHORT  *pNameOrdTab = (USHORT*)((BYTE*)hNtdll + pExportDirectory->AddressOfNameOrdinals);  // Fuck...
    // Get function names which belongs to SSDT
    for (unsigned int i = 0; i < pExportDirectory->NumberOfNames; i++)
    {
        CHAR *pFuncName = pNameArray[i] + (DWORD)hNtdll;
        if (!strncmp(pFuncName, "Nt", 2))
        {
            DWORD   dwSeviceNumber = *(DWORD*)((DWORD)hNtdll + pFuncAddrArray[pNameOrdTab[i]] + 1);
            if (dwSeviceNumber < (DWORD)0x11C)
            {
                WCHAR   szFuncName[64];
                int     nItemIndex = 0;
                // sort by service number
                for (int k = 0; k < m_pListCtrl->GetItemCount(); k++)
                {
                    m_pListCtrl->GetItemText(k, 0, szFuncName, sizeof(szFuncName));
                    if (dwSeviceNumber < wcstoul(szFuncName, NULL, 16))
                    {
                        nItemIndex = k;
                        break;
                    }
                    else
                    {
                        if (k + 1 >= m_pListCtrl->GetItemCount())
                        {
                            nItemIndex = k + 1;
                            break;
                        }
                        m_pListCtrl->GetItemText(k + 1, 0, szFuncName, sizeof(szFuncName));
                        if (dwSeviceNumber < wcstoul(szFuncName, NULL, 16))
                        {
                            nItemIndex = k + 1;
                            break;
                        }
                    }
                }
                swprintf(szFuncName, 64, TEXT("0x%03X"), dwSeviceNumber);
                m_pListCtrl->InsertItem(nItemIndex, szFuncName);

                MultiByteToWideChar(CP_ACP, 0, pFuncName, strlen(pFuncName) + 1, szFuncName,   
                    sizeof(szFuncName) / sizeof(szFuncName[0]));
                m_pListCtrl->SetItemText(nItemIndex++, 1, szFuncName);
            }
        }
    }
    // Load ntoskenl.exe as DLL
    ZwQuerySystemInformation = (PZWQUERYSYSTEMINFORMATION)GetProcAddress(hNtdll, "ZwQuerySystemInformation");
    ZwSystemDebugControl = (PZWSYSTEMDEBUGCONTROL)GetProcAddress(hNtdll, "ZwSystemDebugControl");

    if (!(ZwQuerySystemInformation && ZwSystemDebugControl))
        MessageBox(TEXT("Cann't locate to ZwQuerySystemInformation or ZwSystemDebugControl."), TEXT("lazy_cat"), MB_ICONSTOP);
    else
    {
        ULONG   ulReturnLength = 0;
        ZwQuerySystemInformation(SystemModuleInformation, NULL, 0, &ulReturnLength);
        PSYSTEM_MODULE_INFORMATION SystemInformation = (PSYSTEM_MODULE_INFORMATION)malloc(ulReturnLength);
        ZwQuerySystemInformation(SystemModuleInformation, SystemInformation, ulReturnLength, &ulReturnLength);
        SystemInformation = (PSYSTEM_MODULE_INFORMATION)((DWORD)SystemInformation + 4);
        WCHAR   szFileName[MAX_PATH] = { 0 };
        MultiByteToWideChar(CP_ACP, 0, SystemInformation->ImageName, strlen(SystemInformation->ImageName) + 1, szFileName,   
            sizeof(szFileName) / sizeof(szFileName[0]));
        HMODULE hNtoskrnl;
        MessageBox(szFileName, TEXT("lazy_cat"), MB_ICONINFORMATION);
        __asm
        {
            lea edi,szFileName
            cld
            xor al,al
            or  ecx,0xFFFFFFFF
            repnz scasw
            std
            mov al,'\\'
            or  ecx,0xFFFFFFFF
            repnz scasw
            add edi,4
            cld
            push DONT_RESOLVE_DLL_REFERENCES
            push NULL
            push edi
            call dword ptr [LoadLibraryEx]
            mov  hNtoskrnl,eax
        }
        // calc KeServiceDescriptorTable address.
        DWORD   dwRVAKeSvcDescTab = (DWORD)GetProcAddress(hNtoskrnl, "KeServiceDescriptorTable") - (DWORD)hNtoskrnl;
        DWORD   dwKeSvcDescTab = (DWORD)SystemInformation->Base + dwRVAKeSvcDescTab;
        
        // Read SSDT
        MEMORY_CHUNKS MmChunks;
        MmChunks.dwAddress = dwKeSvcDescTab;
        MmChunks.Data = &m_stSysSvcTab;
        MmChunks.dwLength = sizeof(SYSTEM_SERVICE_TABLE);
        DWORD dwBytesReturn = 0;
        ZwSystemDebugControl(DebugCopyMemoryChunks, &MmChunks, sizeof(MEMORY_CHUNKS), NULL, 0, &dwBytesReturn);

        DWORD   dwFuncAddr = 0;
        MmChunks.dwAddress = (DWORD)m_stSysSvcTab.ServiceTableBase;
        MmChunks.Data = &dwFuncAddr;
        MmChunks.dwLength = sizeof(DWORD);

        for (int i = 0; i < 0x11C; i++)
        {
            WCHAR   szAddr[32];
            ZwSystemDebugControl(DebugCopyMemoryChunks, &MmChunks, sizeof(MEMORY_CHUNKS), NULL, 0, &dwBytesReturn);
            swprintf(szAddr, 32, TEXT("0x%08X"), dwFuncAddr);
            m_pListCtrl->SetItemText(i, 2, szAddr);

            // calc which module this address belongs to.
            for (unsigned int j = 0; j < *(DWORD*)((DWORD)SystemInformation - 4); j++)
            {
                if (dwFuncAddr >= (DWORD)SystemInformation[j].Base && dwFuncAddr < (DWORD)SystemInformation[j].Base + SystemInformation[j].Size) {
                    WCHAR   szModuleName[MAX_PATH] = { 0 };
                    MultiByteToWideChar(CP_ACP, 0, SystemInformation[j].ImageName, strlen(SystemInformation[j].ImageName) + 1, szModuleName,   
                        sizeof(szModuleName) / sizeof(szModuleName[0]));
                    m_pListCtrl->SetItemText(i, 4, szModuleName);
                }
            }
            MmChunks.dwAddress += 4;
        }
        // Enumerate all relocations to find xrefs to the KeServiceDescriptorTable
        PIMAGE_OPTIONAL_HEADER  pOptionalHeader = (PIMAGE_OPTIONAL_HEADER)((DWORD)hNtoskrnl + ((IMAGE_DOS_HEADER*)hNtoskrnl)->e_lfanew + 4 + sizeof(IMAGE_FILE_HEADER));
        PIMAGE_BASE_RELOCATION  pImgBaseReloc = (PIMAGE_BASE_RELOCATION)((DWORD)hNtoskrnl + pOptionalHeader->DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress);
        DWORD   pKiServiceTab;
        WCHAR   szOriginalAddr[32];
        BOOL    bFound = FALSE;
        while (pImgBaseReloc->VirtualAddress)
        {
            PSHORT  pRelocAddr = (PSHORT)((DWORD)pImgBaseReloc + sizeof(IMAGE_BASE_RELOCATION));
            for (unsigned int i = 0; i < (pImgBaseReloc->SizeOfBlock - sizeof(IMAGE_BASE_RELOCATION)) >> 1; i++)
            {
                if (IMAGE_REL_BASED_HIGHLOW == pRelocAddr[i] >> 12)
                {
                    // mov ds:_KeServiceDescriptorTable.Base, offset _KiServiceTable
                    // search for: C7 05, 00 00 00 00, 00 00 00 00
                    DWORD   dwRelocAddr = (DWORD)hNtoskrnl + pImgBaseReloc->VirtualAddress + (pRelocAddr[i] & 0xFFF);
                    if (dwRVAKeSvcDescTab == *(DWORD*)dwRelocAddr - pOptionalHeader->ImageBase)
                    {
                        if (0x5C7 == *((WORD*)(dwRelocAddr - 2)))
                        {
                            pKiServiceTab = *((DWORD*)(dwRelocAddr + 4)) - pOptionalHeader->ImageBase;
                            pKiServiceTab += (DWORD)hNtoskrnl;
                            for (int i = 0; i < 0x11C; i++)
                            {
                                swprintf(szOriginalAddr, 32, TEXT("0x%08X"), ((DWORD*)pKiServiceTab)[i] - pOptionalHeader->ImageBase + (DWORD)SystemInformation->Base);
                                m_pListCtrl->SetItemText(i, 3, szOriginalAddr);
                            }
                            bFound = TRUE;
                            break;
                        }
                    }
                }
            } 
            pImgBaseReloc = (PIMAGE_BASE_RELOCATION)((DWORD)pImgBaseReloc + pImgBaseReloc->SizeOfBlock);
        } // end search reloc

        // If faild, use Solution two:
        if (!bFound) {
            MessageBox(TEXT("Cann't find the KeServiceDescriptorTable's reloc information.\r\nNow try to to use solution 2."), TEXT("lazy_cat"), MB_ICONINFORMATION);
            // KiServiceTable's RVA + hNtoskrnl
            pKiServiceTab = (DWORD)m_stSysSvcTab.ServiceTableBase - (DWORD)SystemInformation->Base + (DWORD)hNtoskrnl;
            for (int i = 0; i < 0x11C; i++)
            {
                // ((DWORD*)pKiServiceTab)[i] is a VA, because of DONT_RESOLVE_DLL_REFERENCES, this address
                // is not reloc, so, sub ImageBase(not hNtoskrnl) from this address is the RVA
                swprintf(szOriginalAddr, 32, TEXT("0x%08X"), ((DWORD*)pKiServiceTab)[i] - pOptionalHeader->ImageBase + (DWORD)SystemInformation->Base);
                m_pListCtrl->SetItemText(i, 3, szOriginalAddr);
            }        
        }

        // calc hooked counts.
        int nHookCount = 0;
        for (int i = 0; i < 0x11C; i++)
            if (wcscmp(m_pListCtrl->GetItemText(i, 2), m_pListCtrl->GetItemText(i, 3)))
                nHookCount++;
        WCHAR   szText[64] = { 0 };
        swprintf(szText, 64, TEXT("SSDT hook count:%d."), nHookCount);
        wcscat_s(szText, 64, nHookCount ? TEXT("Your computer might be at risk.") : TEXT("Your computer is very healthy."));
        SetDlgItemText(IDC_STATIC_INFO, szText);       
        free((PVOID)((DWORD)SystemInformation - 4));
    }
	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CAntiSDTHookDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	CDialog::OnSysCommand(nID, lParam);
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CAntiSDTHookDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

// The system calls this function to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CAntiSDTHookDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}

void CAntiSDTHookDlg::OnListCtrlDrawItemColor(NMHDR *pNmHdr, LRESULT *pResult)
{
    NMLVCUSTOMDRAW* pLVCD = reinterpret_cast<NMLVCUSTOMDRAW*>(pNmHdr);	
    *pResult = CDRF_DODEFAULT;
    if (CDDS_PREPAINT == pLVCD->nmcd.dwDrawStage)
        *pResult = CDRF_NOTIFYITEMDRAW;
    else if (CDDS_ITEMPREPAINT == pLVCD->nmcd.dwDrawStage)
        *pResult = CDRF_NOTIFYSUBITEMDRAW;
    else if ((CDDS_ITEMPREPAINT | CDDS_SUBITEM) == pLVCD->nmcd.dwDrawStage)
    {   
        int nItem = static_cast<int>(pLVCD->nmcd.dwItemSpec);

        if(wcscmp(m_pListCtrl->GetItemText(nItem, 2), m_pListCtrl->GetItemText(nItem, 3))) {
            pLVCD->clrText = RGB(0, 0, 0);
            pLVCD->clrTextBk = RGB(255, 0, 0);
        }
        else {
            pLVCD->clrText = RGB(0, 0, 255);
            pLVCD->clrTextBk = RGB(255, 255, 255);
        }
        *pResult = CDRF_DODEFAULT;
    }
}

void CAntiSDTHookDlg::OnBnClickedButtonRestore()
{
    POSITION pos = m_pListCtrl->GetFirstSelectedItemPosition();
    if (pos)
    {
        int nItem = m_pListCtrl->GetNextSelectedItem(pos);
        WCHAR   szAddr[32];
        m_pListCtrl->GetItemText(nItem, 0, szAddr, sizeof(szAddr));
        int nSvcNum = wcstoul(szAddr, NULL, 16);
        m_pListCtrl->GetItemText(nItem, 3, szAddr, sizeof(szAddr));
        DWORD   dwOriginalAddr = wcstoul(szAddr, NULL, 16);

        // Write kernel memory
        MEMORY_CHUNKS MmChunks;
        MmChunks.dwAddress = (DWORD)m_stSysSvcTab.ServiceTableBase + (nSvcNum << 2);
        MmChunks.Data = &dwOriginalAddr;
        MmChunks.dwLength = sizeof(DWORD);
        DWORD dwReturnLength = 0;
        ZwSystemDebugControl(DebugWriteVirtualMemory, &MmChunks, sizeof(MEMORY_CHUNKS), NULL, 0, &dwReturnLength);
        if (!dwReturnLength)
            MessageBox(TEXT("Restore failed."), TEXT("lazy_cat"), MB_ICONERROR);
    }
}

void CAntiSDTHookDlg::OnBnClickedButtonRestoreall()
{
    for (int i = 0; i < m_pListCtrl->GetItemCount(); i++)
    {
        WCHAR   szAddr[256];
        m_pListCtrl->GetItemText(i, 3, szAddr, sizeof(szAddr));
        
        if (wcscmp(szAddr, m_pListCtrl->GetItemText(i, 2)))
        {
            // Write kernel memory
            DWORD   dwOriginalAddr = wcstoul(szAddr, NULL, 16);
            MEMORY_CHUNKS MmChunks;
            MmChunks.dwAddress = (DWORD)m_stSysSvcTab.ServiceTableBase + (i << 2);
            MmChunks.Data = &dwOriginalAddr;
            MmChunks.dwLength = sizeof(DWORD);
            DWORD dwReturnLength = 0;
            ZwSystemDebugControl(DebugWriteVirtualMemory, &MmChunks, sizeof(MEMORY_CHUNKS), NULL, 0, &dwReturnLength);
            if (!dwReturnLength) {
                m_pListCtrl->GetItemText(i, 1, szAddr, sizeof(szAddr));
                wcscat_s(szAddr, 256, TEXT(" restore failed."));
                MessageBox(szAddr, TEXT("lazy_cat"), MB_ICONERROR);
            }
        }
    }
}
