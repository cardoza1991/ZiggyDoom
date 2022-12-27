const std = @import("std");

const argv = @import("argv.zig");
const state = @import("state.zig");
const misc = struct {
    pub const ConfigValue = @import("misc/config_value.zig").ConfigValue;
    pub const config = @import("misc/config.zig");
};
const wad = @import("wad.zig");

pub var allocator: std.mem.Allocator = undefined;

pub fn main() void {
    run() catch std.process.exit(1);
}

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    wad.lump_info = std.ArrayList(wad.LumpInfo).init(allocator);
    argv.args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv.args);
    try misc.config.setDir(null);
    _ = try wad.addFile("/home/kyle/doom/iwad/doom2.wad");
    try wad.generateHashTable();
    misc.config.load();
    misc.config.save();
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
