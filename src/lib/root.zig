pub const Process = @import("Process.zig");
pub const Thread = @import("Thread.zig");

pub const version = @import("build").version;

test {
    _ = @import("Process.zig");
    _ = @import("Thread.zig");
}
