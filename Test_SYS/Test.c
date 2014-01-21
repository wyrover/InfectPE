/*

  Test.c

  Author: lazy_cat

*/

#include <ntddk.h>
#include "Test.h"


#ifdef  ALLOC_PRAGMA
#pragma alloc_text(INIT, DriverEntry)
#pragma alloc_text(PAGE, TestUnload)
#endif  /* ALLOC_PRAGMA */

typedef struct _FILE_DIRECTORY_INFORMATION { // Information Class 1
	ULONG NextEntryOffset;
	ULONG Unknown;
	LARGE_INTEGER CreationTime;
	LARGE_INTEGER LastAccessTime;
	LARGE_INTEGER LastWriteTime;
	LARGE_INTEGER ChangeTime;
	LARGE_INTEGER EndOfFile;
	LARGE_INTEGER AllocationSize;
	ULONG FileAttributes;
	ULONG FileNameLength;
	WCHAR FileName[1];
} FILE_DIRECTORY_INFORMATION, *PFILE_DIRECTORY_INFORMATION;

NTSTATUS
DriverEntry(
	IN PDRIVER_OBJECT		DriverObject,
	IN PUNICODE_STRING		RegistryPath
	)
{
	NTSTATUS			status = STATUS_SUCCESS;    
	HANDLE				hFile;
	OBJECT_ATTRIBUTES	ObjectAttributes;
	UNICODE_STRING		ustrFileName;
	IO_STATUS_BLOCK		IoStatusBlock;
	PFILE_DIRECTORY_INFORMATION		pDirInfo;
	UNICODE_STRING		FileName;
	PFILE_DIRECTORY_INFORMATION		pCur;

	__asm int 3;
	RtlInitUnicodeString(&FileName, L"*");
	RtlInitUnicodeString(&ustrFileName, L"\\??\\C:\\lazycat");
	InitializeObjectAttributes(&ObjectAttributes, &ustrFileName, OBJ_CASE_INSENSITIVE | OBJ_KERNEL_HANDLE, NULL, NULL);
	status = ZwCreateFile(&hFile, FILE_READ_ATTRIBUTES | FILE_LIST_DIRECTORY, &ObjectAttributes,
		&IoStatusBlock, NULL, FILE_ATTRIBUTE_DIRECTORY, FILE_SHARE_READ, FILE_OPEN, 
		FILE_DIRECTORY_FILE | FILE_SYNCHRONOUS_IO_ALERT, NULL, 0);
	if (NT_SUCCESS(status))
	{
		DbgPrint("ZwCreateFile successed.\n");
		pDirInfo = ExAllocatePoolWithTag(PagedPool, 10*(sizeof(FILE_DIRECTORY_INFORMATION) + sizeof(WCHAR[256])), 'abcd');
		ZwQueryDirectoryFile(hFile, NULL, NULL, NULL, &IoStatusBlock, pDirInfo, 10*(sizeof(FILE_DIRECTORY_INFORMATION) + sizeof(WCHAR[256])), 
			FileDirectoryInformation, FALSE, &FileName, TRUE);

		pCur = pDirInfo;
		while (TRUE)
		{
			DbgPrint("%ws\n", pCur->FileName);
			if (pCur->NextEntryOffset)
				pCur =  (PFILE_DIRECTORY_INFORMATION)((UCHAR*)pCur + pCur->NextEntryOffset);
			else
				break;
		}
		
		ExFreePool(pDirInfo);
		ZwClose(hFile);
	}
	else
	{
		DbgPrint("ZwCreateFile failed.\n");
	}
    
    DriverObject->DriverUnload = TestUnload;
    return status;
}


VOID
TestUnload(
	IN PDRIVER_OBJECT		DriverObject
	)
{
}