const std = @import("std");

pub fn printNeofetchStyle(
    distro_name: []const u8,
    desktop_env: []const u8,
    kernel_version: []const u8,
    uptime: []const u8,
    shell_version: []const u8,
    hardware_model: []const u8,
    cpu: []const u8,
    gpu: []const u8,
    terminal_name: []const u8,
) !void {
    const logo = getDistroLogo(distro_name);

    // Split the logo into lines
    var logo_lines = std.mem.split(u8, logo, "\n");

    // Print the logo and system info side by side
    std.debug.print("{s:<50} DE/WM: {s}\n", .{ logo_lines.next().?, desktop_env });
    std.debug.print("{s:<50} Kernel Version: {s}", .{ logo_lines.next().?, kernel_version });
    std.debug.print("{s:<50} Distro: {s}\n", .{ logo_lines.next().?, distro_name });
    std.debug.print("{s:<50} Uptime: {s}", .{ logo_lines.next().?, uptime });
    std.debug.print("{s:<50} Shell: {s}\n", .{ logo_lines.next().?, shell_version });
    std.debug.print("{s:<50} Hardware Model: {s}\n", .{ logo_lines.next().?, hardware_model });
    std.debug.print("{s:<50} CPU: {s}\n", .{ logo_lines.next().?, cpu });
    std.debug.print("{s:<50} GPU: {s}\n", .{ logo_lines.next().?, gpu });
    std.debug.print("{s:<50} Terminal: {s}\n", .{ logo_lines.next().?, terminal_name });
    // Print the remaining lines of the logo (if any)
    while (logo_lines.next()) |logo_line| {
        std.debug.print("{s}\n", .{logo_line});
    }
}

fn getDistroLogo(distro_name: []const u8) []const u8 {
    // Normalize the distro name (e.g., extract "Parrot" from "Parrot Security")
    const normalized_name = normalizeDistroName(distro_name);

    const logos = std.ComptimeStringMap([]const u8, .{
        .{
            "Arch",
            \\       /\\
            \\      /  \\
            \\     /\\   \\      
            \\    /      \\
            \\   /   ,,   \\
            \\  /   |  |  -\\
            \\ /_-''    ''-_\\
            \\
        },
        .{
            "Ubuntu",
            \\          _
            \\      ---(_)
            \\     _/  ---  \\      
            \\    (_) |   |  |
            \\      \\  --- _/
            \\       ---(_)
            \\
        },
        .{
            "Debian",
            \\     _____
            \\  /  ___  \\      
            \\ |  /   \\  |
            \\ | |     | |
            \\  \\_____/  |
            \\    \\_____/
            \\
        },
        .{
            "Fedora",
            \\      _____
            \\     /   __)\\      
            \\     |  /  \\ \\
            \\  ___|  |  / /
            \\ / (_/    \\_/
            \\ \\___/
            \\
        },
        .{
            "Parrot",
            \\     _____
            \\  /  ___  \\      
            \\  |  \\_/  |
            \\  |   _   |
            \\   \\_____/
            \\
        },
    });

    // Use the normalized name to look up the logo
    return logos.get(normalized_name) orelse
        \\      .--.      
        \\     |o_o |     
        \\     |:_/ |             
        \\    //   \ \    
        \\   (|     | )   
        \\  /'\_   _/`\   
        \\  \___)=(___/
    ;
}

fn normalizeDistroName(distro_name: []const u8) []const u8 {
    // Normalize the distro name by extracting the first word (e.g., "Parrot" from "Parrot Security")
    if (std.mem.indexOf(u8, distro_name, " ")) |space_index| {
        return distro_name[0..space_index];
    }
    return distro_name;
}
