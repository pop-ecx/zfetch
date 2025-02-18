const std = @import("std");
const distro = @import("distro.zig");

pub fn getInstalledPackagesCount(allocator: std.mem.Allocator) !usize {
    const distro_info = try distro.getDistroInfo(allocator);
    defer allocator.free(distro_info);

    const distro_family = try distro.parseDistroFamily(allocator, distro_info);
    defer allocator.free(distro_family);

    if (std.mem.eql(u8, distro_family, "arch")) {
        return try getArchPackageCount(allocator);
    } else if (std.mem.eql(u8, distro_family, "debian") or std.mem.eql(u8, distro_family, "ubuntu")) {
        return try getDebianPackageCount(allocator);
    } else if (std.mem.eql(u8, distro_family, "fedora") or std.mem.eql(u8, distro_family, "rhel")) {
        return try getFedoraPackageCount(allocator);
    } else {
        return error.UnsupportedDistro;
    }
}

fn getArchPackageCount(allocator: std.mem.Allocator) !usize {
    const file = try std.fs.cwd().openFile("/var/lib/pacman/local", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    var count: usize = 0;
    var lines = std.mem.split(u8, buffer, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Package: ")) {
            count += 1;
        }
    }

    return count;
}

fn getDebianPackageCount(allocator: std.mem.Allocator) !usize {
    const file = try std.fs.cwd().openFile("/var/lib/dpkg/status", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    var count: usize = 0;
    var lines = std.mem.split(u8, buffer, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Package: ")) {
            count += 1;
        }
    }

    return count;
}

fn getFedoraPackageCount(allocator: std.mem.Allocator) !usize {
    const file = try std.fs.cwd().openFile("/var/lib/rpm/Packages", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    var count: usize = 0;
    var lines = std.mem.split(u8, buffer, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Package: ")) {
            count += 1;
        }
    }

    return count;
}
