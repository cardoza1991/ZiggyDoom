const std = @import("std");

pub var args: [][:0]u8 = undefined;

pub fn check(arg: []const u8) ?usize {
    for (args) |a, i| {
        if (std.ascii.eqlIgnoreCase(a, arg))
            return i;
    }
    return null;
}

pub fn checkN(arg: []const u8, n: usize) ?usize {
    const i = check(arg) orelse return null;
    return if (i < args.len - n) i else null;
}

pub fn get(i: usize) []const u8 {
    return args[i];
}
