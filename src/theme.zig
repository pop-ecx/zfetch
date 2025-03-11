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
        "/etc/xdg/gtk-3.0/settings.ini",
        "/usr/share/gtk-3.0/settings.ini",
    };
    defer {
        // Free only the dynamically allocated path
        allocator.free(paths_to_try[0]);
    }

    for (paths_to_try) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            // Only print an error if the error is NOT FileNotFound
            if (err != error.FileNotFound) {
                std.debug.print("Failed to open file: {s}, error: {}\n", .{ path, err });
            }
            continue;
        };

        // Try to parse the settings
        const settings = parseGtkSettings(allocator, file) catch |err| {
            std.debug.print("Failed to parse file: {s}, error: {}\n", .{ path, err });
            continue;
        };

        return settings;
    }

    return getGtkSettingsFromGsettings(allocator);
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
        // Trim leading and trailing whitespace
        const trimmed_line = std.mem.trim(u8, line, " \t");

        if (std.mem.startsWith(u8, trimmed_line, "gtk-theme-name")) {
            const theme_part = std.mem.trim(u8, trimmed_line["gtk-theme-name".len..], " \t");
            if (theme_part.len > 0 and theme_part[0] == '=') {
                const theme_name = std.mem.trim(u8, theme_part[1..], " \t\"");
                theme = try allocator.dupe(u8, theme_name);
                theme_found = true;
            }
        } else if (std.mem.startsWith(u8, trimmed_line, "gtk-icon-theme-name")) {
            const icons_part = std.mem.trim(u8, trimmed_line["gtk-icon-theme-name".len..], " \t");
            if (icons_part.len > 0 and icons_part[0] == '=') {
                const icon_name = std.mem.trim(u8, icons_part[1..], " \t\"");
                icons = try allocator.dupe(u8, icon_name);
                icons_found = true;
            }
        }
    }

    if (!theme_found or !icons_found) {
        return error.GtkSettingsNotFound;
    }

    return GtkSettings{ .theme = theme, .icons = icons };
}

fn getGtkSettingsFromGsettings(allocator: std.mem.Allocator) !GtkSettings {
    // Run `gsettings get org.gnome.desktop.interface gtk-theme`
    // In future we can add support for other desktop environments
    const theme_result = try runCommand(allocator, &[_][]const u8{ "gsettings", "get", "org.gnome.desktop.interface", "gtk-theme" });
    defer allocator.free(theme_result);

    // Run `gsettings get org.gnome.desktop.interface icon-theme`
    const icons_result = try runCommand(allocator, &[_][]const u8{ "gsettings", "get", "org.gnome.desktop.interface", "icon-theme" });
    defer allocator.free(icons_result);

    // Remove single quotes and trim whitespace from the results
    const theme = try allocator.dupe(u8, std.mem.trim(u8, theme_result, " '"));
    const icons = try allocator.dupe(u8, std.mem.trim(u8, icons_result, " '"));

    return GtkSettings{ .theme = theme, .icons = icons };
}

fn runCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    const result = try std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = argv,
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    if (result.term.Exited != 0) {
        return error.CommandFailed;
    }

    const output = std.mem.trimRight(u8, result.stdout, "\n");
    return try allocator.dupe(u8, output);
}
