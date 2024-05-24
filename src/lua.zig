//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah

//! in the name of Allah
//! this is planned to be lua bindings

const std = @import("std");
const ziglua = @import("ziglua");
const Lua = ziglua.Lua;

const Tlist = @import("tlist.zig").Tlist;
const Task = @import("task.zig").Task;

pub fn taskNew(lua: *Lua) i32 {
    const allocator: *std.mem.Allocator = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));

    const task: *Task = Task.new(allocator.*) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushLightUserdata(task);
    return 1;
}

pub fn taskGetName(lua: *Lua) i32 {
    const task: *Task = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));

    lua.pushString(task.getName());
    return 1;
}

pub fn taskGetId(lua: *Lua) i32 {
    const task: **const Task = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));
    lua.pushInteger(task.*.getId());
    return 1;
}

pub fn taskGetProgress(lua: *Lua) i32 {
    const task: *Task = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));

    lua.pushInteger(task.getProgress());
    return 1;
}

pub fn taskHasParentId(lua: *Lua) i32 {
    const task: *Task = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(task.hasParentId(id));
    return 1;
}

pub fn taskHasChildId(lua: *Lua) i32 {
    const task: *Task = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushInteger(task.hasChildId(id));
    return 1;
}

pub fn taskHasPreviousId(lua: *Lua) i32 {
    const task: *Task = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(task.hasPreviousId(id));
    return 1;
}

pub fn taskHasNextId(lua: *Lua) i32 {
    const task: *Task = @alignCast(@ptrCast(lua.toPointer(1) catch {
        lua.pushFail();
        return 1;
    }));

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(task.hasNextId(id));
    return 1;
}

pub fn initState(lua: *Lua, tlist: *Tlist, allocator: std.mem.Allocator) void {
    // this is the module table
    lua.newTable();
    const module_table_index = lua.getTop();

    // this is a helper struct to loop to push zigFn to lua and reduce typos
    const FunctionName = struct { func: *const ziglua.ZigFn, name: [:0]const u8 };

    {
        //this is the module.Task table
        lua.newTable();
        defer lua.setField(module_table_index, "Task");

        const task_table_index = lua.getTop();

        const functions_arr: []const FunctionName = &[_]FunctionName{
            .{ .func = taskNew, .name = "new" },
            .{ .func = taskGetName, .name = "getName" },
            .{ .func = taskGetId, .name = "getId" },
            .{ .func = taskGetProgress, .name = "getProgress" },
            .{ .func = taskHasParentId, .name = "hasParentId" },
            .{ .func = taskHasChildId, .name = "hasChildId" },
            .{ .func = taskHasPreviousId, .name = "hasPreviousId" },
            .{ .func = taskHasNextId, .name = "hasNextId" },
        };

        for (functions_arr) |function_name_pair| {
            lua.pushFunction(ziglua.wrap(function_name_pair.func));
            lua.setField(task_table_index, function_name_pair.name);
        }
    }
    lua.setGlobal("TaskTree");

    lua.pushLightUserdata(tlist);
    //TODO: metatable of tlist
    lua.setGlobal("tlist");

    lua.pushLightUserdata(&allocator);
    lua.setGlobal("allocator");
}

test "bismi_allah" {
    const allocator = std.testing.allocator;
    const lua = try Lua.init(&allocator);
    defer Lua.deinit(lua);

    const tlist = try Tlist.new(std.testing.allocator);
    initState(lua, tlist, allocator);

    try lua.doString(
        \\tlist.addTask(TaskTree.Task.new(allocator))
        \\
    );

    try tlist.free();
}
