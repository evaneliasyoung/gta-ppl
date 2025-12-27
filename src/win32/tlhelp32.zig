// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/

const windows = @import("std").os.windows;
const DWORD = windows.DWORD;
const ULONG_PTR = windows.ULONG_PTR;
const LONG = windows.LONG;
const MAX_PATH = windows.MAX_PATH;
const WCHAR = windows.WCHAR;
const HANDLE = windows.HANDLE;
const BOOL = windows.BOOL;

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot#parameters
pub const TH32CS_INHERIT: DWORD = 0x80000000;
pub const TH32CS_SNAPHEAPLIST: DWORD = 0x00000001;
pub const TH32CS_SNAPMODULE: DWORD = 0x00000008;
pub const TH32CS_SNAPMODULE2: DWORD = 0x00000010;
pub const TH32CS_SNAPPROCESS: DWORD = 0x00000002;
pub const TH32CS_SNAPTHREAD: DWORD = 0x00000004;
pub const TH32CS_SNAPALL: DWORD = TH32CS_SNAPHEAPLIST | TH32CS_SNAPMODULE | TH32CS_SNAPPROCESS | TH32CS_SNAPTHREAD;

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/ns-tlhelp32-processentry32w
pub const PROCESSENTRY32W = extern struct {
    dwSize: DWORD,
    cntUsage: DWORD,
    th32ProcessID: DWORD,
    th32DefaultHeapID: ULONG_PTR,
    th32ModuleID: DWORD,
    cntThreads: DWORD,
    th32ParentProcessID: DWORD,
    pcPriClassBase: LONG,
    dwFlags: DWORD,
    szExeFile: [MAX_PATH]WCHAR,
};

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/ns-tlhelp32-threadentry32
pub const THREADENTRY32 = extern struct {
    dwSize: DWORD,
    cntUsage: DWORD,
    th32ThreadID: DWORD,
    th32OwnerProcessID: DWORD,
    tpBasePri: LONG,
    tpDeltaPri: LONG,
    dwFlags: DWORD,
};

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot
pub extern "kernel32" fn CreateToolhelp32Snapshot(
    dwFlags: DWORD,
    th32ProcessID: DWORD,
) callconv(.winapi) HANDLE;

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-process32firstw
pub extern "kernel32" fn Process32FirstW(
    hSnapshot: HANDLE,
    lppe: *PROCESSENTRY32W,
) callconv(.winapi) BOOL;

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-process32nextw
pub extern "kernel32" fn Process32NextW(
    hSnapshot: HANDLE,
    lppe: *PROCESSENTRY32W,
) callconv(.winapi) BOOL;

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32first
pub extern "kernel32" fn Thread32First(
    hSnapshot: HANDLE,
    lpte: *THREADENTRY32,
) callconv(.winapi) BOOL;

// https://learn.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32next
pub extern "kernel32" fn Thread32Next(
    hSnapshot: HANDLE,
    lpte: *THREADENTRY32,
) callconv(.winapi) BOOL;
