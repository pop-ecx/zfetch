const std = @import("std");

const GtkSettings = struct {
    theme: []u8,
    icons: []u8,
};

pub fn getGtkSettings(allocator: std.mem.Allocator) !GtkSettings {
    const home_dir = std.os.getenv("HOME") orelse return error.HomeDirNotFound;

    // let's check the following common paths for the gtk settings file
    const paths_to_try = [_][]const u8{
        try std.fs.path.join(allocator, &[_][]const u8{ home_dir, ".config", "gtk-3.0", "settings.ini" }),
        "/etc/gtk-3.0/settings.ini",
        "/usr/share/gtk-3.0/settings.ini",
    };
    defer {
        // Free only the dynamically allocated path
        allocator.free(paths_to_try[0]);
    }

    for (paths_to_try) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            std.debug.print("Failed to open file: {s}, error: {}\n", .{ path, err });
            continue;
        };

        // Try to parse the settings
        const settings = parseGtkSettings(allocator, file) catch |err| {
            std.debug.print("Failed to parse file: {s}, error: {}\n", .{ path, err });
            continue;
        };

        return settings;
    }

    return error.GtkSettingsNotFound;
}

fn parseGtkSettings(allocator: std.mem.Allocator, file: std.fs.File) !GtkSettings {
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    var theme: []u8 = undefined;
    var icons: []u8 = undefined;
    var theme_found = false;
    var icons_found = false;

    var lines = std.mem.split(u8, buffer, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "gtk-theme-name=")) {
            const theme_name = line["gtk-theme-name=".len..];
            theme = try allocator.dupe(u8, std.mem.trim(u8, theme_name, "\""));
            theme_found = true;
        } else if (std.mem.startsWith(u8, line, "gtk-icon-theme-name=")) {
            const icon_name = line["gtk-icon-theme-name=".len..];
            icons = try allocator.dupe(u8, std.mem.trim(u8, icon_name, "\""));
            icons_found = true;
        }
    }

    // If the expected keys are not found, return an error
    if (!theme_found or !icons_found) {
        return error.GtkSettingsNotFound;
    }

    return GtkSettings{ .theme = theme, .icons = icons };
}
