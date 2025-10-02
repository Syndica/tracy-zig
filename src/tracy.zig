const std = @import("std");
const builtin = @import("builtin");
const options = @import("tracy-options");

const c = @import("c.zig").c;
const common = @import("common.zig");

pub const Zone = @import("zone.zig");
pub const Lockable = @import("lockable.zig");
pub const TracingAllocator = @import("tracing_allocator.zig");

pub fn startupProfiler() void {
    if (!options.enable or !options.manual_lifetime) return;

    c.___tracy_startup_profiler();
}

pub fn shutdownProfiler() void {
    if (!options.enable or !options.manual_lifetime) return;

    c.___tracy_shutdown_profiler();
}

pub fn isConnected() bool {
    if (!options.enable) return false;

    return c.___tracy_connected() > 0;
}

pub fn setThreadName(name: [*:0]const u8) void {
    if (!options.enable) return;

    c.___tracy_set_thread_name(name);
}

pub fn frameMark() void {
    if (!options.enable) return;

    c.___tracy_emit_frame_mark(null);
}

pub fn frameMarkNamed(comptime name: [*:0]const u8) void {
    if (!options.enable) return;

    c.___tracy_emit_frame_mark(name);
}

const DiscontinuousFrame = struct {
    name: [*:0]const u8,

    pub fn init(comptime name: [*:0]const u8) DiscontinuousFrame {
        if (!options.enable) return .{ .name = name };

        c.___tracy_emit_frame_mark_start(name);
        return .{ .name = name };
    }

    pub fn deinit(frame: *const DiscontinuousFrame) void {
        if (!options.enable) return;

        c.___tracy_emit_frame_mark_end(frame.name);
    }
};

pub fn frameImage(image: *anyopaque, width: u16, height: u16, offset: u8, flip: bool) void {
    if (!options.enable) return;

    c.___tracy_emit_frame_mark_image(image, width, height, offset, @as(c_int, @intFromBool(flip)));
}

pub fn plot(comptime T: type, name: [*:0]const u8, value: T) void {
    if (!options.enable) return;

    const type_info = @typeInfo(T);
    switch (type_info) {
        .int => |int_type| {
            if (int_type.bits > 64) @compileError("Too large int to plot");
            if (int_type.signedness == .unsigned and int_type.bits > 63) @compileError("Too large unsigned int to plot");
            c.___tracy_emit_plot_int(name, value);
        },
        .float => |float_type| {
            if (float_type.bits <= 32) {
                c.___tracy_emit_plot_float(name, value);
            } else if (float_type.bits <= 64) {
                c.___tracy_emit_plot(name, value);
            } else {
                @compileError("Too large float to plot");
            }
        },
        else => @compileError("Unsupported plot value type"),
    }
}

pub const PlotType = enum(c_int) {
    Number,
    Memory,
    Percentage,
    Watt,
};

pub const PlotConfig = struct {
    plot_type: PlotType,
    step: c_int,
    fill: c_int,
    color: u32,
};

pub fn plotConfig(comptime name: [*:0]const u8, comptime config: PlotConfig) void {
    if (!options.enable) return;

    c.___tracy_emit_plot_config(
        name,
        @intFromEnum(config.plot_type),
        config.step,
        config.fill,
        config.color,
    );
}

pub fn message(comptime msg: [*:0]const u8) void {
    if (!options.enable) return;

    const depth = options.callstack orelse 0;
    c.___tracy_emit_messageL(msg, depth);
}

pub fn messageColor(comptime msg: [*:0]const u8, color: u32) void {
    if (!options.enable) return;

    const depth = options.callstack orelse 0;
    c.___tracy_emit_messageLC(msg, color, depth);
}

const tracy_message_buffer_size = if (options.enable) 4096 else 0;
threadlocal var tracy_message_buffer: [tracy_message_buffer_size]u8 = undefined;

pub fn print(comptime fmt: []const u8, args: anytype) void {
    if (!options.enable) return;

    const depth = options.callstack orelse 0;

    var stream = std.io.fixedBufferStream(&tracy_message_buffer);
    stream.writer().print(fmt, args) catch {};

    const written = stream.getWritten();
    c.___tracy_emit_message(written.ptr, written.len, depth);
}

pub fn printColor(comptime fmt: []const u8, args: anytype, color: u32) void {
    if (!options.enable) return;

    const depth = options.callstack orelse 0;

    var stream = std.io.fixedBufferStream(&tracy_message_buffer);
    stream.writer().print(fmt, args) catch {};

    const written = stream.getWritten();
    c.___tracy_emit_messageC(written.ptr, written.len, color, depth);
}

pub fn printAppInfo(comptime fmt: []const u8, args: anytype) void {
    if (!options.enable) return;

    var stream = std.io.fixedBufferStream(&tracy_message_buffer);
    stream.reset();
    stream.writer().print(fmt, args) catch {};

    const written = stream.getWritten();
    c.___tracy_emit_message_appinfo(written.ptr, written.len);
}
