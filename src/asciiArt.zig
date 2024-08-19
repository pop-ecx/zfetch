const std = @import("std");

pub fn ascii_art() void {
    //if return value is certain os e.g parrot print parrot logo and system info
    const art =
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
        \\                      +MMMMMMMo  :sNh.     
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
    ;

    //const stdout = std.io.getStdOut().writer();
    //try stdout.print("{s}", .{art});
    std.debug.print("{s}", .{art});
}
