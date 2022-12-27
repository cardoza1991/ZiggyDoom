const std = @import("std");

const argv = @import("argv.zig");
const state = @import("state.zig");
const menu = struct {
    pub const ConfigValue = @import("menu/config_value.zig").ConfigValue;
    pub const misc = @import("menu/misc.zig");
};

var base_default_buf: [1024]u8 = undefined;
pub var base_default: []const u8 = undefined;
pub var allocator: std.mem.Allocator = undefined;

pub fn main() void {
    run() catch std.process.exit(1);
}

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    allocator = gpa.allocator();
    const home = std.process.getEnvVarOwned(
        allocator,
        "HOME",
    ) catch |e| switch (e) {
        error.EnvironmentVariableNotFound => std.process.getEnvVarOwned(
            allocator,
            "USERPROFILE",
        ) catch {
            std.debug.print("Please set $HOME to your home directory\n", .{});
            return error.NoHome;
        },
        else => return e,
    };
    defer allocator.free(home);
    base_default = std.fmt.bufPrint(&base_default_buf, "{s}/.doomrc", .{home}) catch unreachable;
    argv.args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv.args);
    menu.misc.loadDefaults();
    menu.misc.saveDefaults();
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
