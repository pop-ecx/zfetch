const std = @import("std");

pub fn printSystemInfo(allocator: std.mem.Allocator) !void {
    // Get memory information
    const memory_info = try executeCommand(allocator, &[_][]const u8{ "free", "-h" });
    defer allocator.free(memory_info);
    std.debug.print("Memory Info:\n{s}\n", .{memory_info});

    // Get storage space information
    const storage_info = try executeCommand(allocator, &[_][]const u8{ "df", "-h" });
    defer allocator.free(storage_info);
    std.debug.print("Storage Space Info:\n{s}\n", .{storage_info});

    // Get desktop environment
    const desktop_env = std.os.getenv("XDG_CURRENT_DESKTOP") orelse "Unknown";
    std.debug.print("Desktop Environment: {s}\n", .{desktop_env});

    // Get Linux kernel version
    const kernel_version = try executeCommand(allocator, &[_][]const u8{ "uname", "-r" });
    defer allocator.free(kernel_version);
    std.debug.print("Linux Kernel Version: {s}\n", .{kernel_version});
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
