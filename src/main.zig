const std = @import("std");
pub const state = @import("state.zig");
pub const menu = struct {
    pub const ConfigValue = @import("menu/config_value.zig").ConfigValue;
    pub const misc = @import("menu/misc.zig");
};

pub fn main() !void {}

test {
    std.testing.refAllDeclsRecursive(@This());
}
