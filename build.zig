const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tracy_config = TracyConfig.fromBuild(b);
    const tracy_options_module = tracy_config.makeOptions(b).createModule();
    const upstream = b.dependency("tracy", .{});

    const tracy = b.addModule("tracy", .{
        .root_source_file = b.path("./src/tracy.zig"),
        .imports = &.{
            .{ .name = "tracy-options", .module = tracy_options_module },
        },
        .sanitize_c = false, // tracy has some UB :(
    });

    const libtracy = b.addStaticLibrary(.{
        .name = "tracy",
        .target = target,
        .optimize = optimize,
    });
    libtracy.linkLibC();
    libtracy.linkLibCpp();

    libtracy.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "public/TracyClient.cpp",
            "public/client/TracyProfiler.cpp",
        },
        .flags = &.{},
    });
    libtracy.root_module.sanitize_c = false;

    libtracy.addIncludePath(upstream.path("public/tracy"));
    libtracy.installHeader(upstream.path("public/tracy/TracyC.h"), "tracy/tracy/TracyC.h");
    const hopt: std.Build.Step.Compile.HeaderInstallation.Directory.Options = .{
        .include_extensions = &.{ ".h", ".hpp" },
    };
    libtracy.installHeadersDirectory(upstream.path("public/client"), "tracy/client", hopt);
    libtracy.installHeadersDirectory(upstream.path("public/common"), "tracy/common", hopt);

    tracy_config.intoModule(libtracy.root_module);

    if (tracy_config.enable) tracy.linkLibrary(libtracy);

    if (target.result.os.tag == .windows) {
        libtracy.linkSystemLibrary("dbghelp");
        libtracy.linkSystemLibrary("ws2_32");
    }

    b.installArtifact(libtracy);
}

