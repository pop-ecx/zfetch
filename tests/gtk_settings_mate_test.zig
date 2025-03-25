const std = @import("std");
const testing = std.testing;

const GtkSettings = struct {
    theme: []u8,
    icons: []u8,
};

fn mockRunCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
    if (argv.len < 4) return error.CommandFailed;

    if (std.mem.eql(u8, argv[3], "gtk-theme")) {
        return allocator.dupe(u8, "'ARK-Dark'");
    } else if (std.mem.eql(u8, argv[3], "icon-theme")) {
        return allocator.dupe(u8, "'ARK-Dark'");
    }

    return error.CommandFailed;
}

test "getGtkSettingsFromGsettings retrieves theme and icon names" {
    var gpa = std.testing.allocator;

    const settings = try getGtkSettingsFromGsettings(gpa, mockRunCommand);
    defer gpa.free(settings.theme);
    defer gpa.free(settings.icons);

    try testing.expectEqualStrings("ARK-Dark", settings.theme);
    try testing.expectEqualStrings("ARK-Dark", settings.icons);
}

fn getGtkSettingsFromGsettings(
    allocator: std.mem.Allocator,
    runCmd: fn (std.mem.Allocator, []const []const u8) anyerror![]u8,
) !GtkSettings {
    const theme_result = try runCmd(allocator, &[_][]const u8{ "gsettings", "get", "org.mate.interface", "gtk-theme" });
    defer allocator.free(theme_result);

    const icons_result = try runCmd(allocator, &[_][]const u8{ "gsettings", "get", "org.mate.interface", "icon-theme" });
    defer allocator.free(icons_result);

    const theme = try allocator.dupe(u8, std.mem.trim(u8, theme_result, " '"));
    const icons = try allocator.dupe(u8, std.mem.trim(u8, icons_result, " '"));

    return GtkSettings{ .theme = theme, .icons = icons };
}
