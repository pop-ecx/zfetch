const std = @import("std");

pub fn getHardwareModel(allocator: std.mem.Allocator) ![]u8 {
    const hostnamectl_output = try executeCommand(allocator, &[_][]const u8{"hostnamectl"});
    defer allocator.free(hostnamectl_output);

    // Parse the hardware model from the output
    var lines = std.mem.split(u8, hostnamectl_output, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "  Hardware Model:")) {
            const model = std.mem.trim(u8, line["  Hardware Model:".len..], " ");
            return try allocator.dupe(u8, model);
        }
    }

    return try allocator.dupe(u8, "Unknown");
}

fn executeCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
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
