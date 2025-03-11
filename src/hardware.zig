const std = @import("std");

pub fn getResolution(allocator: std.mem.Allocator) ![]u8 {
    const xrandr_output = try executeCommand(allocator, &[_][]const u8{"xrandr"});
    defer allocator.free(xrandr_output);

    // Parse the resolution from the output
    var lines = std.mem.split(u8, xrandr_output, "\n");
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, " connected")) |connected_index| {
            if (std.mem.indexOf(u8, line[connected_index..], " ")) |space_index| {
                const resolution_start = connected_index + space_index + 1;
                if (std.mem.indexOf(u8, line[resolution_start..], " ")) |next_space_index| {
                    const resolution = line[resolution_start .. resolution_start + next_space_index];
                    return try allocator.dupe(u8, resolution);
                }
            }
        }
    }

    return try allocator.dupe(u8, "Unknown");
}

pub fn getCPUInfo(allocator: std.mem.Allocator) ![]u8 {
    const lscpu_output = try executeCommand(allocator, &[_][]const u8{"lscpu"});
    defer allocator.free(lscpu_output);

    // Parse the CPU model name and frequency
    var model_name: []const u8 = "Unknown";
    var frequency: []const u8 = "";

    var lines = std.mem.split(u8, lscpu_output, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Model name:")) {
            model_name = std.mem.trim(u8, line["Model name:".len..], " ");
        } else if (std.mem.startsWith(u8, line, "CPU MHz:")) {
            const mhz = std.mem.trim(u8, line["CPU MHz:".len..], " ");
            const ghz = try std.fmt.allocPrint(allocator, "{d:.3}GHz", .{try std.fmt.parseFloat(f64, mhz) / 1000.0});
            frequency = ghz;
        }
    }

    // Format the CPU info
    return try std.fmt.allocPrint(allocator, "{s}  {s}", .{ model_name, frequency });
}

pub fn getGPUInfo(allocator: std.mem.Allocator) ![]u8 {
    const lspci_output = try executeCommand(allocator, &[_][]const u8{"lspci"});
    defer allocator.free(lspci_output);

    // Parse the GPU information
    var lines = std.mem.split(u8, lspci_output, "\n");
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "VGA compatible controller:")) |vga_index| {
            const gpu_info = std.mem.trim(u8, line[vga_index + "VGA compatible controller:".len ..], " ");
            return try allocator.dupe(u8, gpu_info);
        }
    }

    return try allocator.dupe(u8, "Unknown");
}

fn executeCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
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
