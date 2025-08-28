const std = @import("std");
const distro = @import("distro.zig");
const ascii_art = @import("ascii_art.zig");
const hardware = @import("hardware.zig");

pub fn getShellVersion(allocator: std.mem.Allocator) ![]u8 {
    // Get the current shell
    const shell_path = std.posix.getenv("SHELL") orelse return try allocator.dupe(u8, "Unknown");

    // Extract the shell name (e.g., "bash" or "zsh") from the path
    const shell_name = std.fs.path.basename(shell_path);

    const shell_version_output = try executeCommand(allocator, &[_][]const u8{ shell_name, "--version" });
    defer allocator.free(shell_version_output);

    // Parse the version from the output
    const shell_version = try parseShellVersion(allocator, shell_name, shell_version_output);
    return shell_version;
}

pub fn userAndHostname(allocator: std.mem.Allocator) ![]u8 {
    //user and hostname info printed on top
    const user = std.posix.getenv("USER") orelse return try allocator.dupe(u8, "Unknown");
    var hostname_buf: [64]u8 = undefined; // Buffer to store the hostname
    const hostname = std.posix.gethostname(&hostname_buf) catch "Unknown";
    return try std.fmt.allocPrint(allocator, "{s}@{s}", .{ user, hostname });
}

fn parseShellVersion(allocator: std.mem.Allocator, shell_name: []const u8, output: []const u8) ![]u8 {
    if (std.mem.eql(u8, shell_name, "bash")) {
        // Example output: "GNU bash, version 5.2.15(1)-release (x86_64-pc-linux-gnu)"
        if (std.mem.indexOf(u8, output, "version")) |version_index| {
            const version_start = version_index + "version ".len;
            if (std.mem.indexOf(u8, output[version_start..], " ")) |space_index| {
                const version = output[version_start .. version_start + space_index];
                return try std.fmt.allocPrint(allocator, "Bash {s}", .{version});
            }
        }
    } else if (std.mem.eql(u8, shell_name, "zsh")) {
        // Example output: "zsh 5.9 (x86_64-pc-linux-gnu)"
        if (std.mem.indexOf(u8, output, " ")) |space_index| {
            const version_start = space_index + 1;
            if (std.mem.indexOf(u8, output[version_start..], " ")) |next_space_index| {
                const version = output[version_start .. version_start + next_space_index];
                return try std.fmt.allocPrint(allocator, "Zsh {s}", .{version});
            }
        }
    }

    return try allocator.dupe(u8, "Unknown");
}

pub fn getMemoryInfo(allocator: std.mem.Allocator) ![]const u8 {
    const meminfo_file = try std.fs.openFileAbsolute("/proc/meminfo", .{});
    defer meminfo_file.close();

    var meminfo_buf: [1024]u8 = undefined;
    const meminfo_len = try meminfo_file.readAll(&meminfo_buf);
    const meminfo_str = meminfo_buf[0..meminfo_len];

    var mem_total: u64 = 0;
    var mem_available: u64 = 0;

    var lines = std.mem.splitSequence(u8, meminfo_str, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            mem_total = try parseMemInfoValue(line);
        } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            mem_available = try parseMemInfoValue(line);
        }
    }

    if (mem_total == 0 or mem_available == 0) {
        return error.InvalidMemInfo;
    }

    const used_memory = mem_total - mem_available;
    const memory_info = try std.fmt.allocPrint(allocator, "{}MiB / {}MiB", .{ used_memory / 1024, mem_total / 1024 });
    return memory_info;
}

fn parseMemInfoValue(line: []const u8) !u64 {
    var iter = std.mem.splitSequence(u8, line, " ");
    _ = iter.next(); // Skip the label (e.g., "MemTotal:")

    // Find the first non-empty token
    while (iter.next()) |token| {
        if (token.len > 0) {
            // Remove the "kB" suffix if present
            const value_str = if (std.mem.endsWith(u8, token, "kB"))
                token[0 .. token.len - 2]
            else
                token;

            // Parse the numeric value
            return std.fmt.parseInt(u64, value_str, 10);
        }
    }

    return error.InvalidMemInfo;
}

pub fn executeCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
    var result = std.ArrayListUnmanaged(u8){}; // Andrew Kelley made me do this
    defer result.deinit(allocator);

    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    //const stdout = try child.stdout.?.reader(&buf).readAllAlloc(allocator, std.math.maxInt(usize));
    const stdout = try child.stdout.?.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdout);

    try result.appendSlice(allocator, stdout);

    _ = try child.wait();

    return try result.toOwnedSlice(allocator);
}

pub fn executeUptimeCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![] u8 {
    var result = std.ArrayListUnmanaged(u8){};
    defer result.deinit(allocator);

    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdout);

    try result.appendSlice(allocator, stdout);

    const term = try child.wait();
    if (term.Exited != 0) {
        return error.CommandFailed;
    }

    return result.toOwnedSlice(allocator);
}

