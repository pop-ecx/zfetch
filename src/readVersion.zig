const std = @import("std");
const fs = std.fs;

pub fn get_os() !void {
    const filePath = "/proc/version";
    var file = try fs.openFileAbsolute(filePath, .{ .mode = fs.File.OpenMode.read_only });
    defer file.close();

    const bufferSize: usize = 4096;
    var buffer: [bufferSize]u8 = undefined;

    while (true) {
        const bytesRead = try file.read(buffer[0..]);
        if (bytesRead == 0) break;

        // Process the read data here
        // For example, you can print it to stdout
        std.debug.print("{s}", .{buffer[0..bytesRead]});
    }
}
