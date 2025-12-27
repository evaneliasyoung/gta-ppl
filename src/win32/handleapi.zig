// https://learn.microsoft.com/en-us/windows/win32/api/handleapi/
const windows = @import("std").os.windows;
const HANDLE = windows.HANDLE;
const BOOL = windows.BOOL;

// https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle
pub extern "kernel32" fn CloseHandle(
    hObject: HANDLE,
) callconv(.winapi) BOOL;
