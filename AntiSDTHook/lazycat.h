/*

define some native api & some structure.

*/

#pragma once

#include "stdafx.h"

typedef enum _SYSTEM_INFORMATION_CLASS {
    SystemBasicInformation,               // 0
    SystemProcessorInformation,           // 1
    SystemPerformanceInformation,         // 2
    SystemTimeOfDayInformation,           // 3
    SystemNotImplemented1,                // 4
    SystemProcessesAndThreadsInformation, // 5
    SystemCallCounts,                     // 6
    SystemConfigurationInformation,       // 7
    SystemProcessorTimes,                 // 8
    SystemGlobalFlag,                     // 9
    SystemNotImplemented2,                // 10
    SystemModuleInformation,              // 11
    // Ref to Native API for more...
} SYSTEM_INFORMATION_CLASS;

typedef
ULONG (NTAPI *PZWQUERYSYSTEMINFORMATION) (
    SYSTEM_INFORMATION_CLASS SystemInformationClass,
    PVOID SystemInformation,
    ULONG SystemInformationLength,
    PULONG ReturnLength
    );

typedef struct _SYSTEM_MODULE_INFORMATION { // Information Class 11
    ULONG Reserved[2];
    PVOID Base;
    ULONG Size;
    ULONG Flags;
    USHORT Index;
    USHORT Unknown;
    USHORT LoadCount;
    USHORT ModuleNameOffset;
    CHAR   ImageName[256];
} SYSTEM_MODULE_INFORMATION, *PSYSTEM_MODULE_INFORMATION;


typedef enum _DEBUG_CONTROL_CODE {
    DebugGetTraceInformation = 1,
    DebugSetInternalBreakpoint,
    DebugSetSpecialCall,
    DebugClearSpecialCalls,
    DebugQuerySpecialCalls,
    DebugDbgBreakPoint,
    // add by lazy_cat
    DebugCopyMemoryChunks   = 8,
    DebugWriteVirtualMemory = 9
} DEBUG_CONTROL_CODE;


typedef
ULONG
(NTAPI *PZWSYSTEMDEBUGCONTROL) (
    IN DEBUG_CONTROL_CODE ControlCode,
    IN PVOID InputBuffer OPTIONAL,
    IN ULONG InputBufferLength,
    OUT PVOID OutputBuffer OPTIONAL,
    IN ULONG OutputBufferLength,
    OUT PULONG ReturnLength OPTIONAL
    );

// DebugCopyMemoryChunks
typedef struct _MEMORY_CHUNKS {
    DWORD dwAddress;    // Address to be read
    PVOID Data;         // Data buffer
    DWORD dwLength;     // Buffer length
}MEMORY_CHUNKS, *PMEMORY_CHUNKS;
