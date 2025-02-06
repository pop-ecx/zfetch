const std = @import("std");

pub fn printNeofetchStyle(
    distro_name: []const u8,
    desktop_env: []const u8,
    kernel_version: []const u8,
    uptime: []const u8,
    shell_version: []const u8,
    hardware_model: []const u8,
    cpu: []const u8,
    gpu: []const u8,
    terminal_name: []const u8,
) !void {
    const logo = getDistroLogo(distro_name);

    // Split the logo into lines
    var logo_lines = std.mem.split(u8, logo, "\n");

    // Print the logo and system info side by side
    std.debug.print("{s:<50} DE/WM: {s}\n", .{ logo_lines.next().?, desktop_env });
    std.debug.print("{s:<50} Kernel Version: {s}", .{ logo_lines.next().?, kernel_version });
    std.debug.print("{s:<50} Distro: {s}\n", .{ logo_lines.next().?, distro_name });
    std.debug.print("{s:<50} Uptime: {s}", .{ logo_lines.next().?, uptime });
    std.debug.print("{s:<50} Shell: {s}\n", .{ logo_lines.next().?, shell_version });
    std.debug.print("{s:<50} Hardware Model: {s}\n", .{ logo_lines.next().?, hardware_model });
    std.debug.print("{s:<50} CPU: {s}\n", .{ logo_lines.next().?, cpu });
    std.debug.print("{s:<50} GPU: {s}\n", .{ logo_lines.next().?, gpu });
    std.debug.print("{s:<50} Terminal: {s}\n", .{ logo_lines.next().?, terminal_name });
    // Print the remaining lines of the logo (if any)
    while (logo_lines.next()) |logo_line| {
        std.debug.print("{s}\n", .{logo_line});
    }
}

