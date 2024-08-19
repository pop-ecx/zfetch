const std = @import("std");
const os = std.os;

pub fn checkOs() !void {
    const version = os.uname();

    std.debug.print("OS: {s}\nArch: {s}\nkernel: {s}\n", .{ version.sysname, version.machine, version.release });
}
