const options = @import("tracy-options");
const std = @import("std");

pub const c = @cImport({
    @cDefine("TRACY_ENABLE", {});
    if (options.on_demand) @cDefine("TRACY_ON_DEMAND", {});
    if (options.callstack) |depth| @cDefine(std.fmt.comptimePrint("TRACY_CALLSTACK \"{d}\"", .{depth}), {});
    if (options.no_callstack) @cDefine("TRACY_NO_CALLSTACK", {});
    if (options.no_callstack_inlines) @cDefine("TRACY_NO_CALLSTACK_INLINES", {});
    if (options.only_localhost) @cDefine("TRACY_ONLY_LOCALHOST", {});
    if (options.no_broadcast) @cDefine("TRACY_NO_BROADCAST", {});
    if (options.only_ipv4) @cDefine("TRACY_ONLY_IPV4", {});
    if (options.no_code_transfer) @cDefine("TRACY_NO_CODE_TRANSFER", {});
    if (options.no_context_switch) @cDefine("TRACY_NO_CONTEXT_SWITCH", {});
    if (options.no_exit) @cDefine("TRACY_NO_EXIT", {});
    if (options.no_sampling) @cDefine("TRACY_NO_SAMPLING", {});
    if (options.no_verify) @cDefine("TRACY_NO_VERIFY", {});
    if (options.no_vsync_capture) @cDefine("TRACY_NO_VSYNC_CAPTURE", {});
    if (options.no_frame_image) @cDefine("TRACY_NO_FRAME_IMAGE", {});
    if (options.no_system_tracing) @cDefine("TRACY_NO_SYSTEM_TRACING", {});
    if (options.delayed_init) @cDefine("TRACY_DELAYED_INIT", {});
    if (options.manual_lifetime) @cDefine("TRACY_MANUAL_LIFETIME", {});
    if (options.fibers) @cDefine("TRACY_FIBERS", {});
    if (options.no_crash_handler) @cDefine("TRACY_NO_CRASH_HANDLER", {});
    if (options.timer_fallback) @cDefine("TRACY_TIMER_FALLBACK", {});
    // if (options.shared and builtin.os.tag == .windows) @cDefine("    ", {});

    @cInclude("tracy/tracy/TracyC.h");
});
