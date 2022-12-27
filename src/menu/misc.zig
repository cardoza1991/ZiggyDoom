//! Corresponds to m_misc.c in the original Doom source.

const state = @import("root").state;
const ConfigValue = @import("config_value.zig").ConfigValue;

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
    // TODO
}

pub fn saveDefaults() void {
    // TODO
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
