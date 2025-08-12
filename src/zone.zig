const std = @import("std");
const options = @import("tracy-options");
const c = @import("c.zig").c;
const common = @import("common.zig");

const Zone = @This();

ctx: if (options.enable) c.___tracy_c_zone_context else void,

pub const Options = struct {
    active: bool = true,
    name: ?[*:0]const u8 = null,
    color: ?u32 = null,
};

pub fn init(comptime src: std.builtin.SourceLocation, comptime opts: Options) Zone {
    if (!options.enable) return .{ .ctx = {} };

    // lifetime of this struct must outlast the function
    const src_loc = comptime common.toTracySrc(src, opts.name);

    const active: c_int = @intFromBool(opts.active);

    const maybe_depth = if (options.no_callstack) null else options.callstack;

    return if (maybe_depth) |depth|
        .{ .ctx = c.___tracy_emit_zone_begin_callstack(&src_loc, depth, active) }
    else
        .{ .ctx = c.___tracy_emit_zone_begin(&src_loc, active) };
}

pub fn deinit(zone: Zone) void {
    if (!options.enable) return;

    c.___tracy_emit_zone_end(zone.ctx);
}

pub fn name(zone: Zone, zone_name: []const u8) void {
    if (!options.enable) return;

    c.___tracy_emit_zone_name(zone.ctx, zone_name.ptr, zone_name.len);
}

pub fn text(zone: Zone, zone_text: []const u8) void {
    if (!options.enable) return;

    c.___tracy_emit_zone_text(zone.ctx, zone_text.ptr, zone_text.len);
}

pub fn color(zone: Zone, zone_color: u32) void {
    if (!options.enable) return;

    c.___tracy_emit_zone_color(zone.ctx, zone_color);
}

pub fn value(zone: Zone, zone_value: u64) void {
    if (!options.enable) return;

    c.___tracy_emit_zone_value(zone.ctx, zone_value);
}
