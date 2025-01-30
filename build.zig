const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("ollama", .{
        .root_source_file = b.path("src/ollama.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_tests.root_module.addImport("ollama", module);
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Samples
    inline for ([_]struct {
        name: []const u8,
        src: []const u8,
    }{
        .{ .name = "chat", .src = "examples/chat/main.zig" },
        .{ .name = "generate", .src = "examples/generate/main.zig" },
        .{ .name = "ps", .src = "examples/ps/main.zig" },
        .{ .name = "tags", .src = "examples/tags/main.zig" },
    }) |execfg| {
        const exe_name = execfg.name;

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_source_file = b.path(execfg.src),
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addImport("ollama", module);

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const step_name = "run-" ++ exe_name;
        const run_step = b.step(step_name, "Run the app " ++ exe_name);
        run_step.dependOn(&run_cmd.step);
    }
}
