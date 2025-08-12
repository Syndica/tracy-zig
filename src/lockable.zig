const std = @import("std");
const options = @import("tracy-options");
const c = @import("c.zig").c;
const common = @import("common.zig");

const Lockable = @This();

ctx: if (options.enable) *c.__tracy_lockable_context_data else void,

pub fn announce(src: std.builtin.SourceLocation, name: ?[*:0]const u8) Lockable {
    if (!options.enable) return .{};

    return .{
        .ctx = c.___tracy_announce_lockable_ctx(&common.toTracySrc(src, name)) orelse
            @panic("wat"),
    };
}

pub fn terminate(self: *Lockable) void {
    if (!options.enable) return;

    c.___tracy_terminate_lockable_ctx(self.ctx);
}

pub fn beforeLock(self: *Lockable) void {
    if (!options.enable) return;

    _ = c.___tracy_before_lock_lockable_ctx(self.ctx);
}

pub fn afterLock(self: *Lockable) void {
    if (!options.enable) return;

    c.___tracy_after_lock_lockable_ctx(self.ctx);
}

pub fn afterUnlock(self: *Lockable) void {
    if (!options.enable) return;

    c.___tracy_after_unlock_lockable_ctx(self.ctx);
}

pub fn afterTryUnlock(self: *Lockable) void {
    if (!options.enable) return;

    c.___tracy_after_try_lock_lockable_ctx(self.ctx);
}

pub fn mark(self: *Lockable, src: std.builtin.SourceLocation, name: ?[*:0]const u8) void {
    if (!options.enable) return;

    c.___tracy_mark_lockable_ctx(self.ctx, &common.toTracySrc(src, name));
}

pub fn customName(self: *Lockable, name: []const u8) void {
    if (!options.enable) return;

    c.___tracy_custom_name_lockable_ctx(self.ctx, name.ptr, name.len);
}
