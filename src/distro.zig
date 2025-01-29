const std = @import("std");

pub fn getDistroInfo(allocator: std.mem.Allocator) ![]u8 {
    const distro_info = try readFile(allocator, "/etc/os-release");
    return distro_info;
}

pub fn parseDistroName(allocator: std.mem.Allocator, distro_info: []const u8) ![]u8 {
    var lines = std.mem.split(u8, distro_info, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "NAME=")) {
            const name = line["NAME=".len..];
            const trimmed_name = std.mem.trim(u8, name, "\"");
            return try allocator.dupe(u8, trimmed_name);
        }
    }
    return error.DistroNameNotFound;
}

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    _ = try file.readAll(buffer);

    return buffer;
}
