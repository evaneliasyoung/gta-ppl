const std = @import("std");
const builtin = @import("builtin");
const clap = @import("clap");

const cli = @import("root.zig");
const gta_ppl = @import("gta_ppl");

pub const params = clap.parseParamsComptime(
    \\-m, --min-sleep <usize>    Minimum sleep time in seconds
    \\-x, --max-sleep <usize>    Maximum sleep time in seconds
    \\-v, --version              Display version and exit
    \\-h, --help                 Display this menu and exit
);

pub const Args = clap.Result(clap.Help, &cli.main.params, clap.parsers.default);

pub fn invoke(
    gpa: std.mem.Allocator,
    stdout: *std.Io.Writer,
    stderr: *std.Io.Writer,
    res: *const Args,
) !void {
    if (res.args.help != 0) {
        defer std.process.exit(0);
        try cli.help.invoke(gpa, stdout, stderr);
    }

    if (res.args.version != 0) {
        defer std.process.exit(0);
        try cli.main.version(stdout, res);
    }

    const min_sleep_time: usize = res.args.@"min-sleep" orelse 9;
    const max_sleep_time: usize = res.args.@"max-sleep" orelse 11;

    if (min_sleep_time >= max_sleep_time) {
        return error.SleepTimeInvalid;
    }

    var procs: gta_ppl.Process.List = try .where(gpa, isGTA);
    defer procs.deinit(gpa);
    if (procs.len == 0) {
        return error.ProcessNotFound;
    }

    var threads: gta_ppl.Thread.List = try .whereChildOfProcesses(gpa, procs);
    defer threads.deinit(gpa);
    if (threads.len == 0) {
        return error.ThreadsNotFound;
    }

    for (threads.items) |*thread| {
        try thread.open(.SuspendResume);
        try thread.@"suspend"();
        try thread.close();
    }

    try stdout.print("\r+{s:-^78}+\n", .{"GTA-PPL"});
    try displayThreads(gpa, stdout, threads);

    const sleep_time = getSleepTime(min_sleep_time * std.time.ns_per_s, max_sleep_time * std.time.ns_per_s);

    try pauseWithCountdown(stdout, sleep_time);

    for (threads.items) |*thread| {
        try thread.open(.SuspendResume);
        try thread.@"resume"();
        try thread.close();
    }
}

fn displayThreads(
    gpa: std.mem.Allocator,
    w: *std.Io.Writer,
    threads: gta_ppl.Thread.List,
) std.Io.Writer.Error!void {
    {
        var i: usize = 0;
        var line: std.Io.Writer.Allocating = .init(gpa);
        const line_writer = &line.writer;
        defer line.deinit();

        for (threads.items) |thread| {
            try line_writer.print("0x{X:0>8}", .{thread.thread_id});
            if (i == 7 - 1) {
                try w.print("|{s: ^78}|\n", .{line_writer.buffered()});
                _ = line_writer.consumeAll();
            } else {
                try line_writer.writeByte(' ');
            }

            i = (i + 1) % 7;
        }

        _ = line_writer.consumeAll();
    }

    if (threads.len % 7 != 0) {
        const remaining_count = 7 - (threads.len % 7);
        const remaining = threads.items[(threads.len - remaining_count)..];
        var i: usize = 0;

        try w.writeAll("| ");

        const conditions = [7]bool{
            remaining.len == 6,
            remaining.len >= 4,
            remaining.len >= 2,
            remaining.len % 2 == 1,
            remaining.len >= 2,
            remaining.len >= 4,
            remaining.len == 6,
        };

        for (conditions) |cond| {
            if (cond) {
                try w.print("0x{X:0>8} ", .{remaining[i].thread_id});
                i += 1;
            } else {
                try w.writeAll("           ");
            }
        }

        try w.writeAll("|\n");
    }
}

fn isGTA(proc: *const gta_ppl.Process) bool {
    return std.mem.eql(u8, proc.exe_file, "GTA5.exe") or std.mem.eql(u8, proc.exe_file, "GTA5_Enhanced.exe");
}

fn getSleepTime(min_sleep_time: u64, max_sleep_time: u64) u64 {
    var engine: std.Random.DefaultPrng = .init(@intCast(std.time.microTimestamp()));
    const rng = engine.random();
    return std.Random.intRangeAtMost(rng, u64, min_sleep_time, max_sleep_time);
}

fn pauseWithCountdown(
    w: *std.Io.Writer,
    nanoseconds: u64,
) (std.Io.Writer.Error || std.time.Timer.Error)!void {
    try w.writeAll("\x1b[?25l");

    const ns_per_cs: u64 = 10 * @as(u64, std.time.ns_per_ms);

    var timer = try std.time.Timer.start();

    var last_cs: u64 = std.math.maxInt(u64);

    while (true) {
        const elapsed_ns = timer.read();
        if (elapsed_ns >= nanoseconds) break;

        const remaining_ns = nanoseconds - elapsed_ns;
        const remaining_cs = (remaining_ns + ns_per_cs - 1) / ns_per_cs;

        if (remaining_cs != last_cs) {
            last_cs = remaining_cs;
            const fl = @as(f64, @floatFromInt(remaining_cs)) / 100;
            try w.print("\r+{d:-^78.2}+", .{fl});
        }

        std.Thread.sleep(@min(remaining_ns, ns_per_cs));
    }
    try w.print("\r+{s:-^78}+\n", .{"GTA-PPL"});
    try w.writeAll("\x1b[?25h");
}

pub fn version(w: *std.Io.Writer, res: *const Args) std.Io.Writer.Error!void {
    switch (res.args.version) {
        1 => try w.print("{s}\n", .{gta_ppl.version}),
        2 => try w.print("{s}-{s}-{s}", .{
            gta_ppl.version,
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.cpu.arch),
        }),
        else => try w.print("{s}-{s}-{s}-{s}", .{
            gta_ppl.version,
            @tagName(builtin.target.os.tag),
            @tagName(builtin.target.cpu.arch),
            switch (builtin.mode) {
                .Debug => "debug",
                .ReleaseSafe => "safe",
                .ReleaseFast => "fast",
                .ReleaseSmall => "small",
            },
        }),
    }
}