fn getDistroLogo(distro_name: []const u8) []const u8 {
    // Normalize the distro name (e.g., extract "Parrot" from "Parrot Security")
    const normalized_name = normalizeDistroName(distro_name);

    const logos = std.ComptimeStringMap([]const u8, .{
        .{
            "Arch",
            \\                  .
            \\                 / \
            \\                /   \
            \\               /     \
            \\              /       \
            \\             />,       \
            \\            /  `*.      \
            \\           /      `      \
            \\          /               \
            \\         /                 \
            \\        /      ,.-+-..      \
            \\       /      ,/'   `\.      \
            \\      /      .|'     `|.   _  \
            \\     /       :|.     ,|;    `+.\
            \\    /        .\:     ;/,      "<\
            \\   /     __,--+"     "+--.__     \
            \\  /  _,+'"                 "'+._  \
            \\ /,-'                           `-.\
            \\'                                   '
        },
        .{
            "Ubuntu",
            \\                             ....
            \\              $2.',:clooo:  $1.:looooo:.
            \\           $2.;looooooooc  $1.oooooooooo'
            \\        $2.;looooool:,''.  $1:ooooooooooc
            \\       $2;looool;.         $1'oooooooooo,
            \\      $2;clool'             $1.cooooooc.  $2,,
            \\         $2...                $1......  $2.:oo,
            \\  $1.;clol:,.                        $2.loooo'
            \\ $1:ooooooooo,                        $2'ooool
            \\$1'ooooooooooo.                        $2loooo.
            \\$1'ooooooooool                         $2coooo.
            \\ $1,loooooooc.                        $2.loooo.
            \\   $1.,;;;'.                          $2;ooooc
            \\       $2...                         $2,ooool.
            \\    $2.cooooc.              $1..',,'.  $2.cooo.
            \\      $2;ooooo:.           $1;oooooooc.  $2:l.
            \\       $2.coooooc,..      $1coooooooooo.
            \\         $2.:ooooooolc:. $1.ooooooooooo'
            \\           $2.':loooooo;  $1,oooooooooc
            \\               $2..';::c'  $1.;loooo:'
        },
        .{
            "Debian",
            \\        $2_,met$$$$$$$$$$gg.
            \\     ,g$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$P.
            \\   ,g$$$$P""       """Y$$$$.".
            \\  ,$$$$P'              `$$$$$$.
            \\',$$$$P       ,ggs.     `$$$$b:
            \\`d$$$$'     ,$P"'   $1.$2    $$$$$$
            \\ $$$$P      d$'     $1,$2    $$$$P
            \\ $$$$:      $$$.   $1-$2    ,d$$$$'
            \\ $$$$;      Y$b._   _,d$P'
            \\ Y$$$$.    $1`.$2`"Y$$$$$$$$P"'
            \\ `$$$$b      $1"-.__
            \\  $2`Y$$$$b
            \\   `Y$$$$.
            \\     `$$$$b.
            \\       `Y$$$$b.
            \\         `"Y$$b._
            \\             `""""
        },
        .{
            "Fedora",
            \\             .',;::::;,'.
            \\         .';:cccccccccccc:;,.
            \\      .;cccccccccccccccccccccc;.
            \\    .:cccccccccccccccccccccccccc:.
            \\  .;ccccccccccccc;$2.:dddl:.$1;ccccccc;.
            \\ .:ccccccccccccc;$2OWMKOOXMWd$1;ccccccc:.
            \\.:ccccccccccccc;$2KMMc$1;cc;$2xMMc$1;ccccccc:.
            \\,cccccccccccccc;$2MMM.$1;cc;$2;WW:$1;cccccccc,
            \\:cccccccccccccc;$2MMM.$1;cccccccccccccccc:
            \\:ccccccc;$2oxOOOo$1;$2MMM000k.$1;cccccccccccc:
            \\cccccc;$20MMKxdd:$1;$2MMMkddc.$1;cccccccccccc;
            \\ccccc;$2XMO'$1;cccc;$2MMM.$1;cccccccccccccccc'
            \\ccccc;$2MMo$1;ccccc;$2MMW.$1;ccccccccccccccc;
            \\ccccc;$20MNc.$1ccc$2.xMMd$1;ccccccccccccccc;
            \\cccccc;$2dNMWXXXWM0:$1;cccccccccccccc:,
            \\cccccccc;$2.:odl:.$1;cccccccccccccc:,.
            \\ccccccccccccccccccccccccccccc:'.
            \\:ccccccccccccccccccccccc:;,..
            \\ ':cccccccccccccccc::;,.
        },
        .{
            "Kali",
            \\..............
            \\            ..,;:ccc,.
            \\          ......''';lxO.
            \\.....''''..........,:ld;
            \\           .';;;:::;,,.x,
            \\      ..'''.            0Xxoc:,.  ...
            \\  ....                ,ONkc;,;cokOdc',.
            \\ .                   OMo           ':${c2}dd${c1}o.
            \\                    dMc               :OO;
            \\                    0M.                 .:o.
            \\                    ;Wd
            \\                     ;XO,
            \\                       ,d0Odlc;,..
            \\                           ..',;:cdOOd::,.
            \\                                    .:d;.':;.
            \\                                       'd,  .'
            \\                                         ;l   ..
            \\                                          .o
            \\                                            c
            \\                                            .'
            \\                                            .
        },
        .{
            "Parrot",
            \\  `:oho/-`
            \\`mMMMMMMMMMMMNmmdhy-
            \\ dMMMMMMMMMMMMMMMMMMs`
            \\ +MMsohNMMMMMMMMMMMMMm/
            \\ .My   .+dMMMMMMMMMMMMMh.
            \\  +       :NMMMMMMMMMMMMNo
            \\           `yMMMMMMMMMMMMMm:
            \\             /NMMMMMMMMMMMMMy`
            \\              .hMMMMMMMMMMMMMN+
            \\                  ``-NMMMMMMMMMd-
            \\                     /MMMMMMMMMMMs`
            \\                      mMMMMMMMsyNMN/
            \\                     +MMMMMMMo  :sNh.
            \\                      `NMMMMMMm     -o/
            \\                       oMMMMMMM.
            \\                       `NMMMMMM+
            \\                        +MMd/NMh
            \\                         mMm -mN`
            \\                         /MM  `h:
            \\                          dM`   .
            \\                          :M-
            \\                           d:
            \\                           -+
            \\                            -
        },
    });

    // Use the normalized name to look up the logo
    return logos.get(normalized_name) orelse
        \\      .--.      
        \\     |o_o |     
        \\     |:_/ |             
        \\    //   \ \    
        \\   (|     | )   
        \\  /'\_   _/`\   
        \\  \___)=(___/
    ;
}

fn normalizeDistroName(distro_name: []const u8) []const u8 {
    // Normalize the distro name by extracting the first word (e.g., "Parrot" from "Parrot Security")
    if (std.mem.indexOf(u8, distro_name, " ")) |space_index| {
        return distro_name[0..space_index];
    }
    return distro_name;
}
