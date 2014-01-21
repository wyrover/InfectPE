// IoCtl.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#define IOCTL_INFECTPE CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)


int _tmain(int argc, _TCHAR* argv[])
{
    HANDLE  hFile = CreateFile(TEXT("C:\\InfectPE.sys"), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE)
    {
        printf("C:\\InfectPE.sys open failed.\n");
    }
    else
    {
        printf("C:\\InfectPE.sys open successed.\n");
        CloseHandle(hFile);
    }
    printf("%08X\n", IOCTL_INFECTPE);
    return 0;
    HANDLE  hDevice = CreateFile(TEXT("\\\\.\\InfectPE"), 0, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (hDevice == INVALID_HANDLE_VALUE)
    {
        printf("%08x can't open the drive.\n", hDevice);
        return (FALSE);
    }
    ULONG   ulPID = _wtoi(argv[1]);
    DWORD   dwBytesReturned = 0;
    ULONG   ulReturnVal = 0;

    BOOL bResult = DeviceIoControl(hDevice, IOCTL_INFECTPE, &ulPID, sizeof(ulPID), &ulReturnVal, sizeof(ULONG), &dwBytesReturned, NULL);
    if (bResult)
    {
        if (dwBytesReturned)
        {
            printf("%08X:%08X\n", (ULONG)&ulReturnVal, ulReturnVal);
        }
        printf("OK. dwBytesReturned=%d\n", dwBytesReturned);
    }
    else
    {
        printf("DeviceIoControl Failed.\n");
    }
    CloseHandle(hDevice);
	return 0;
}

