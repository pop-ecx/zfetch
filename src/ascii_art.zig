const std = @import("std");

pub fn printNeofetchStyle(
    distro_name: []const u8,
    memory_info: []const u8,
    storage_info: []const u8,
    desktop_env: []const u8,
    kernel_version: []const u8,
) !void {
    const logo = getDistroLogo(distro_name);

    // Split the logo and system info into lines
    var logo_lines = std.mem.split(u8, logo, "\n");
    var memory_lines = std.mem.split(u8, memory_info, "\n");

    // Print the logo and memory info side by side
    while (logo_lines.next()) |logo_line| {
        const memory_line = memory_lines.next() orelse "";
        std.debug.print("{s:<30} {s}\n", .{ logo_line, memory_line });
    }

    // Print additional system info below the logo
    std.debug.print("\n{s:<30} Desktop Environment: {s}\n", .{ "", desktop_env });
    std.debug.print("{s:<30} Kernel Version: {s}\n", .{ "", kernel_version });
    std.debug.print("{s:<30} Storage:\n", .{""});

    // Print storage info
    var storage_lines = std.mem.split(u8, storage_info, "\n");
    while (storage_lines.next()) |storage_line| {
        std.debug.print("{s:<30} {s}\n", .{ "", storage_line });
    }
}

fn getDistroLogo(distro_name: []const u8) []const u8 {
    const logos = std.ComptimeStringMap([]const u8, .{
        .{
            "Arch",
            \\       /\\
            \\      /  \\
            \\     /\\   \\      Arch Linux
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
            \\     _/  ---  \\      Ubuntu
            \\    (_) |   |  |
            \\      \\  --- _/
            \\       ---(_)
            \\
        },
        .{
            "Debian",
            \\     _____
            \\  /  ___  \\      Debian
            \\ |  /   \\  |
            \\ | |     | |
            \\  \\_____/  |
            \\    \\_____/
            \\
        },
        .{
            "Fedora",
            \\      _____
            \\     /   __)\\      Fedora
            \\     |  /  \\ \\
            \\  ___|  |  / /
            \\ / (_/    \\_/
            \\ \\___/
            \\
        },
        .{
            "Parrot",
            \\     _____
            \\   /  ___  \\      Parrot OS
            \\  |  \\_/  |
            \\  |   _   |
            \\   \\_____/
            \\
        },
    });

    return logos.get(distro_name) orelse
        \\      .--.      
        \\     |o_o |     Unknown Distro
        \\     |:_/ |     
        \\    //   \ \    
        \\   (|     | )   
        \\  /'\_   _/`\   
        \\  \___)=(___/  
    ;
}
