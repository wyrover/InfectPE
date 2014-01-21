/*

  Test.h

  Author: lazy_cat

*/

#ifndef _TEST_H_
#define _TEST_H_

NTSTATUS
DriverEntry(
			IN PDRIVER_OBJECT		DriverObject,
			IN PUNICODE_STRING		RegistryPath
			);


VOID
TestUnload(
		   IN PDRIVER_OBJECT		DriverObject
	);


NTSYSAPI
NTSTATUS 
NTAPI
ZwQueryDirectoryFile(
					 __in HANDLE  FileHandle,
					 __in_opt HANDLE  Event,
					 __in_opt PIO_APC_ROUTINE  ApcRoutine,
					 __in_opt PVOID  ApcContext,
					 __out PIO_STATUS_BLOCK  IoStatusBlock,
					 __out PVOID  FileInformation,
					 __in ULONG  Length,
					 __in FILE_INFORMATION_CLASS  FileInformationClass,
					 __in BOOLEAN  ReturnSingleEntry,
					 __in_opt PUNICODE_STRING  FileName,
					 __in BOOLEAN  RestartScan
					 );


#endif  /* _TEST_H_ */