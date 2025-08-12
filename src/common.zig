const std = @import("std");
const c = @import("c.zig").c;

pub fn toTracySrc(
    comptime src: std.builtin.SourceLocation,
    comptime name: ?[*:0]const u8,
) c.___tracy_source_location_data {
    if (name) |src_name| std.debug.assert(std.mem.span(src_name).len <= 65535);

    return .{
        .name = name,
        .file = src.file,
        .function = src.fn_name,
        .line = src.line,
        .color = 0,
    };
}
