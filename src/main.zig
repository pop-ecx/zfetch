const std = @import("std");
const fs = std.fs;
const io = std.io;
const warn = std.debug;

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

pub fn get_uptime() !void {
    //    var data: [4096]u8 = indefined;
}

fn ascii_art() !void {
    //if return value is certain os e.g parrot print parrot logo and system info
    const art =
        \\                   -`
        \\                  .o+`
        \\                 `ooo:
        \\                `+oooo:
        \\               `+oooooo:
        \\               -+oooooo+:
        \\             `/:-:++oooo+:
        \\            `/++++/+++++++:
        \\           `/++++++++++++++:
        \\          `/+++ooooooooooooo/`
        \\         ./ooosssso++osssssso+`
        \\        .oossssso-````/ossssss+`
        \\       -osssssso.      :ssssssso.
        \\      :osssssss/        osssso+++.
        \\     /ossssssss/        +ssssooo/-
        \\   `/ossssso+/:-        -:/+osssso+-
        \\  `+sso+:-`                 `.-/+oso:
        \\ `++:.                           `-/+/
        \\
    ;
    //const stdout = std.io.getStdOut().writer();
    //try stdout.print("{s}", .{art});
    std.debug.print("{s}", .{art});
}

pub fn main() !void {
    const asciiArt = ascii_art();
    const getOs = get_os();
    std.debug.print("{any}", .{asciiArt});
    std.debug.print("{any}", .{getOs});
}
