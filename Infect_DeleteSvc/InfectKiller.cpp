// InfectKiller.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"


int _tmain(int argc, _TCHAR* argv[])
{
    SC_HANDLE hSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
	if (!hSCManager)
        return 0;
    SC_HANDLE hService = OpenService(hSCManager, TEXT("InfectPESvc"), SERVICE_ALL_ACCESS);
    if (hService)
    {
        // first, stop the service 
        SERVICE_STATUS ServiceStatus = { 0 };
        if (ControlService(hService, SERVICE_CONTROL_STOP, &ServiceStatus))
            _tprintf(TEXT("ControlService(), service status:%08X\n"), ServiceStatus.dwCurrentState);

        // then delete the service
        if (DeleteService(hService))
            _tprintf(TEXT("Driver service uninstall success.\n"));
    }
    CloseServiceHandle(hService);
    CloseServiceHandle(hSCManager);
    return 0;
}

