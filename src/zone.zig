const std = @import("std");

// order matters, some methods free in a range!
pub const Tag = enum(usize) {
    static,
    sound,
    music,
    dave,
    level,
    levspec,
    purgelevel,
    cache,
};

var zones: [std.meta.fields(Tag).len]std.heap.ArenaAllocator =
    // initialize with init()
    undefined;

pub fn init(raw_allocator: std.mem.Allocator) void {
    for (&zones) |*z| {
        z.* = std.heap.ArenaAllocator.init(raw_allocator);
    }
}

pub fn deinit() void {
    for (&zones) |*z| {
        z.deinit();
    }
}

pub fn get(tag: Tag) std.mem.Allocator {
    return zones[@enumToInt(tag)].allocator();
}

pub fn alloc(tag: Tag, comptime T: type, count: usize) ![]T {
    return try get(tag).alloc(T, count);
}

pub fn create(tag: Tag, comptime T: type) !*T {
    return try get(tag).create(T);
}

pub fn resetTags(comptime low: Tag, comptime high: Tag) void {
    comptime std.debug.assert(@enumToInt(low) <= @enumToInt(high));

    for (@enumToInt(low)..@enumToInt(high)) |i| {
        // limit 100kB
        _ = zones[i].reset(.{ .retain_with_limit = 100 * 1024 });
    }
}

pub fn changeTagSingle(comptime T: type, ptr: *T, new_tag: Tag) !*T {
    const new_ptr = try get(new_tag).create(T);
    new_ptr.* = ptr.*;
    return new_ptr;
}

pub fn changeTagSlice(comptime T: type, ptr: []const T, new_tag: Tag) ![]T {
    return try get(new_tag).dupe(T, ptr);
}
