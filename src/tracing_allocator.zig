const std = @import("std");
const options = @import("tracy-options");
const c = @import("c.zig").c;
const common = @import("common.zig");

const TracingAllocator = @This();

parent: std.mem.Allocator,
name: ?[*:0]const u8 = null,

pub fn allocator(self: *TracingAllocator) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = std.mem.Allocator.noRemap, // TODO
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, len: usize, ptr_align: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const self: *TracingAllocator = @ptrCast(@alignCast(ctx));
    const result = self.parent.rawAlloc(len, ptr_align, ret_addr);
    if (!options.enable) return result;

    if (self.name) |name| {
        c.___tracy_emit_memory_alloc_named(result, len, 0, name);
    } else {
        c.___tracy_emit_memory_alloc(result, len, 0);
    }

    return result;
}

fn resize(
    ctx: *anyopaque,
    buf: []u8,
    buf_align: std.mem.Alignment,
    new_len: usize,
    ret_addr: usize,
) bool {
    const self: *TracingAllocator = @ptrCast(@alignCast(ctx));
    const result = self.parent.rawResize(buf, buf_align, new_len, ret_addr);
    if (!result) return false;

    if (!options.enable) return true;

    if (self.name) |name| {
        c.___tracy_emit_memory_free_named(buf.ptr, 0, name);
        c.___tracy_emit_memory_alloc_named(buf.ptr, new_len, 0, name);
    } else {
        c.___tracy_emit_memory_free(buf.ptr, 0);
        c.___tracy_emit_memory_alloc(buf.ptr, new_len, 0);
    }

    return true;
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, ret_addr: usize) void {
    const self: *TracingAllocator = @ptrCast(@alignCast(ctx));

    if (options.enable) {
        if (self.name) |name| {
            c.___tracy_emit_memory_free_named(buf.ptr, 0, name);
        } else {
            c.___tracy_emit_memory_free(buf.ptr, 0);
        }
    }

    self.parent.rawFree(buf, buf_align, ret_addr);
}
