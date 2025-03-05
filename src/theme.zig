const std = @import("std");

const GtkSettings = struct {
    theme: []u8,
    icons: []u8,
};

pub fn getGtkSettings(allocator: std.mem.Allocator) !GtkSettings {
    const xdg_config_home = std.os.getenv("XDG_CONFIG_HOME") orelse {
        const home_dir = std.os.getenv("HOME") orelse return error.HomeDirNotFound;
        const config_dir = try std.fs.path.join(allocator, &[_][]const u8{ home_dir, ".config" });
        defer allocator.free(config_dir);
        const gtk3_path = try std.fs.path.join(allocator, &[_][]const u8{ config_dir, "gtk-3.0", "settings.ini" });
        defer allocator.free(gtk3_path);

        const file = std.fs.cwd().openFile(gtk3_path, .{}) catch |err| {
            std.debug.print("Failed to open file: {s}, error: {}\n", .{ gtk3_path, err });
            return error.GtkSettingsNotFound;
        };
        return try parseGtkSettings(allocator, file);
    };

    const paths_to_try = [_][]const u8{
        try std.fs.path.join(allocator, &[_][]const u8{ xdg_config_home, "gtk-3.0", "settings.ini" }),
        "/etc/gtk-3.0/settings.ini",
        "/usr/share/gtk-3.0/settings.ini",
    };
    defer {
        for (paths_to_try) |path| {
            // Only free dynamically allocated paths
            if (!std.mem.eql(u8, path, "/etc/gtk-3.0/settings.ini") and
                !std.mem.eql(u8, path, "/usr/share/gtk-3.0/settings.ini"))
            {
                allocator.free(path);
            }
        }
    }

    for (paths_to_try) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            std.debug.print("Failed to open file: {s}, error: {}\n", .{ path, err });
            continue;
        };
        return try parseGtkSettings(allocator, file);
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

    if (!theme_found or !icons_found) {
        return error.GtkSettingsNotFound;
    }

    return GtkSettings{ .theme = theme, .icons = icons };
}
