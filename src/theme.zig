const std = @import("std");

// Define a common struct for the return type
const GtkSettings = struct {
    theme: []u8,
    icons: []u8,
};

pub fn getGtkSettings(allocator: std.mem.Allocator) !GtkSettings {
    const home_dir = std.os.getenv("HOME") orelse return error.HomeDirNotFound;
    const gtk3_path = try std.fs.path.join(allocator, &[_][]const u8{ home_dir, ".config", "gtk-3.0", "settings.ini" });
    defer allocator.free(gtk3_path);

    const file = std.fs.cwd().openFile(gtk3_path, .{}) catch {
        // If GTK 3 settings file doesn't exist, try GTK 4
        const gtk4_path = try std.fs.path.join(allocator, &[_][]const u8{ home_dir, ".config", "gtk-4.0", "settings.ini" });
        defer allocator.free(gtk4_path);

        const file = std.fs.cwd().openFile(gtk4_path, .{}) catch return error.GtkSettingsNotFound;
        return try parseGtkSettings(allocator, file);
    };
    return try parseGtkSettings(allocator, file);
}

fn parseGtkSettings(allocator: std.mem.Allocator, file: std.fs.File) !GtkSettings {
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    var theme: []u8 = undefined;
    var icons: []u8 = undefined;

    var lines = std.mem.split(u8, buffer, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "gtk-theme-name=")) {
            const theme_name = line["gtk-theme-name=".len..];
            theme = try allocator.dupe(u8, std.mem.trim(u8, theme_name, "\""));
        } else if (std.mem.startsWith(u8, line, "gtk-icon-theme-name=")) {
            const icon_name = line["gtk-icon-theme-name=".len..];
            icons = try allocator.dupe(u8, std.mem.trim(u8, icon_name, "\""));
        }
    }

    if (theme.len == 0 or icons.len == 0) {
        return error.GtkSettingsNotFound;
    }

    return GtkSettings{ .theme = theme, .icons = icons };
}
