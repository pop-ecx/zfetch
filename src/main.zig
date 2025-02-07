const std = @import("std");
const distro = @import("distro.zig");
const system = @import("system.zig");
const ascii_art = @import("ascii_art.zig");
const machine = @import("machine.zig");
const hardware = @import("hardware.zig");
const terminal = @import("terminal.zig");

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
    defer allocator.free(kernel_version);

    const shell_version = try system.getShellVersion(allocator);

    const uptime = try system.executeCommand(allocator, &[_][]const u8{ "uptime", "-p" });
    defer allocator.free(uptime);

    //read hardware model
    const hardware_model = try machine.getHardwareModel(allocator);
    defer allocator.free(hardware_model);

    //cpu info
    const cpu = try hardware.getCPUInfo(allocator);
    defer allocator.free(cpu);

    //GPU info
    const gpu = try hardware.getGPUInfo(allocator);
    defer allocator.free(gpu);

    //Terminal info
    const terminal_name = try terminal.getTerminal(allocator);
    defer allocator.free(terminal_name);

    //memory info
    const memory_info = try system.getMemoryInfo(allocator);
    defer allocator.free(memory_info);

    //user at hostname
    const user_at_hostname = try system.userAndHostname(allocator);
    defer allocator.free(user_at_hostname);

    // Print ASCII art and system info in Neofetch style
    try ascii_art.printNeofetchStyle(distro_name, desktop_env, kernel_version, uptime, shell_version, hardware_model, cpu, gpu, terminal_name, memory_info, user_at_hostname);
}
