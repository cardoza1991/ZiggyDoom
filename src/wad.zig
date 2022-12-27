const std = @import("std");

const io = @import("io.zig");
const main = @import("main.zig");

const WadInfo = struct {
    identification: [4]u8,
    num_lumps: usize,
    info_table_ofs: usize,
};

const FileLump = struct {
    pos: usize,
    size: usize,
    name: []const u8,
};

pub const File = struct {
    file: std.fs.File,
};

pub const LumpInfo = struct {
    name: []const u8,
    wad: *File,
    position: usize,
    size: usize,
    cache: ?[]u8 = null,
};

pub var lump_info: std.ArrayList(LumpInfo) = undefined;
const LumpHash = std.StringArrayHashMap(*LumpInfo);
var lump_hash: ?LumpHash = null;

pub fn addFile(path: []const u8) !*File {
    const wf = try main.allocator.create(File);
    wf.file = std.fs.cwd().openFile(path, .{}) catch |e| {
        io.print(" couldn't open {s}\n", .{path});
        return e;
    };
    errdefer {
        wf.file.close();
        main.allocator.destroy(wf);
    }

    readWad(path, wf) catch |e| {
        const IoError = std.fs.File.ReadError || std.fs.File.StatError;
        inline for (@typeInfo(IoError).ErrorSet.?) |fld| {
            if (std.mem.eql(u8, @errorName(e), fld.name))
                return error.InvalidWad;
        }
        return e;
    };
    return wf;
}

fn readWad(path: []const u8, wf: *File) !void {
    var fileinfo: []FileLump = undefined;
    const f = &wf.file;

    if (std.ascii.endsWithIgnoreCase(path, "wad")) {
        // full WAD
        var header: WadInfo = undefined;
        if ((try f.reader().readAll(&header.identification)) != 4)
            return error.InvalidWad;

        if (!std.mem.eql(u8, &header.identification, "IWAD") and
            !std.mem.eql(u8, &header.identification, "PWAD"))
        {
            return error.InvalidWad;
        }

        const numlumps = try f.reader().readIntLittle(i32);
        const infotableofs = try f.reader().readIntLittle(i32);
        fileinfo = main.allocator.alloc(
            FileLump,
            @intCast(usize, numlumps),
        ) catch unreachable;

        try f.seekTo(@intCast(u64, infotableofs));
        for (fileinfo) |*i| {
            const pos = try f.reader().readIntLittle(i32);
            const size = try f.reader().readIntLittle(i32);
            var namebuf: [8]u8 = undefined;
            if ((try f.reader().readAll(&namebuf)) != 8)
                return error.InvalidWad;
            const name_end = std.mem.indexOfScalar(u8, &namebuf, 0) orelse 8;
            const name = main.allocator.dupe(u8, namebuf[0..name_end]) catch unreachable;
            i.pos = @intCast(usize, pos);
            i.size = @intCast(usize, size);
            i.name = name;
        }
    } else {
        // single-lump file, construct "fake" directory
        fileinfo = main.allocator.alloc(FileLump, 1) catch unreachable;
        fileinfo[0].name = std.fs.path.stem(path);
        fileinfo[0].pos = 0;
        const stat = try f.stat();
        fileinfo[0].size = stat.size;
    }

    const startlump = lump_info.items.len;
    try lump_info.resize(startlump + fileinfo.len);
    for (lump_info.items[startlump..]) |*nl, i| {
        nl.wad = wf;
        nl.position = fileinfo[i].pos;
        nl.size = fileinfo[i].size;
        nl.cache = null;
        nl.name = fileinfo[i].name;
    }
}

pub fn generateHashTable() !void {
    if (lump_hash) |*lh| {
        lh.deinit();
    }

    lump_hash = LumpHash.init(main.allocator);
    for (lump_info.items) |*lump| {
        try lump_hash.?.put(lump.name, lump);
    }
}
