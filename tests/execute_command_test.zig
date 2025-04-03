const std = @import("std");

pub fn executeCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
    if (argv.len == 0) {
        return error.NoExecPath;
    }
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

test "executeCommand: successful command execution" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "echo", "hello" };
    const result = try executeCommand(allocator, &args);
    defer allocator.free(result);

    try std.testing.expectEqualSlices(u8, "hello\n", result);
}

test "executeCommand: command with no output" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{"true"};
    const result = try executeCommand(allocator, &args);
    defer allocator.free(result);

    try std.testing.expectEqualSlices(u8, "", result);
}

test "executeCommand: non-existent command" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{"nonexistentcommand123"};
    const result = executeCommand(allocator, &args);

    try std.testing.expectError(error.FileNotFound, result);
}

test "executeCommand: empty argument list" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{};
    const result = executeCommand(allocator, &args);

    try std.testing.expectError(error.NoExecPath, result);
}
