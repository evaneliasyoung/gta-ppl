pub const print = @import("print.zig");

pub const main = @import("main.zig");
pub const help = @import("help.zig");

test {
    _ = @import("print.zig");

    _ = @import("main.zig");
    _ = @import("help.zig");
}
