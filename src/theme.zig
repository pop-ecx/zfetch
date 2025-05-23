const std = @import("std");

const GtkSettings = struct {
    theme: []u8,
    icons: []u8,
};

pub fn getGtkSettings(allocator: std.mem.Allocator) !GtkSettings {
    const home_dir = std.posix.getenv("HOME") orelse return error.HomeDirNotFound;

    const paths_to_try = [_][]const u8{
        try std.fs.path.join(allocator, &[_][]const u8{ home_dir, ".config", "gtk-3.0", "settings.ini" }),
        "/etc/gtk-3.0/settings.ini",
        "/etc/xdg/gtk-3.0/settings.ini",
        "/usr/share/gtk-3.0/settings.ini",
    };
    defer allocator.free(paths_to_try[0]);

    for (paths_to_try) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            if (err != error.FileNotFound) {
                std.debug.print("Failed to open file: {s}, error: {}\n", .{ path, err });
            }
            continue;
        };

        const settings = parseGtkSettings(allocator, file) catch |err| {
            std.debug.print("Failed to parse file: {s}, error: {}\n", .{ path, err });
            continue;
        };

        return settings;
    }

    return getGtkSettingsFromGsettings(allocator) catch {
        return GtkSettings{
            .theme = try allocator.dupe(u8, "Unknown"),
            .icons = try allocator.dupe(u8, "Unknown"),
        };
    };
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

    var lines = std.mem.splitSequence(u8, buffer, "\n");
    while (lines.next()) |line| {
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
    const gnome_theme_result = runCommand(allocator, &[_][]const u8{ "gsettings", "get", "org.gnome.desktop.interface", "gtk-theme" });
    const gnome_icons_result = runCommand(allocator, &[_][]const u8{ "gsettings", "get", "org.gnome.desktop.interface", "icon-theme" });

    if (gnome_theme_result == error.CommandFailed or gnome_icons_result == error.CommandFailed) {
        const mate_theme = try runCommand(allocator, &[_][]const u8{ "gsettings", "get", "org.mate.interface", "gtk-theme" });
        defer allocator.free(mate_theme);
        const mate_icons = try runCommand(allocator, &[_][]const u8{ "gsettings", "get", "org.mate.interface", "icon-theme" });
        defer allocator.free(mate_icons);

        const theme = try allocator.dupe(u8, std.mem.trim(u8, mate_theme, " '\n"));
        const icons = try allocator.dupe(u8, std.mem.trim(u8, mate_icons, " '\n"));
        return GtkSettings{ .theme = theme, .icons = icons };
    } else {
        const gnome_theme = try gnome_theme_result;
        defer allocator.free(gnome_theme);
        const gnome_icons = try gnome_icons_result;
        defer allocator.free(gnome_icons);

        const theme = try allocator.dupe(u8, std.mem.trim(u8, gnome_theme, " '\n"));
        const icons = try allocator.dupe(u8, std.mem.trim(u8, gnome_icons, " '\n"));
        return GtkSettings{ .theme = theme, .icons = icons };
    }
}
pub fn runCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
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
