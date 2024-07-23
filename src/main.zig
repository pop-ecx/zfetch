const std = @import("std");
const fs = std.fs;
const io = std.io;
const warn = std.debug;
const asciiart = @import("asciiArt.zig");
const getos = @import("readVersion.zig");
const uptime = @import("readUptime.zig");

pub fn main() void {
    const asciiArt = asciiart.ascii_art();
    const getOs = getos.get_os();
    const getUptime = uptime.get_uptime();
    std.debug.print("{any}", .{asciiArt});
    std.debug.print("{any}", .{getOs});
    std.debug.print("{any}", .{getUptime});
}
