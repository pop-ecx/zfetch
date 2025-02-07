const std = @import("std");
const distro = @import("distro.zig");
const ascii_art = @import("ascii_art.zig");
const hardware = @import("hardware.zig");

pub fn printSystemInfo(allocator: std.mem.Allocator) !void {
    // Get distro information
    const distro_info = try distro.getDistroInfo(allocator);
    defer allocator.free(distro_info);

    // Parse distro name
    const distro_name = try distro.parseDistroName(allocator, distro_info);
    defer allocator.free(distro_name);

    // Get desktop environment
    const desktop_env = std.os.getenv("DESKTOP_SESSION") orelse std.os.getenv("XDG_CURRENT_DESKTOP") orelse "Unknown";

    // Get Linux kernel version
    const kernel_version = try executeCommand(allocator, &[_][]const u8{ "uname", "-r" });
    defer allocator.free(kernel_version);

    // Get system uptime
    const uptime = try getUptime(allocator);
    defer allocator.free(uptime);

    //get memory info
    const memory_info = try getMemoryInfo(std.heap.page_allocator);
    defer std.heap.page_allocator.free(memory_info);

    //Get bash/zsh/fish version
    const shell_version = try getShellVersion(allocator);
    defer allocator.free(shell_version);

    //Get CPU info
    const cpu = try hardware.getCPUInfo(allocator);
    defer allocator.free(cpu);

    //Get GPU info
    const gpu = try hardware.getGPUInfo(allocator);
    defer allocator.free(gpu);

    //user and hostname info
    const user_at_hostname = try userAndHostname(allocator);
    defer allocator.free(user_at_hostname);

    // Print ASCII art and system info in Neofetch style
    try ascii_art.printNeofetchStyle(distro_name, desktop_env, kernel_version, uptime, shell_version, cpu);
}

pub fn getShellVersion(allocator: std.mem.Allocator) ![]u8 {
    // Get the current shell from the SHELL environment variable
    const shell_path = std.os.getenv("SHELL") orelse return try allocator.dupe(u8, "Unknown");

    // Extract the shell name (e.g., "bash" or "zsh") from the path
    const shell_name = std.fs.path.basename(shell_path);

    const shell_version_output = try executeCommand(allocator, &[_][]const u8{ shell_name, "--version" });
    defer allocator.free(shell_version_output);

    // Parse the version from the output
    const shell_version = try parseShellVersion(allocator, shell_name, shell_version_output);
    return shell_version;
}

pub fn userAndHostname(allocator: std.mem.Allocator) ![]u8 {
    //Get user and hostname info to be printed on top
    const user = std.os.getenv("USER") orelse return try allocator.dupe(u8, "Unknown");
    var hostname_buf: [64]u8 = undefined; // Buffer to store the hostname
    const hostname = std.os.gethostname(&hostname_buf) catch "Unknown";
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

    //"Unknown if shell version cannot be parsed"
    return try allocator.dupe(u8, "Unknown");
}

fn getUptime(allocator: std.mem.Allocator) ![]u8 {
    // Execute the `uptime` command
    const uptime_output = try executeCommand(allocator, &[_][]const u8{ "uptime", "-p" });
    defer allocator.free(uptime_output);

    // Remove the "up" prefix from the output (e.g., "up 3 hours, 43 mins" -> "3 hours, 43 mins")
    const uptime = std.mem.trim(u8, uptime_output, "up ");
    return try allocator.dupe(u8, uptime);
}

pub fn getMemoryInfo(allocator: std.mem.Allocator) ![]const u8 {
    const meminfo_file = try std.fs.openFileAbsolute("/proc/meminfo", .{});
    defer meminfo_file.close();

    var meminfo_buf: [1024]u8 = undefined;
    const meminfo_len = try meminfo_file.readAll(&meminfo_buf);
    const meminfo_str = meminfo_buf[0..meminfo_len];

    var mem_total: u64 = 0;
    var mem_available: u64 = 0;

    var lines = std.mem.split(u8, meminfo_str, "\n");
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
    var iter = std.mem.split(u8, line, " ");
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
