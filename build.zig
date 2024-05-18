//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah
//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libtask_tree = b.addModule("libtask-tree", .{ .root_source_file = .{ .path = "src/lib.zig" }, .target = target, .optimize = optimize });
    _ = libtask_tree;

    const ziglua = b.dependency("ziglua", .{
        .target = target,
        .optimize = optimize,
    });
    _ = ziglua;

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const task_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/task.zig"),
        .target = target,
        .optimize = optimize,
    });
    const tlist_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tlist.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const run_task_unit_tests = b.addRunArtifact(task_unit_tests);
    const run_tlist_unit_tests = b.addRunArtifact(tlist_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_task_unit_tests.step);
    test_step.dependOn(&run_tlist_unit_tests.step);
}
