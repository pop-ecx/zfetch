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
    const memory_info = try system.executeCommand(allocator, &[_][]const u8{ "free", "-h" });
    defer allocator.free(memory_info);
    const storage_info = try system.executeCommand(allocator, &[_][]const u8{ "df", "-h" });
    defer allocator.free(storage_info);
    const desktop_env = std.os.getenv("DESKTOP_SESSION") orelse "Unknown";
    const kernel_version = try system.executeCommand(allocator, &[_][]const u8{ "uname", "-r" });
    defer allocator.free(kernel_version);

    // Print ASCII art and system info in Neofetch style
    try ascii_art.printNeofetchStyle(distro_name, memory_info, storage_info, desktop_env, kernel_version);
}
