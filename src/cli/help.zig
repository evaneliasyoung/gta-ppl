const std = @import("std");
const builtin = @import("builtin");

const Chameleon = @import("chameleon");

const cli = @import("root.zig");
const gta_ppl = @import("gta_ppl");

pub const InvokeError = std.mem.Allocator.Error || std.Io.Writer.Error;

pub fn invoke(
    gpa: std.mem.Allocator,
    stdout: *std.Io.Writer,
    _: *std.Io.Writer,
) InvokeError!void {
    var c = Chameleon.initRuntime(.{ .allocator = gpa });
    defer c.deinit();

    var bold = try c.bold().createPreset();
    defer bold.deinit();

    var dim = try c.dim().createPreset();
    defer dim.deinit();

    var bold_cyan = try c.bold().cyan().createPreset();
    defer bold_cyan.deinit();

    var cyan = try c.cyan().createPreset();
    defer cyan.deinit();

    var dim_cyan = try c.cyan().dim().createPreset();
    defer dim_cyan.deinit();

    var bold_magenta = try c.bold().magenta().createPreset();
    defer bold_magenta.deinit();

    // Header
    try c.bold().green().print(stdout, "gta-ppl", .{});
    try stdout.writeAll(" is a tool to generate a public-private lobby for GTA V. ");
    try dim.print(stdout, "({s})\n\n", .{gta_ppl.version});

    // Usage
    try bold.print(stdout, "Usage: gta-ppl ", .{});
    try bold_cyan.print(stdout, "[...flags]\n\n", .{});

    // Flags
    try bold.print(stdout, "Flags:\n", .{});

    try cyan.print(stdout, "  -m", .{});
    try stdout.writeAll(", ");
    try cyan.print(stdout, "--min-sleep", .{});
    try dim_cyan.print(stdout, "=<val>", .{});
    try stdout.writeAll("    Minimum sleep time in seconds (default: 9)\n");

    try cyan.print(stdout, "  -x", .{});
    try stdout.writeAll(", ");
    try cyan.print(stdout, "--max-sleep", .{});
    try dim_cyan.print(stdout, "=<val>", .{});
    try stdout.writeAll("    Maximum sleep time in seconds (default: 11)\n");

    try cyan.print(stdout, "  -v", .{});
    try stdout.writeAll(", ");
    try cyan.print(stdout, "--version", .{});
    try stdout.writeAll("            Display version and exit\n");

    try cyan.print(stdout, "      -vv", .{});
    try stdout.writeAll("                  Display version and target and exit\n");

    try cyan.print(stdout, "      -vvv", .{});
    try stdout.writeAll("                 Display version, target and optimization and exit\n");

    try cyan.print(stdout, "  -h", .{});
    try stdout.writeAll(", ");
    try cyan.print(stdout, "--help", .{});
    try stdout.writeAll("               Display this menu and exit\n");
}
