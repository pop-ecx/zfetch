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

    var lines = std.mem.splitSequence(u8, lscpu_output, "\n");
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
    // --- 1. Try lspci ---
    if (executeCommand(allocator, &[_][]const u8{"lspci"})) |lspci_output| {
        defer allocator.free(lspci_output);

        var lines = std.mem.splitSequence(u8, lspci_output, "\n");
        while (lines.next()) |line| {
            if (std.mem.indexOf(u8, line, "VGA compatible controller:")) |vga_index| {
                const gpu_info = std.mem.trim(
                    u8,
                    line[vga_index + "VGA compatible controller:".len ..],
                    " "
                );
                return try allocator.dupe(u8, gpu_info);
            }
        }
    } else |_| {
        // silently ignore if command missing
    }

    // --- 2. Try glxinfo ---
    if (executeCommand(allocator, &[_][]const u8{"glxinfo"})) |glx_output| {
        defer allocator.free(glx_output);

        var lines = std.mem.splitSequence(u8, glx_output, "\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "OpenGL renderer string:")) {
                const gpu_info = std.mem.trim(
                    u8,
                    line["OpenGL renderer string:".len ..],
                    " "
                );
                return try allocator.dupe(u8, gpu_info);
            }
        }
    } else |_| {}

    // --- 3. Try vulkaninfo ---
    if (executeCommand(allocator, &[_][]const u8{"vulkaninfo"})) |vk_output| {
        defer allocator.free(vk_output);

        var lines = std.mem.splitSequence(u8, vk_output, "\n");
        while (lines.next()) |line| {
            if (std.mem.indexOf(u8, line, "deviceName")) |idx| {
                const gpu_info = std.mem.trim(
                    u8,
                    line[idx + "deviceName".len ..],
                    " :\t"
                );
                return try allocator.dupe(u8, gpu_info);
            }
        }
    } else |_| {}

    // --- 4. Try sysfs (/sys/class/drm) ---
    if (std.fs.cwd().openFile("/sys/class/drm/card0/device/vendor", .{})) |vendor_file| {
        defer vendor_file.close();
        if (std.fs.cwd().openFile("/sys/class/drm/card0/device/device", .{})) |device_file| {
            defer device_file.close();

            const vendor = try vendor_file.readToEndAlloc(allocator, 16);
            defer allocator.free(vendor);
            const device = try device_file.readToEndAlloc(allocator, 16);
            defer allocator.free(device);

            const combined = try std.fmt.allocPrint(
                allocator,
                "PCI Vendor: {s}, Device: {s}",
                .{ std.mem.trim(u8, vendor, "\n "), std.mem.trim(u8, device, "\n ") }
            );
            return combined;
        } else |_| {}
    } else |_| {}

    // --- Fallback ---
    return try allocator.dupe(u8, "Unknown GPU");
}

fn executeCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    var result = std.ArrayListUnmanaged(u8){};
    defer result.deinit(allocator);

    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdout);

    try result.appendSlice(allocator, stdout);

    _ = try child.wait();

    return result.toOwnedSlice(allocator);
}
