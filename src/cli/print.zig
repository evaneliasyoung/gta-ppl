const std = @import("std");

const Chameleon = @import("chameleon");

fn printWithPrefix(
    c: *Chameleon.RuntimeChameleon,
    prefix: []const u8,
    comptime format: []const u8,
    args: anytype,
) std.Io.Writer.Error!void {
    var buf: [1024]u8 = undefined;
    var writer = std.fs.File.stderr().writer(&buf);
    try c.print(&writer.interface, "{s}: ", .{prefix});
    try writer.interface.print(format, args);
    try writer.interface.flush();
}

pub fn warn(
    c: *Chameleon.RuntimeChameleon,
    comptime format: []const u8,
    args: anytype,
) std.Io.Writer.Error!void {
    try printWithPrefix(c.bold().yellow(), "warn", format, args);
}

pub fn err(
    c: *Chameleon.RuntimeChameleon,
    comptime format: []const u8,
    args: anytype,
) std.Io.Writer.Error!void {
    try printWithPrefix(c.bold().red(), "error", format, args);
}
