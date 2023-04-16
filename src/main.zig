const std = @import("std");
const zone = @import("zone.zig");
const g = @import("global.zig");
const io = @import("io.zig");

fn findResponseFile() !void {
    // loop with indices because this loop reallocates g.args
    var i: usize = 0;
    while (i < g.args.len) : (i += 1) {
        if (std.mem.startsWith(u8, g.args[i], "@")) {
            const file = blk: {
                const handle = std.fs.cwd().openFile(g.args[i][1..], .{}) catch |e| {
                    io.print("\nNo such response file!\n", .{});
                    return e;
                };
                defer handle.close();
                io.print("Found response file {s}!\n", .{g.args[i][1..]});
                const file = try handle.readToEndAlloc(
                    zone.get(.static),
                    std.math.maxInt(usize),
                );
                break :blk file;
            };

            var it = std.mem.tokenize(u8, file, &std.ascii.whitespace);
            var nargs: usize = 0;
            while (it.next()) |_| {
                nargs += 1;
            }

            const new_args = try zone.alloc(.static, []const u8, g.args.len + nargs - 1);
            std.mem.copy([]const u8, new_args, g.args[0..i]);
            it = std.mem.tokenize(u8, file, &std.ascii.whitespace);
            var offset: usize = 0;
            while (it.next()) |a| : (offset += 1) {
                new_args[i + offset] = a;
            }
            std.mem.copy([]const u8, new_args[i + offset ..], g.args[i + 1 ..]);

            io.print("{d} command-line args:\n", .{new_args.len - 1});
            for (new_args[1..]) |a| {
                io.print("{s}\n", .{a});
            }

            g.args = new_args;
            break;
        }
    }
}

pub fn main() void {
    run() catch std.process.exit(1);
}

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 10 }){};
    const raw_allocator = gpa.allocator();
    zone.init(raw_allocator);
    defer zone.deinit();

    defer io.deinit();

    g.args = try std.process.argsAlloc(zone.get(.static));

    try findResponseFile();
}
