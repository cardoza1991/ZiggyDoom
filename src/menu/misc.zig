//! Corresponds to m_misc.c in the original Doom source.

const std = @import("std");

const main = @import("../main.zig");
const argv = @import("../argv.zig");
const state = @import("../state.zig");
const ConfigValue = @import("config_value.zig").ConfigValue;

var default_file: []const u8 = undefined;

pub fn writeFile(name: []const u8, source: []const u8) !void {
    // TODO
    _ = name;
    _ = source;
}

pub fn readFile(name: []const u8) ![]u8 {
    // TODO
    _ = name;
    return error.NotImplemented;
}

pub fn screenShot() void {
    // TODO
}

pub fn loadDefaults() void {
    for (defaults) |*d| {
        d.location.* = d.default_value;
    }

    if (argv.checkN("-config", 1)) |i| {
        default_file = argv.get(i + 1);
        std.io.getStdOut().writer().print(
            "        default file: {s}\n",
            .{default_file},
        ) catch unreachable;
    } else default_file = main.base_default;

    var f = std.fs.cwd().openFile(default_file, .{}) catch return;
    defer f.close();

    var def_buf: [80]u8 = undefined;
    var strparm_buf: [100]u8 = undefined;

    nextLine: while (true) {
        const def = f.reader().readUntilDelimiterOrEof(
            &def_buf,
            ' ',
        ) catch |e| switch (e) {
            error.StreamTooLong => &def_buf,
            else => unreachable,
        } orelse break;
        const first: ?u8 = firstNonWs: while (true) {
            const c = f.reader().readByte() catch break :firstNonWs null;
            if (c == '\n') break :firstNonWs null;
            if (!std.ascii.isWhitespace(c)) break :firstNonWs c;
        };
        strparm_buf[0] = first orelse continue;
        const strparm = f.reader().readUntilDelimiterOrEof(
            strparm_buf[1..],
            '\n',
        ) catch |e| switch (e) {
            error.StreamTooLong => &strparm_buf,
            else => unreachable,
        } orelse break;

        const default = findDefault: {
            for (defaults) |d| {
                if (std.mem.eql(u8, def, d.name))
                    break :findDefault d;
            }
            continue :nextLine;
        };

        if (strparm[0] == '"') {
            default.location.* = .{
                .string = main.allocator.dupe(u8, strparm) catch unreachable,
            };
        } else {
            default.location.* = .{
                .int = std.fmt.parseInt(isize, strparm, 0) catch continue :nextLine,
            };
        }
    }
}

pub fn saveDefaults() void {
    var f = std.fs.cwd().createFile(default_file, .{}) catch return;
    defer f.close();

    for (defaults) |d| {
        switch (d.location.*) {
            .int => |i| {
                f.writer().print("{s} {d}\n", .{ d.name, i }) catch break;
            },
            .string => |s| {
                f.writer().print("{s} \"{s}\"\n", .{ d.name, s }) catch break;
            },
        }
    }
}

pub fn drawText(x: usize, y: usize, direct: bool, string: []const u8) usize {
    // TODO
    _ = x;
    _ = y;
    _ = direct;
    _ = string;
    return 0;
}

// ===================
// =   PRIVATE API   =
// ===================

const Config = struct {
    name: []const u8,
    location: *ConfigValue,
    default_value: ConfigValue,
    scan_translate: isize = 0,
    untranslated: isize = 0,
};

const defaults = [_]Config{
    .{
        .name = "mouse_sensitivity",
        .location = &state.mouse_sensitivity,
        .default_value = .{ .int = 5 },
    },
    .{
        .name = "sfx_volume",
        .location = &state.sfx_volume,
        .default_value = .{ .int = 8 },
    },
    .{
        .name = "music_volume",
        .location = &state.music_volume,
        .default_value = .{ .int = 8 },
    },
    .{
        .name = "show_messages",
        .location = &state.show_messages,
        .default_value = .{ .int = 8 },
    },
};
