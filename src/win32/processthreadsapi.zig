// https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/

const windows = @import("std").os.windows;
const DWORD = windows.DWORD;
const BOOL = windows.BOOL;
const HANDLE = windows.HANDLE;

// https://learn.microsoft.com/en-us/windows/win32/procthread/process-security-and-access-rights
pub const PROCESS_CREATE_PROCESS: DWORD = 0x0080;
pub const PROCESS_CREATE_THREAD: DWORD = 0x0002;
pub const PROCESS_DUP_HANDLE: DWORD = 0x0040;
pub const PROCESS_QUERY_INFORMATION: DWORD = 0x0400;
pub const PROCESS_QUERY_LIMITED_INFORMATION: DWORD = 0x1000;
pub const PROCESS_SET_INFORMATION: DWORD = 0x0200;
pub const PROCESS_SET_QUOTA: DWORD = 0x0100;
pub const PROCESS_SUSPEND_RESUME: DWORD = 0x0800;
pub const PROCESS_TERMINATE: DWORD = 0x0001;
pub const PROCESS_VM_OPERATION: DWORD = 0x0008;
pub const PROCESS_VM_READ: DWORD = 0x0010;
pub const PROCESS_VM_WRITE: DWORD = 0x0020;

// https://learn.microsoft.com/en-us/windows/win32/procthread/thread-security-and-access-rights
pub const THREAD_DIRECT_IMPERSONATION: DWORD = 0x0200;
pub const THREAD_GET_CONTEXT: DWORD = 0x0008;
pub const THREAD_THREAD_IMPERSONATE: DWORD = 0x0100;
pub const THREAD_QUERY_INFORMATION: DWORD = 0x0040;
pub const THREAD_QUERY_LIMITED_INFORMATION: DWORD = 0x0800;
pub const THREAD_SET_CONTEXT: DWORD = 0x0010;
pub const THREAD_SET_INFORMATION: DWORD = 0x0020;
pub const THREAD_SET_LIMITED_INFORMATION: DWORD = 0x0400;
pub const THREAD_SET_THREAD_TOKEN: DWORD = 0x0080;
pub const THREAD_SUSPEND_RESUME: DWORD = 0x00002;
pub const THREAD_TERMINATE: DWORD = 0x0001;

// https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess
pub extern "kernel32" fn OpenProcess(
    dwDesiredAccess: DWORD,
    bInheritHandle: BOOL,
    dwProcessId: DWORD,
) callconv(.winapi) ?HANDLE;

// https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openthread
pub extern "kernel32" fn OpenThread(
    dwDesiredAccess: DWORD,
    bInheritHandle: BOOL,
    dwThreadId: DWORD,
) callconv(.winapi) ?HANDLE;

// https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-resumethread
pub extern "kernel32" fn ResumeThread(
    hThread: HANDLE,
) callconv(.winapi) DWORD;

// https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-suspendthread
pub extern "kernel32" fn SuspendThread(
    hThread: HANDLE,
) callconv(.winapi) DWORD;
