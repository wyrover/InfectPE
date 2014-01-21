/*

  InfectPE.h
  by lazy_cat

  Desc: Some structure is copy from ntifs.h (WinDDK.7600.16385.0)

*/

#ifndef _INFECTPE_H_
#define _INFECTPE_H_


#pragma pack(1)
typedef struct _SYSTEM_SERVICE_TABLE {
    PULONG     ServiceTableBase;
    PULONG     ServiceCounterTableBase;
    ULONG      NumberOfService;
    PCHAR      ParamTableBase;
} SYSTEM_SERVICE_TABLE, *PSYSTEM_SERVICE_TABLE;
#pragma pack()


#pragma pack(1)
typedef struct _SERVICE_DESCRIPTOR_TABLE {
    SYSTEM_SERVICE_TABLE    ntoskrnl;
    SYSTEM_SERVICE_TABLE    win32k;
    SYSTEM_SERVICE_TABLE    Reserved1;
    SYSTEM_SERVICE_TABLE    Reserved2;
} SERVICE_DESCRIPTOR_TABLE, *PSERVICE_DESCRIPTOR_TABLE;
#pragma pack()


NTSYSAPI
NTSTATUS
NTAPI
ZwQueryDirectoryFile (
	__in HANDLE FileHandle,
	__in_opt HANDLE Event,
	__in_opt PIO_APC_ROUTINE ApcRoutine,
    __in_opt PVOID ApcContext,
	__out PIO_STATUS_BLOCK IoStatusBlock,
    __out_bcount(Length) PVOID FileInformation,
	__in ULONG Length,
	__in FILE_INFORMATION_CLASS FileInformationClass,
    __in BOOLEAN ReturnSingleEntry,
    __in_opt PUNICODE_STRING FileName,
    __in BOOLEAN RestartScan
    );


NTSYSAPI
NTSTATUS
NTAPI
ZwOpenProcess (
	__out PHANDLE  ProcessHandle,
	__in ACCESS_MASK  DesiredAccess,
	__in POBJECT_ATTRIBUTES  ObjectAttributes,
	__in_opt PCLIENT_ID  ClientId
	);


NTSTATUS
NTAPI
InfectpeNtQueryDirectoryFile (
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


NTSTATUS
NTAPI
InfectpeNtOpenProcess (
	__out PHANDLE  ProcessHandle,
	__in ACCESS_MASK  DesiredAccess,
	__in POBJECT_ATTRIBUTES  ObjectAttributes,
	__in_opt PCLIENT_ID  ClientId
	);



typedef
NTSTATUS 
(NTAPI *PNTQUERYDIRECTORYFILE) (
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


typedef
NTSTATUS
(NTAPI *PNTOPENPROCESS) (
	__out PHANDLE  ProcessHandle,
	__in ACCESS_MASK  DesiredAccess,
	__in POBJECT_ATTRIBUTES  ObjectAttributes,
	__in_opt PCLIENT_ID  ClientId
	);


NTSTATUS
DriverEntry (
	IN PDRIVER_OBJECT		DriverObject,
	IN PUNICODE_STRING		RegistryPath
	);


VOID
InfectpeUnload (
	IN PDRIVER_OBJECT		DriverObject
	);


NTSTATUS
InfectpeDispatchDeviceControl (
	__in struct _DEVICE_OBJECT  *DeviceObject,
	__in struct _IRP  *Irp
	);

NTSTATUS
InfectpeDispatch (
	__in struct _DEVICE_OBJECT  *DeviceObject,
	__in struct _IRP  *Irp
	);


typedef struct _FILE_BOTH_DIR_INFORMATION {
    ULONG NextEntryOffset;			// +0
    ULONG FileIndex;				// +4
    LARGE_INTEGER CreationTime;		// +8
    LARGE_INTEGER LastAccessTime;	// +16
    LARGE_INTEGER LastWriteTime;	// +24
    LARGE_INTEGER ChangeTime;		// +32
    LARGE_INTEGER EndOfFile;		// +40
    LARGE_INTEGER AllocationSize;	// +48
    ULONG FileAttributes;			// +56
    ULONG FileNameLength;			// +60
    ULONG EaSize;					// +64
    CCHAR ShortNameLength;			// +68
    WCHAR ShortName[12];			// +70
    WCHAR FileName[1];				// +94
} FILE_BOTH_DIR_INFORMATION, *PFILE_BOTH_DIR_INFORMATION;


typedef	struct _DEVICE_EXTENSION {
	PDEVICE_OBJECT	pDeviceObject;
	UNICODE_STRING  ustrSymbolicName;
} DEVICE_EXTENSION, *PDEVICE_EXTENSION;


typedef struct _SHOW_INFO {
	ULONG	ulMajorFunction;
	CHAR	*szText;
} SHOW_INFO, *PSHOW_INFO;


typedef	ULONG	DWORD;


//
// Get the Nt~ function address index in the SSDT table.
// The index is located in corresponding Zw~ address plus 1.
//
#define ServiceIndex(_func) (*(ULONG*)((UCHAR*)(_func) + 1))

//
// I/O Control Codes
//
#define IOCTL_INFECTPE CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)


#endif  /* _INFECTPE_H_ */
