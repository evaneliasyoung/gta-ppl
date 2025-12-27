const std = @import("std");
const win = std.os.windows;

const win32 = @import("win32");
const tlhelp32 = win32.tlhelp32;
const handleapi = win32.handleapi;

pub const Error = error{OutOfMemory};

pub const Process = @This();

size: u32,
usage: u32,
process_id: u32,
heap_id: usize,
module_id: u32,
threads: u32,
parent_id: u32,
class_base: i32,
flags: u32,
exe_file: []u8,

pub fn copyFromWin32Process(
    gpa: std.mem.Allocator,
    proc: *tlhelp32.PROCESSENTRY32W,
) Error!Process {
    const u16_name = std.mem.sliceTo(proc.*.szExeFile[0..], 0);
    const exe_file = std.unicode.utf16LeToUtf8Alloc(gpa, u16_name) catch return Error.OutOfMemory;

    return Process{
        .size = proc.*.dwSize,
        .usage = proc.*.cntUsage,
        .process_id = proc.*.th32ProcessID,
        .heap_id = proc.*.th32DefaultHeapID,
        .module_id = proc.*.th32ModuleID,
        .threads = proc.*.cntThreads,
        .parent_id = proc.*.th32ParentProcessID,
        .class_base = proc.*.pcPriClassBase,
        .flags = proc.*.dwFlags,
        .exe_file = exe_file,
    };
}

pub fn dupe(self: *const Process, gpa: std.mem.Allocator) Error!Process {
    return .{
        .size = self.size,
        .usage = self.usage,
        .process_id = self.process_id,
        .heap_id = self.heap_id,
        .module_id = self.module_id,
        .threads = self.threads,
        .parent_id = self.parent_id,
        .class_base = self.class_base,
        .flags = self.flags,
        .exe_file = gpa.dupe(u8, self.exe_file) catch return Error.OutOfMemory,
    };
}

pub fn deinit(self: *Process, gpa: std.mem.Allocator) void {
    gpa.free(self.exe_file);
}

pub const Iterator = struct {
    pub const Error = error{SnapshotFailed} || Process.Error;

    snap: win.HANDLE,
    proc: ?Process,

    pub fn init() Iterator.Error!Iterator {
        const snap = tlhelp32.CreateToolhelp32Snapshot(tlhelp32.TH32CS_SNAPPROCESS, 0);

        if (snap == win.INVALID_HANDLE_VALUE) {
            _ = handleapi.CloseHandle(snap);
            return Iterator.Error.SnapshotFailed;
        }
        return .{ .snap = snap, .proc = null };
    }

    pub fn next(self: *Iterator, gpa: std.mem.Allocator) Iterator.Error!?Process {
        var entry: tlhelp32.PROCESSENTRY32W = undefined;
        entry.dwSize = @sizeOf(tlhelp32.PROCESSENTRY32W);

        if (self.proc) |*proc| {
            proc.deinit(gpa);
            if (tlhelp32.Process32NextW(self.snap, &entry) == win.FALSE) return null;
        } else {
            if (tlhelp32.Process32FirstW(self.snap, &entry) == win.FALSE) return null;
        }

        self.proc = try .copyFromWin32Process(gpa, &entry);
        return self.proc;
    }

    pub fn deinit(self: *Iterator, gpa: std.mem.Allocator) void {
        if (self.proc) |*proc| proc.deinit(gpa);
        _ = handleapi.CloseHandle(self.snap);
    }
};

pub const List = struct {
    pub const Error = Iterator.Error;

    items: []Process,
    len: usize,

    pub fn where(
        gpa: std.mem.Allocator,
        filterFN: *const fn (item: *const Process) bool,
    ) List.Error!List {
        var collection: std.ArrayList(Process) = .empty;
        defer collection.deinit(gpa);

        var it: Iterator = try .init();
        defer it.deinit(gpa);

        while (try it.next(gpa)) |*p| {
            if (filterFN(p)) {
                const copy = try p.dupe(gpa);
                try collection.append(gpa, copy);
            }
        }

        const items = try collection.toOwnedSlice(gpa);
        const len = items.len;

        return .{ .items = items, .len = len };
    }

    pub fn deinit(self: *List, gpa: std.mem.Allocator) void {
        for (self.items) |*p| p.deinit(gpa);
        gpa.free(self.items);
    }
};
