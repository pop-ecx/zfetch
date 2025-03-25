const std = @import("std");
const distro = @import("distro.zig");
const system = @import("system.zig");
const ascii_art = @import("ascii_art.zig");
const machine = @import("machine.zig");
const hardware = @import("hardware.zig");
const terminal = @import("terminal.zig");
const packages = @import("package.zig");
const theme = @import("theme.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var color: []const u8 = "\x1b[38;2;135;206;250m";

    if (args.len > 1) {
        if (std.mem.eql(u8, args[1], "--red")) {
            color = "\x1b[31m";
        } else if (std.mem.eql(u8, args[1], "--green")) {
            color = "\x1b[32m";
        } else if (std.mem.eql(u8, args[1], "--yellow")) {
            color = "\x1b[33m";
        } else if (std.mem.eql(u8, args[1], "--blue")) {
            color = "\x1b[34m";
        } else if (std.mem.eql(u8, args[1], "--magenta")) {
            color = "\x1b[35m";
        } else if (std.mem.eql(u8, args[1], "--cyan")) {
            color = "\x1b[36m";
        } else if (std.mem.eql(u8, args[1], "--white")) {
            color = "\x1b[37m";
        } else if (std.mem.eql(u8, args[1], "--orange")) {
            color = "\x1b[38;5;208m";
        } else if (std.mem.eql(u8, args[1], "--purple")) {
            color = "\x1b[38;5;54m";
        }
    }

    // distro info
    const distro_info = try distro.getDistroInfo(allocator);
    defer allocator.free(distro_info);

    // Parse distro name
    const distro_name = try distro.parseDistroName(allocator, distro_info);
    defer allocator.free(distro_name);

    // sys info
    const desktop_env = std.posix.getenv("DESKTOP_SESSION") orelse "Unknown";

    const kernel_version = try system.executeCommand(allocator, &[_][]const u8{ "uname", "-r" });
    defer allocator.free(kernel_version);

    const shell_version = try system.getShellVersion(allocator);
    defer allocator.free(shell_version);

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

    //installed packages count
    const package_count = try packages.getInstalledPackagesCount(allocator);

    //gtk settings icons and theme
    const gtk_settings = try theme.getGtkSettings(allocator);
    defer {
        allocator.free(gtk_settings.theme);
        allocator.free(gtk_settings.icons);
    }

    // Print ASCII art n sys info
    try ascii_art.printNeofetchStyle(distro_name, desktop_env, kernel_version, uptime, shell_version, hardware_model, cpu, gpu, terminal_name, memory_info, user_at_hostname, package_count, gtk_settings.theme, gtk_settings.icons, color);
}
