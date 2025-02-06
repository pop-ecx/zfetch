const std = @import("std");

pub fn getTerminal(allocator: std.mem.Allocator) ![]u8 {
    // Get the PID of the current process
    var pid = std.os.linux.getpid();

    // Traverse up the process tree until we find the terminal emulator
    while (true) {
        // Construct the path to the /proc/<pid>/stat file
        var stat_path = try std.fmt.allocPrint(allocator, "/proc/{}/stat", .{pid});
        defer allocator.free(stat_path);

        // Read the stat file to get the parent PID (PPID)
        const stat_file = try std.fs.openFileAbsolute(stat_path, .{});
        defer stat_file.close();

        var stat_buf: [1024]u8 = undefined;
        const stat_len = try stat_file.readAll(&stat_buf);
        const stat_str = stat_buf[0..stat_len];

        // Parse the stat file to get the PPID
        const ppid = try parsePpidFromStat(stat_str);

        // Construct the path to the /proc/<pid>/cmdline file
        var cmdline_path = try std.fmt.allocPrint(allocator, "/proc/{}/cmdline", .{pid});
        defer allocator.free(cmdline_path);

        // Read the cmdline file to get the command line of the process
        const cmdline_file = try std.fs.openFileAbsolute(cmdline_path, .{});
        defer cmdline_file.close();

        var cmdline_buf: [1024]u8 = undefined;
        const cmdline_len = try cmdline_file.readAll(&cmdline_buf);
        const cmdline_str = cmdline_buf[0..cmdline_len];

        // The first part of the cmdline is the executable name
        const process_name = std.mem.sliceTo(cmdline_str, 0);

        // Check if this process is a terminal emulator
        if (isTerminalEmulator(process_name)) {
            return try allocator.dupe(u8, process_name);
        }

        // Move up to the parent process
        if (ppid == 0) {
            return try allocator.dupe(u8, "xterm-256color");
        }
        pid = ppid;
    }
}

fn parsePpidFromStat(stat_str: []const u8) !i32 {
    var iter = std.mem.split(u8, stat_str, " ");

    // Skip the first field (PID)
    _ = iter.next();

    // The second field is the executable name, which can contain spaces and parentheses.
    // We need to find the closing parenthesis to correctly parse the PPID.
    var executable_name = iter.next() orelse return error.InvalidStatFile;
    if (std.mem.endsWith(u8, executable_name, ")")) {
        // The executable name is fully contained in this field.
        // The next field is the state, and the one after that is the PPID.
        _ = iter.next(); // Skip state
        const ppid_str = iter.next() orelse return error.InvalidStatFile;
        return std.fmt.parseInt(i32, ppid_str, 10);
    } else {
        // The executable name spans multiple fields. We need to find the closing parenthesis.
        while (iter.next()) |field| {
            if (std.mem.endsWith(u8, field, ")")) {
                // Now the next field is the state, and the one after that is the PPID.
                _ = iter.next(); // Skip state
                const ppid_str = iter.next() orelse return error.InvalidStatFile;
                return std.fmt.parseInt(i32, ppid_str, 10);
            }
        }
        return error.InvalidStatFile;
    }
}

fn isTerminalEmulator(process_name: []const u8) bool {
    const terminal_emulators = [_][]const u8{
        "alacritty", "kitty", "gnome-terminal", "xterm", "konsole", "urxvt", "st", "terminator", "tilix", "xfce4-terminal",
    };

    for (terminal_emulators) |emulator| {
        if (std.mem.eql(u8, process_name, emulator)) {
            return true;
        }
    }
    return false;
}
