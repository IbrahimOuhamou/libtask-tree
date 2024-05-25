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
    const allocator: *std.mem.Allocator = lua.toUserdata(std.mem.Allocator, 1) catch {
        lua.pushFail();
        return 1;
    };

    const task: *Task = Task.new(allocator.*) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushLightUserdata(task);
    return 1;
}

pub fn taskGetName(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };

    _ = lua.pushString(task.getName());
    return 1;
}

pub fn taskGetId(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };
    lua.pushInteger(task.*.getId());
    return 1;
}

pub fn taskGetProgress(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushInteger(task.getProgress());
    return 1;
}

pub fn taskHasParentId(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(task.hasParentId(@intCast(id)));
    return 1;
}

pub fn taskHasChildId(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(task.hasChildId(@intCast(id)));
    return 1;
}

pub fn taskHasPreviousId(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(task.hasPreviousId(@intCast(id)));
    return 1;
}

pub fn taskHasNextId(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(task.hasNextId(@intCast(id)));
    return 1;
}

pub fn initState(lua: *Lua, tlist: *Tlist) void {
    // this is the module table
    lua.newTable();
    const module_table_index = lua.getTop();

    {
        //this is the module.Task table
        lua.newTable();
        defer lua.setField(module_table_index, "Task");

        const task_table_index = lua.getTop();

        lua.pushFunction(ziglua.wrap(taskNew));
        lua.setField(task_table_index, "new");

        lua.pushFunction(ziglua.wrap(taskGetName));
        lua.setField(task_table_index, "getName");

        lua.pushFunction(ziglua.wrap(taskGetId));
        lua.setField(task_table_index, "getId");

        lua.pushFunction(ziglua.wrap(taskGetProgress));
        lua.setField(task_table_index, "getProgress");

        lua.pushFunction(ziglua.wrap(taskHasParentId));
        lua.setField(task_table_index, "hasParentId");

        lua.pushFunction(ziglua.wrap(taskHasChildId));
        lua.setField(task_table_index, "hasChildId");

        lua.pushFunction(ziglua.wrap(taskHasPreviousId));
        lua.setField(task_table_index, "hasPreviousId");

        lua.pushFunction(ziglua.wrap(taskHasNextId));
        lua.setField(task_table_index, "hasNextId");
    }
    lua.setGlobal("TaskTree");

    lua.pushLightUserdata(tlist);
    //TODO: metatable of tlist
    lua.setGlobal("tlist");

    lua.pushLightUserdata(&tlist.allocator);
    lua.setGlobal("allocator");
}

test "bismi_allah" {
    const allocator = std.testing.allocator;
    const lua = try Lua.init(&allocator);
    defer Lua.deinit(lua);

    const tlist = try Tlist.new(std.testing.allocator);
    initState(lua, tlist);

    lua.doString(
        \\task0 = TaskTree.Task.new(allocator)
        \\
    ) catch {
        std.debug.print("alhamdo li Allah error: {s}\n", .{try lua.toString(-1)});
    };

    _ = try lua.getGlobal("task0");
    allocator.destroy(try lua.toUserdata(Task, -1));

    try tlist.free();
    allocator.destroy(tlist);
}
