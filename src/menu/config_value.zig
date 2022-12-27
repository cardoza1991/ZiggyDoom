pub const ConfigValue = union(enum) {
    int: isize,
    string: []const u8,
};
