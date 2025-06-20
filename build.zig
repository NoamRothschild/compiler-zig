const std = @import("std");

pub fn build(b: *std.Build) void {
    const allocator = std.heap.page_allocator;
    var builder = LibraryBuilder.init(
        allocator,
        b,
        "src/main.zig",
        "compiler",
        5,
        b.standardTargetOptions(.{}),
        b.standardOptimizeOption(.{}),
    ) catch |err| {
        std.debug.print("Failed to initialize LibraryBuilder in build.zig, error: {s}\n", .{@errorName(err)});
        unreachable;
    };

    defer builder.deinit();

    builder.linkLibrary("src/lexer/root.zig", "lexer", .ALL_LIBRARIES);
    builder.linkLibrary("src/ast/root.zig", "ast", .ALL_LIBRARIES);
    builder.linkLibrary("src/parser/root.zig", "parser", .ALL_LIBRARIES);
    builder.linkLibrary("src/generator/root.zig", "generator", .ALL_LIBRARIES);
    builder.linkLibrary("src/colored/root.zig", "colored", .NO_LIBRARIES);

    builder.bake();
}

const dependsOn = enum {
    ALL_LIBRARIES,
    NO_LIBRARIES,
};

const ModuleType = struct {
    name: []const u8,
    module: *std.Build.Module,
    library_name: []const u8,
    depends: dependsOn,
};

const LibraryBuilder = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    allocator: std.mem.Allocator,
    project_name: []const u8,
    exe_mod: *std.Build.Module,

    module_count: u32 = undefined,
    i: u32 = 0,
    unit_tests: []*std.Build.Step.Run,
    modules: []ModuleType,

    pub fn init(allocator: std.mem.Allocator, b: *std.Build, root_source_file: []const u8, project_name: []const u8, module_count: u32, target: ?std.Build.ResolvedTarget, optimize: ?std.builtin.OptimizeMode) !LibraryBuilder {
        const unit_tests = try allocator.alloc(*std.Build.Step.Run, module_count);
        const modules = try allocator.alloc(ModuleType, module_count);

        // give a default value
        const real_target = target orelse b.standardTargetOptions(.{});
        const real_optimize = optimize orelse b.standardOptimizeOption(.{});

        const exe_mod = b.createModule(.{
            .root_source_file = b.path(root_source_file),
            .target = real_target,
            .optimize = real_optimize,
        });

        return LibraryBuilder{
            .b = b,
            .target = real_target,
            .optimize = real_optimize,
            .allocator = allocator,
            .project_name = project_name,
            .exe_mod = exe_mod,
            .module_count = module_count,
            .unit_tests = unit_tests,
            .modules = modules,
        };
    }

    pub fn deinit(self: *LibraryBuilder) void {
        self.allocator.free(self.unit_tests);
        defer self.allocator.free(self.modules);

        for (self.modules) |module| {
            self.allocator.free(module.library_name);
        }
    }

    pub fn linkLibrary(self: *LibraryBuilder, root_file: []const u8, import_name: []const u8, option: dependsOn) void {
        if (self.i >= self.module_count) {
            std.debug.print("module count variable too small. ({d})", .{self.module_count});
            unreachable;
        }

        const new_module = self.b.createModule(.{
            .root_source_file = self.b.path(root_file),
            .target = self.target,
            .optimize = self.optimize,
        });

        self.exe_mod.addImport(import_name, new_module);
        self.modules[self.i].module = new_module;
        self.modules[self.i].name = import_name;
        self.modules[self.i].depends = option;
        self.modules[self.i].library_name = self.libraryName(import_name) catch {
            unreachable;
        };

        const new_library = self.b.addLibrary(.{
            .linkage = .static,
            .name = self.modules[self.i].library_name,
            .root_module = new_module,
        });

        self.b.installArtifact(new_library);

        const run_new_library_unit_tests = self.b.addRunArtifact(self.b.addTest(.{
            .root_module = new_module,
        }));

        self.unit_tests[self.i] = run_new_library_unit_tests;
        self.i += 1;
    }

    pub fn bake(self: *LibraryBuilder) void {
        for (self.modules) |module| {
            for (self.modules) |module2| {
                if (module.depends == .NO_LIBRARIES) continue;
                if (std.mem.eql(u8, module.name, module2.name)) continue;
                module.module.addImport(module2.name, module2.module);
            }
        }

        const exe = self.b.addExecutable(.{
            .name = self.project_name,
            .root_module = self.exe_mod,
        });

        self.b.installArtifact(exe);

        // adding the run command to the build
        const run_cmd = self.b.addRunArtifact(exe);
        run_cmd.step.dependOn(self.b.getInstallStep());
        if (self.b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = self.b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

        // adding the testing command to the build
        const exe_unit_tests = self.b.addTest(.{
            .root_module = self.exe_mod,
        });

        const run_exe_unit_tests = self.b.addRunArtifact(exe_unit_tests);

        const test_step = self.b.step("test", "Run unit tests");
        for (self.unit_tests) |unit_test| {
            test_step.dependOn(&unit_test.step);
        }
        test_step.dependOn(&run_exe_unit_tests.step);
    }

    fn libraryName(self: *LibraryBuilder, name: []const u8) ![]const u8 {
        return std.fmt.allocPrint(self.allocator, "{s}_{s}", .{ self.project_name, name });
    }
};
