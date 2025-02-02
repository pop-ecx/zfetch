const std = @import("std");
const distro = @import("distro.zig");
const system = @import("system.zig");
const ascii_art = @import("ascii_art.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Get distro information
    const distro_info = try distro.getDistroInfo(allocator);
    defer allocator.free(distro_info);

    // Parse distro name
    const distro_name = try distro.parseDistroName(allocator, distro_info);
    defer allocator.free(distro_name);

    // Get system information
    const desktop_env = std.os.getenv("DESKTOP_SESSION") orelse "Unknown";
    const kernel_version = try system.executeCommand(allocator, &[_][]const u8{ "uname", "-r" });

    const shell_version = std.os.getenv("BASH_VERSION") orelse std.os.getenv("ZSH_VERSION") orelse "Unknown";
    defer allocator.free(kernel_version);

    const uptime = try system.executeCommand(allocator, &[_][]const u8{ "uptime", "-p" });
    defer allocator.free(uptime);

    // Print ASCII art and system info in Neofetch style
    try ascii_art.printNeofetchStyle(distro_name, desktop_env, kernel_version, uptime, shell_version);
}
