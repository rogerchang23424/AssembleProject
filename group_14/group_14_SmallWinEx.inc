OSVERSIONINFO STRUCT
	dwOSVersionInfoSize DWORD ?
	dwMajorVersion DWORD ?
	dwMinorVersion DWORD ?
	dwBuildNumber DWORD ?
	dwPlatformId DWORD ?
	szCSDVersion BYTE 128 DUP(?)
OSVERSIONINFO ENDS

OSVERSIONINFOEX STRUCT
	dwOSVersionInfoSize DWORD ?
	dwMajorVersion DWORD ?
	dwMinorVersion DWORD ?
	dwBuildNumber DWORD ?
	dwPlatformId DWORD ?
	szCSDVersion BYTE 128 DUP(?)
	wServicePackMajor WORD ?
	wServicePackMinor WORD ?
	wSuiteMask WORD ?
	wProductType BYTE ?
	wReserved BYTE ?
OSVERSIONINFOEX ENDS

RTL_CRITICAL_SECTION STRUCT
	DebugInfo DWORD ?
	LockCount DWORD ?
	RecursionCount DWORD ?
	OwningThread DWORD ?
	LockSemaphore DWORD ?
	SpinCount DWORD ?
RTL_CRITICAL_SECTION ENDS

VER_NT_WORKSTATION = 1

;以下函式庫接定義在kernel32.dll裡面

GetVersionExA PROTO, lpVersionInfo:PTR OSVERSIONINFO		;取得作業系統版本
SetConsoleCursorInfo PROTO, _hout:HANDLE, _cci:PTR CONSOLE_CURSOR_INFO	;設定游標狀態
SetConsoleCursorPosition PROTO, _hout:HANDLE, _coord:COORD		;設定游標位置
SetConsoleTitleA PROTO, title_name:PTR BYTE
WriteConsoleInputA PROTO, 
	hConsoleInput:HANDLE, lpBuffer:PTR INPUT_RECORD, 
	nLength:DWORD, lpNumberOfEventsWritten:PTR DWORD
MapVirtualKeyA PROTO, uCode:DWORD, uMapType:DWORD

;Thread 初始化
EXTERN CreateThread@24:PROC
CreateMutexA PROTO, lpMutexAttributes:DWORD, bInitialOwner:DWORD, lpName:PTR BYTE
GetCurrentThreadId PROTO
Sleep proto, millisecond:DWORD
WaitForMultipleObjects PROTO, nCount:DWORD,
	lpHandles:PTR HANDLE, bWaitAll:DWORD, dwMilliseconds:DWORD
WaitForSingleObject PROTO, hHandle:HANDLE, dwMilliseconds:DWORD
ReleaseMutex PROTO, hMutex:HANDLE

InitializeCriticalSection PROTO, _cs:PTR RTL_CRITICAL_SECTION
EnterCriticalSection PROTO, _cs:PTR RTL_CRITICAL_SECTION
LeaveCriticalSection PROTO, _cs:PTR RTL_CRITICAL_SECTION
DeleteCriticalSection PROTO, _cs:PTR RTL_CRITICAL_SECTION


INFINITE = -1
