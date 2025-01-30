const std = @import("std");
const distro = @import("distro.zig");
const ascii_art = @import("ascii_art.zig");

pub fn printSystemInfo(allocator: std.mem.Allocator) !void {
    // Get distro information
    const distro_info = try distro.getDistroInfo(allocator);
    defer allocator.free(distro_info);

    // Parse distro name
    const distro_name = try distro.parseDistroName(allocator, distro_info);
    defer allocator.free(distro_name);

    // Get memory information
    const memory_info = try executeCommand(allocator, &[_][]const u8{ "free", "-h" });
    defer allocator.free(memory_info);

    // Get storage space information
    const storage_info = try executeCommand(allocator, &[_][]const u8{ "df", "-h" });
    defer allocator.free(storage_info);

    // Get desktop environment
    const desktop_env = std.os.getenv("DESKTOP_SESSION") orelse "Unknown";

    // Get Linux kernel version
    const kernel_version = try executeCommand(allocator, &[_][]const u8{ "uname", "-r" });
    defer allocator.free(kernel_version);

    // Print ASCII art and system info in Neofetch style
    try ascii_art.printNeofetchStyle(distro_name, memory_info, storage_info, desktop_env, kernel_version);
}

pub fn executeCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.reader().readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdout);

    try result.appendSlice(stdout);

    _ = try child.wait();

    return result.toOwnedSlice();
}
