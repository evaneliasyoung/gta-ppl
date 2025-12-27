const std = @import("std");

const Chameleon = @import("chameleon");
const cli = @import("cli/root.zig");
const clap = @import("clap");

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const gpa = arena.allocator();

    var diag = clap.Diagnostic{};
    var res: cli.main.Args = clap.parse(clap.Help, &cli.main.params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa,
        .terminating_positional = 0,
    }) catch |err| {
        try diag.reportToFile(.stderr(), err);
        return err;
    };
    defer res.deinit();

    const stdout_file: std.fs.File = .stdout();
    var stdout_writer = stdout_file.writer(&.{});
    const stdout = &stdout_writer.interface;

    const stderr_file: std.fs.File = .stderr();
    var stderr_writer = stderr_file.writer(&.{});
    const stderr = &stderr_writer.interface;

    cli.main.invoke(gpa, stdout, stderr, &res) catch |err| {
        var c = Chameleon.initRuntime(.{ .allocator = gpa });
        defer c.deinit();

        defer std.process.exit(1);

        switch (err) {
            error.SleepTimeInvalid => {
                try cli.print.err(
                    &c,
                    "min-sleep ({d}) must be less than max-sleep ({d})",
                    .{ res.args.@"min-sleep" orelse 9, res.args.@"max-sleep" orelse 11 },
                );
            },
            error.ProcessNotFound => {
                try cli.print.err(&c, "failed to find GTA process", .{});
            },
            error.ThreadsNotFound => {
                try cli.print.err(&c, "failed to find GTA threads", .{});
            },
            else => try cli.print.err(&c, "{any}", .{err}),
        }
    };
}

test {
    _ = @import("cli/root.zig");
}
