const std = @import("std");

var stdout_buf: ?@TypeOf(std.io.bufferedWriter(std.io.getStdOut().writer())) = null;

pub fn deinit() void {
    if (stdout_buf) |*sb|
        sb.flush() catch std.process.exit(1);
}

fn stdout() @TypeOf(stdout_buf.?.writer()) {
    if (stdout_buf) |*sb|
        return sb.writer();

    stdout_buf = std.io.bufferedWriter(std.io.getStdOut().writer());
    return stdout_buf.?.writer();
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    stdout().print(fmt, args) catch std.process.exit(1);
}
