const std = @import("std");

pub fn ascii_art() void {
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