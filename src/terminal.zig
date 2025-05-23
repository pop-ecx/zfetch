const std = @import("std");

pub fn getTerminal(allocator: std.mem.Allocator) ![]u8 {
    var pid = std.os.linux.getpid();

    while (true) {
        const stat_path = try std.fmt.allocPrint(allocator, "/proc/{}/stat", .{pid});
        defer allocator.free(stat_path);

        const stat_file = try std.fs.openFileAbsolute(stat_path, .{});
        defer stat_file.close();

        var stat_buf: [1024]u8 = undefined;
        const stat_len = try stat_file.readAll(&stat_buf);
        const stat_str = stat_buf[0..stat_len];

        const ppid = try parsePpidFromStat(stat_str);

        const cmdline_path = try std.fmt.allocPrint(allocator, "/proc/{}/cmdline", .{pid});
        defer allocator.free(cmdline_path);

        const cmdline_file = try std.fs.openFileAbsolute(cmdline_path, .{});
        defer cmdline_file.close();

        var cmdline_buf: [1024]u8 = undefined;
        const cmdline_len = try cmdline_file.readAll(&cmdline_buf);
        const cmdline_str = cmdline_buf[0..cmdline_len];

        const process_name = std.mem.sliceTo(cmdline_str, 0);
        //without this, matching the process with terminal emulator
        //name will fail resulting in the default value of xterm-256color
        const basename = std.fs.path.basename(process_name);

        // Check the basename first
        if (isTerminalEmulator(basename)) {
            return try allocator.dupe(u8, basename);
        }

        // Split cmdline into arguments and check each
        // we do this because the terminator cmdline process
        // has an argument which is what we have to use to identify terminator
        var args_iter = std.mem.splitSequence(u8, cmdline_str, &[_]u8{0});
        while (args_iter.next()) |arg| {
            if (arg.len == 0) continue; // Skip empty args (trailing nulls)
            const arg_basename = std.fs.path.basename(arg);
            if (isTerminalEmulator(arg_basename)) {
                return try allocator.dupe(u8, arg_basename);
            }
        }

        if (ppid == 0) {
            return try allocator.dupe(u8, "xterm-256color");
        }
        pid = ppid;
    }
}

fn parsePpidFromStat(stat_str: []const u8) !i32 {
    var iter = std.mem.splitSequence(u8, stat_str, " ");
    _ = iter.next();
    const executable_name = iter.next() orelse return error.InvalidStatFile;
    if (std.mem.endsWith(u8, executable_name, ")")) {
        _ = iter.next();
        const ppid_str = iter.next() orelse return error.InvalidStatFile;
        return std.fmt.parseInt(i32, ppid_str, 10);
    } else {
        while (iter.next()) |field| {
            if (std.mem.endsWith(u8, field, ")")) {
                _ = iter.next();
                const ppid_str = iter.next() orelse return error.InvalidStatFile;
                return std.fmt.parseInt(i32, ppid_str, 10);
            }
        }
        return error.InvalidStatFile;
    }
}

fn isTerminalEmulator(process_name: []const u8) bool {
    const terminal_emulators = [_][]const u8{ "alacritty", "kitty", "gnome-terminal", "xterm", "konsole", "urxvt", "st", "terminator", "tilix", "xfce4-terminal", "tmux", "screen", "terminology", "lxterminal", "rxvt", "sakura", "mate-terminal", "terminology", "konsole", "terminator" };
    for (terminal_emulators) |emulator| {
        if (std.mem.eql(u8, process_name, emulator)) {
            return true;
        }
    }
    return false;
}
