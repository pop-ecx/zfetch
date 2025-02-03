const std = @import("std");

pub fn printNeofetchStyle(
    distro_name: []const u8,
    desktop_env: []const u8,
    kernel_version: []const u8,
    uptime: []const u8,
    shell_version: []const u8,
    hardware_model: []const u8,
) !void {
    const logo = getDistroLogo(distro_name);

    // Split the logo into lines
    var logo_lines = std.mem.split(u8, logo, "\n");

    // Print the logo and system info side by side
    std.debug.print("{s:<30} DE/WM: {s}\n", .{ logo_lines.next().?, desktop_env });
    std.debug.print("{s:<30} Kernel Version: {s}", .{ logo_lines.next().?, kernel_version });
    std.debug.print("{s:<30} Distro: {s}\n", .{ logo_lines.next().?, distro_name });
    std.debug.print("{s:<30} Uptime: {s}", .{ logo_lines.next().?, uptime });
    std.debug.print("{s:<30} Shell: {s}\n", .{ logo_lines.next().?, shell_version });
    std.debug.print("{s:<30} Hardware Model: {s}\n", .{ logo_lines.next().?, hardware_model });

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