/// matches tracy's cmake
const TracyConfig = struct {
    enable: bool,
    on_demand: bool,
    callstack: ?u8,
    no_callstack: bool,
    no_callstack_inlines: bool,
    only_localhost: bool,
    no_broadcast: bool,
    only_ipv4: bool,
    no_code_transfer: bool,
    no_context_switch: bool,
    no_exit: bool,
    no_sampling: bool,
    no_verify: bool,
    no_vsync_capture: bool,
    no_frame_image: bool,
    no_system_tracing: bool,
    patchable_nopsleds: bool,
    delayed_init: bool,
    manual_lifetime: bool,
    fibers: bool,
    no_crash_handler: bool,
    timer_fallback: bool,
    libunwind_backtrace: bool,
    symbol_offline_resolve: bool,
    libbacktrace_elf_dynload_support: bool,
    debuginfod: bool,
    verbose: bool,
    demangle: bool,

    fn fromBuild(b: *std.Build) TracyConfig {
        return .{
            .enable = b.option(bool, "tracy_enable",
                \\Enable profiling
            ) orelse true,
            .on_demand = b.option(bool, "tracy_on_demand",
                \\On-demand profiling
            ) orelse false,
            .callstack = b.option(u8, "tracy_callstack",
                \\Enforce callstack collection for tracy regions
            ),
            .no_callstack = b.option(bool, "tracy_no_callstack",
                \\Disable all callstack related functionality
            ) orelse false,
            .no_callstack_inlines = b.option(bool, "tracy_no_callstack_inlines",
                \\Disables the inline functions in callstacks
            ) orelse false,
            .only_localhost = b.option(bool, "tracy_only_localhost", "Only listen on the localhost interface") orelse false,
            .no_broadcast = b.option(bool, "tracy_no_broadcast",
                \\Disable client discovery by broadcast to local network
            ) orelse false,
            .only_ipv4 = b.option(bool, "tracy_only_ipv4",
                \\Tracy will only accept connections on IPv4 addresses (disable IPv6)
            ) orelse false,
            .no_code_transfer = b.option(bool, "tracy_no_code_transfer",
                \\Disable collection of source code
            ) orelse false,
            .no_context_switch = b.option(bool, "tracy_no_context_switch",
                \\Disable capture of context switches
            ) orelse false,
            .no_exit = b.option(bool, "tracy_no_exit",
                \\Client executable does not exit until all profile data is sent to server
            ) orelse false,
            .no_sampling = b.option(bool, "tracy_no_sampling",
                \\Disable call stack sampling
            ) orelse false,
            .no_verify = b.option(bool, "tracy_no_verify",
                \\Disable zone validation for C API
            ) orelse false,
            .no_vsync_capture = b.option(bool, "tracy_no_vsync_capture",
                \\Disable capture of hardware Vsync events
            ) orelse false,
            .no_frame_image = b.option(bool, "tracy_no_frame_image",
                \\Disable the frame image support and its thread
            ) orelse false,
            .no_system_tracing = b.option(bool, "tracy_no_system_tracing",
                \\Disable systrace sampling
            ) orelse false,
            .patchable_nopsleds = b.option(bool, "tracy_patchable_nopsleds",
                \\Enable nopsleds for efficient patching by system-level tools (e.g. rr)
            ) orelse false,
            .delayed_init = b.option(bool, "tracy_delayed_init",
                \\Enable delayed initialization of the library (init on first call)
            ) orelse false,
            .manual_lifetime = b.option(bool, "tracy_manual_lifetime",
                \\Enable the manual lifetime management of the profile
            ) orelse false,
            .fibers = b.option(bool, "tracy_fibers",
                \\Enable fibers support
            ) orelse false,
            .no_crash_handler = b.option(bool, "tracy_no_crash_handler",
                \\Disable crash handling
            ) orelse false,
            .timer_fallback = b.option(bool, "tracy_timer_fallback",
                \\Use lower resolution timers
            ) orelse false,
            .libunwind_backtrace = b.option(bool, "tracy_libunwind_backtrace",
                \\Use libunwind backtracing where supported
            ) orelse false,
            .symbol_offline_resolve = b.option(bool, "tracy_symbol_offline_resolve",
                \\Instead of full runtime symbol resolution, only resolve the image path and offset to enable offline symbol resolution
            ) orelse false,
            .libbacktrace_elf_dynload_support = b.option(bool, "tracy_libbacktrace_elf_dynload_support",
                \\Enable libbacktrace to support dynamically loaded elfs in symbol resolution resolution after the first symbol resolve operation
            ) orelse false,
            .debuginfod = b.option(bool, "tracy_debuginfod",
                \\Enable debuginfod support
            ) orelse false,
            .verbose = b.option(bool, "tracy_verbose",
                \\[advanced] Verbose output from the profiler
            ) orelse false,
            .demangle = b.option(bool, "tracy_demangle",
                \\[advanced] Don't use default demangling function - You'll need to provide your own
            ) orelse false,
        };
    }

    fn makeOptions(self: TracyConfig, b: *std.Build) *std.Build.Step.Options {
        const options = b.addOptions();
        options.addOption(bool, "enable", self.enable);
        options.addOption(bool, "on_demand", self.on_demand);
        options.addOption(?u8, "callstack", self.callstack);
        options.addOption(bool, "no_callstack", self.no_callstack);
        options.addOption(bool, "no_callstack_inlines", self.no_callstack_inlines);
        options.addOption(bool, "only_localhost", self.only_localhost);
        options.addOption(bool, "no_broadcast", self.no_broadcast);
        options.addOption(bool, "only_ipv4", self.only_ipv4);
        options.addOption(bool, "no_code_transfer", self.no_code_transfer);
        options.addOption(bool, "no_context_switch", self.no_context_switch);
        options.addOption(bool, "no_exit", self.no_exit);
        options.addOption(bool, "no_sampling", self.no_sampling);
        options.addOption(bool, "no_verify", self.no_verify);
        options.addOption(bool, "no_vsync_capture", self.no_vsync_capture);
        options.addOption(bool, "no_frame_image", self.no_frame_image);
        options.addOption(bool, "no_system_tracing", self.no_system_tracing);
        options.addOption(bool, "patchable_nopsleds", self.patchable_nopsleds);
        options.addOption(bool, "delayed_init", self.delayed_init);
        options.addOption(bool, "manual_lifetime", self.manual_lifetime);
        options.addOption(bool, "fibers", self.fibers);
        options.addOption(bool, "no_crash_handler", self.no_crash_handler);
        options.addOption(bool, "timer_fallback", self.timer_fallback);
        options.addOption(bool, "libunwind_backtrace", self.libunwind_backtrace);
        options.addOption(bool, "symbol_offline_resolve", self.symbol_offline_resolve);
        options.addOption(bool, "libbacktrace_elf_dynload_support", self.libbacktrace_elf_dynload_support);
        options.addOption(bool, "debuginfod", self.debuginfod);
        options.addOption(bool, "verbose", self.verbose);
        options.addOption(bool, "demangle", self.demangle);
        return options;
    }

    fn intoModule(self: TracyConfig, tracy: *std.Build.Module) void {
        if (self.enable) tracy.addCMacro("TRACY_ENABLE", "");
        if (self.on_demand) tracy.addCMacro("TRACY_ON_DEMAND", "");
        if (self.callstack) |depth| {
            tracy.addCMacro(
                "TRACY_CALLSTACK",
                std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{depth}) catch unreachable,
            );
        }
        if (self.no_callstack) tracy.addCMacro("TRACY_NO_CALLSTACK", "");
        if (self.no_callstack_inlines) tracy.addCMacro("TRACY_NO_CALLSTACK_INLINES", "");
        if (self.only_localhost) tracy.addCMacro("TRACY_ONLY_LOCALHOST", "");
        if (self.no_broadcast) tracy.addCMacro("TRACY_NO_BROADCAST", "");
        if (self.only_ipv4) tracy.addCMacro("TRACY_ONLY_IPV4", "");
        if (self.no_code_transfer) tracy.addCMacro("TRACY_NO_CODE_TRANSFER", "");
        if (self.no_context_switch) tracy.addCMacro("TRACY_NO_CONTEXT_SWITCH", "");
        if (self.no_exit) tracy.addCMacro("TRACY_NO_EXIT", "");
        if (self.no_sampling) tracy.addCMacro("TRACY_NO_SAMPLING", "");
        if (self.no_verify) tracy.addCMacro("TRACY_NO_VERIFY", "");
        if (self.no_vsync_capture) tracy.addCMacro("TRACY_NO_VSYNC_CAPTURE", "");
        if (self.no_frame_image) tracy.addCMacro("TRACY_NO_FRAME_IMAGE", "");
        if (self.no_system_tracing) tracy.addCMacro("TRACY_NO_SYSTEM_TRACING", "");
        if (self.patchable_nopsleds) tracy.addCMacro("TRACY_PATCHABLE_NOPSLEDS", "");
        if (self.delayed_init) tracy.addCMacro("TRACY_DELAYED_INIT", "");
        if (self.manual_lifetime) tracy.addCMacro("TRACY_MANUAL_LIFETIME", "");
        if (self.fibers) tracy.addCMacro("TRACY_FIBERS", "");
        if (self.no_crash_handler) tracy.addCMacro("TRACY_NO_CRASH_HANDLER", "");
        if (self.timer_fallback) tracy.addCMacro("TRACY_TIMER_FALLBACK", "");
        if (self.libunwind_backtrace) tracy.addCMacro("TRACY_LIBUNWIND_BACKTRACE", "");
        if (self.symbol_offline_resolve) tracy.addCMacro("TRACY_SYMBOL_OFFLINE_RESOLVE", "");
        if (self.libbacktrace_elf_dynload_support) tracy.addCMacro("TRACY_LIBBACKTRACE_ELF_DYNLOAD_SUPPORT", "");
        if (self.debuginfod) tracy.addCMacro("TRACY_DEBUGINFOD", "");
        if (self.verbose) tracy.addCMacro("TRACY_VERBOSE", "");
        if (self.demangle) tracy.addCMacro("TRACY_DEMANGLE", "");
    }
};
