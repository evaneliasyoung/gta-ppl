const std = @import("std");
const win = std.os.windows;

const win32 = @import("win32");
const tlhelp32 = win32.tlhelp32;
const handleapi = win32.handleapi;

const Process = @import("Process.zig");

pub const Thread = @This();

pub const OpenError = error{ AlreadyOpen, AccessError };
pub const SuspendResumeError = error{NotOpen};
pub const CloseError = error{ NotOpen, AccessError };

pub const Access = enum(u32) {
    DirectImpersonation = win32.processthreadsapi.THREAD_DIRECT_IMPERSONATION,
    GetContext = win32.processthreadsapi.THREAD_GET_CONTEXT,
    ThreadImpersonate = win32.processthreadsapi.THREAD_THREAD_IMPERSONATE,
    QueryInformation = win32.processthreadsapi.THREAD_QUERY_INFORMATION,
    QueryLimitedInformation = win32.processthreadsapi.THREAD_QUERY_LIMITED_INFORMATION,
    SetContext = win32.processthreadsapi.THREAD_SET_CONTEXT,
    SetInformation = win32.processthreadsapi.THREAD_SET_INFORMATION,
    SetLimitedInformation = win32.processthreadsapi.THREAD_SET_LIMITED_INFORMATION,
    SetThreadToken = win32.processthreadsapi.THREAD_SET_THREAD_TOKEN,
    SuspendResume = win32.processthreadsapi.THREAD_SUSPEND_RESUME,
    Terminate = win32.processthreadsapi.THREAD_TERMINATE,
};

size: u32,
usage: u32,
thread_id: u32,
process_id: u32,
base_pri: i32,
delta_pri: i32,
flags: u32,
handle: ?win.HANDLE,

pub fn copyFromWin32Thread(thread: *const tlhelp32.THREADENTRY32) Thread {
    return Thread{
        .size = thread.*.dwSize,
        .usage = thread.*.cntUsage,
        .thread_id = thread.*.th32ThreadID,
        .process_id = thread.*.th32OwnerProcessID,
        .base_pri = thread.*.tpBasePri,
        .delta_pri = thread.*.tpDeltaPri,
        .flags = thread.*.dwFlags,
        .handle = null,
    };
}

pub fn open(self: *Thread, access: Access) OpenError!void {
    if (self.handle) |_| return OpenError.AlreadyOpen;
    const result = win32.processthreadsapi.OpenThread(@intFromEnum(access), win.FALSE, self.thread_id);
    if (result == win.INVALID_HANDLE_VALUE) return OpenError.AccessError;
    self.handle = result;
}

pub fn close(self: *Thread) CloseError!void {
    if (self.handle) |handle| {
        const result = win32.handleapi.CloseHandle(handle);
        if (result == win.FALSE) return CloseError.AccessError;
        self.handle = null;
    } else {
        return CloseError.NotOpen;
    }
}

pub fn @"suspend"(self: *Thread) SuspendResumeError!void {
    if (self.handle) |handle| {
        _ = win32.processthreadsapi.SuspendThread(handle);
    } else {
        return SuspendResumeError.NotOpen;
    }
}

pub fn @"resume"(self: *Thread) SuspendResumeError!void {
    if (self.handle) |handle| {
        _ = win32.processthreadsapi.ResumeThread(handle);
    } else {
        return SuspendResumeError.NotOpen;
    }
}

pub fn isChildOf(self: *const Thread, proc: Process) bool {
    return self.process_id == proc.process_id;
}

pub const Iterator = struct {
    pub const Error = error{SnapshotFailed};

    snap: win.HANDLE,
    thread: ?Thread,

    pub fn init() Iterator.Error!Iterator {
        const snap = tlhelp32.CreateToolhelp32Snapshot(tlhelp32.TH32CS_SNAPTHREAD, 0);

        if (snap == win.INVALID_HANDLE_VALUE) {
            _ = handleapi.CloseHandle(snap);
            return Iterator.Error.SnapshotFailed;
        }
        return .{ .snap = snap, .thread = null };
    }

    pub fn next(self: *Iterator) ?Thread {
        var entry: tlhelp32.THREADENTRY32 = undefined;
        entry.dwSize = @sizeOf(tlhelp32.THREADENTRY32);

        if (self.thread) |_| {
            if (tlhelp32.Thread32Next(self.snap, &entry) == win.FALSE) return null;
        } else {
            if (tlhelp32.Thread32First(self.snap, &entry) == win.FALSE) return null;
        }

        self.thread = .copyFromWin32Thread(&entry);
        return self.thread;
    }

    pub fn deinit(self: *Iterator) void {
        _ = handleapi.CloseHandle(self.snap);
    }
};

pub const List = struct {
    pub const Error = error{OutOfMemory} || Iterator.Error;

    len: usize,
    items: []Thread,

    pub fn whereChildOfProcesses(
        gpa: std.mem.Allocator,
        procs: Process.List,
    ) List.Error!List {
        var collection: std.ArrayList(Thread) = .empty;
        defer collection.deinit(gpa);

        var it: Iterator = try .init();
        defer it.deinit();

        while (it.next()) |t| {
            for (procs.items) |proc| {
                if (t.isChildOf(proc)) try collection.append(gpa, t);
            }
        }

        const items = try collection.toOwnedSlice(gpa);
        const len = items.len;

        return .{ .items = items, .len = len };
    }

    pub fn deinit(self: *List, gpa: std.mem.Allocator) void {
        gpa.free(self.items);
    }
};
