//! Corresponds to m_misc.c in the original Doom source.

const std = @import("std");
const known_folders = @import("known-folders");

const main = @import("../main.zig");
const argv = @import("../argv.zig");
const state = @import("../state.zig");
const ConfigValue = @import("config_value.zig").ConfigValue;

var config_dir: []const u8 = undefined;

fn getDefaultConfigDir() ![]const u8 {
    const base_path = try known_folders.getPath(
        main.allocator,
        .roaming_configuration,
    );
    if (base_path) |bp| {
        return try std.fs.path.join(main.allocator, &.{ bp, "zigdoom" });
    }
    return ".";
}

pub fn setDir(dir: ?[]const u8) !void {
    config_dir = dir orelse try getDefaultConfigDir();
    std.io.getStdOut().writer().print(
        "Using {s} for configuration and saves\n",
        .{config_dir},
    ) catch unreachable;
    std.fs.cwd().makePath(config_dir) catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };
}

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

pub fn load() void {
    for (defaults.values) |*d| {
        d.location.* = d.default_value;
    }

    if (argv.checkN("-config", 1)) |i| {
        defaults.filename = argv.get(i + 1);
        std.io.getStdOut().writer().print(
            "        default file: {s}\n",
            .{defaults.filename},
        ) catch unreachable;
    } else defaults.filename = std.fs.path.join(
        main.allocator,
        &.{ config_dir, "default.cfg" },
    ) catch unreachable;

    var f = std.fs.cwd().openFile(defaults.filename, .{}) catch {
        // file failed to open, don't complain
        // probably just the first run
        return;
    };
    defer f.close();

    var line_buf: [200]u8 = undefined;

    nextLine: while (true) {
        const line = readLine: {
            var tmp: []const u8 = f.reader().readUntilDelimiterOrEof(
                &line_buf,
                '\n',
            ) catch |e| switch (e) {
                error.StreamTooLong => &line_buf,
                else => unreachable,
            } orelse break :nextLine;
            tmp = std.mem.trimRight(u8, tmp, "\r");
            break :readLine tmp;
        };

        const def_name_end = std.mem.indexOfAny(
            u8,
            line,
            &std.ascii.whitespace,
        ) orelse {
            // parse failure
            continue :nextLine;
        };
        const def_name = line[0..def_name_end];

        const ws_end = findValue: {
            for (line[def_name_end..]) |c, i| {
                if (std.ascii.isWhitespace(c)) continue;
                break :findValue i + def_name_end;
            }
            // parse failure
            continue :nextLine;
        };
        const strparm = std.mem.trim(u8, line[ws_end..], "\"");

        const def = findDefault: {
            for (defaults.values) |d| {
                if (std.mem.eql(u8, def_name, d.name))
                    break :findDefault d;
            }
            continue :nextLine;
        };

        switch (def.default_value) {
            .int => def.location.* = .{
                .int = std.fmt.parseInt(isize, strparm, 0) catch continue :nextLine,
            },
            .boolean => {
                const ival = std.fmt.parseInt(u1, strparm, 0) catch continue :nextLine;
                def.location.* = .{
                    .boolean = if (ival == 1) true else false,
                };
            },
            .string => def.location.* = .{ .string = strparm },
            .float => def.location.* = .{
                .float = std.fmt.parseFloat(f64, strparm) catch continue :nextLine,
            },
        }
    }
}

pub fn save() void {
    var f = std.fs.cwd().createFile(defaults.filename, .{}) catch return;
    defer f.close();

    for (defaults.values) |d| {
        switch (d.location.*) {
            .int => |v| {
                f.writer().print("{s} {d}\n", .{ d.name, v }) catch break;
            },
            .string => |v| {
                f.writer().print("{s} \"{s}\"\n", .{ d.name, v }) catch break;
            },
            .float => |v| {
                f.writer().print("{s} {d}\n", .{ d.name, v }) catch break;
            },
            .boolean => |v| {
                f.writer().print("{s} {d}\n", .{ d.name, @boolToInt(v) }) catch break;
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
};

const defaults_list = [_]Config{
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
    .{
        .name = "screenblocks",
        .location = &state.screen_blocks,
        .default_value = .{ .int = 10 },
    },
    .{
        .name = "detaillevel",
        .location = &state.detail_level,
        .default_value = .{ .int = 0 },
    },
    .{
        .name = "snd_channels",
        .location = &state.snd_channels,
        .default_value = .{ .int = 8 },
    },
    .{
        .name = "vanilla_savegame_limit",
        .location = &state.vanilla_savegame_limit,
        .default_value = .{ .boolean = true },
    },
    .{
        .name = "vanilla_demo_limit",
        .location = &state.vanilla_demo_limit,
        .default_value = .{ .boolean = true },
    },
    .{
        .name = "show_endoom",
        .location = &state.show_endoom,
        .default_value = .{ .boolean = false },
    },
};

const ConfigSet = struct {
    values: []const Config,
    filename: []const u8 = undefined,
};

var defaults = ConfigSet{ .values = &defaults_list };
