//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah

//! in the name of Allah
//! this is planned to be lua bindings

const std = @import("std");
const ziglua = @import("ziglua");
const Lua = ziglua.Lua;

const Tlist = @import("tlist.zig").Tlist;
const Task = @import("task.zig").Task;

// task

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

pub fn taskSetName(lua: *Lua) i32 {
    const task: *Task = lua.toUserdata(Task, 1) catch {
        lua.pushFail();
        return 1;
    };

    var name: []u8 = @constCast(lua.toString(2) catch {
        lua.pushFail();
        return 1;
    });

    task.setName(name[0..]);
    return 0;
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

// tlist

pub fn tlistNew(lua: *Lua) i32 {
    const allocator: *std.mem.Allocator = lua.toUserdata(std.mem.Allocator, 1) catch {
        lua.pushFail();
        return 1;
    };

    const tlist: *Tlist = Tlist.new(allocator.*) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushLightUserdata(tlist);
    return 1;
}

pub fn tlistClear(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    tlist.clear() catch {
        lua.pushFail();
        return 1;
    };

    return 0;
}

pub fn tlistGetSize(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    if (null == tlist.data) {
        lua.pushNil();
    } else {
        lua.pushInteger(@intCast(tlist.data.?.len));
    }
    return 1;
}

pub fn tlistGetTask(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const task: *Task = tlist.getTask(@intCast(id)) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushLightUserdata(task);
    return 1;
}

pub fn tlistAddTask(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const task: *Task = lua.toUserdata(Task, 2) catch {
        lua.pushFail();
        return 1;
    };

    tlist.addTask(task) catch {
        lua.pushFail();
        return 1;
    };

    return 0;
}

pub fn tlistRemoveTaskById(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const update_progress = lua.toBoolean(3);

    tlist.removeTaskById(@intCast(id), update_progress) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskSetProgress(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const progress = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    const update_progress = lua.toBoolean(4);

    tlist.taskSetProgress(@intCast(id), @intCast(progress), update_progress) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskHasGrandChild(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const grand_child_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(tlist.taskHasGrandChild(@intCast(id), @intCast(grand_child_id)) catch {
        lua.pushFail();
        return 1;
    });
    return 1;
}

pub fn tlistTaskUpdateProgressFromChildren(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const update_parents = lua.toBoolean(3);

    tlist.taskUpdateProgressFromChildren(@intCast(id), update_parents) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskAddChildId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const child_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    const update_progress = lua.toBoolean(4);

    tlist.taskAddChildId(@intCast(id), @intCast(child_id), update_progress) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskRemoveChildId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const child_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    const update_progress = lua.toBoolean(4);

    tlist.taskRemoveChildId(@intCast(id), @intCast(child_id), update_progress) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskAddParentId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const parent_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    const update_progress = lua.toBoolean(4);

    tlist.taskAddParentId(@intCast(id), @intCast(parent_id), update_progress) catch {
        lua.pushFail();
        return 1;
    };

    return 0;
}

pub fn tlistTaskRemoveParentId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const parent_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    const update_progress = lua.toBoolean(4);

    tlist.taskRemoveParentId(@intCast(id), @intCast(parent_id), update_progress) catch {
        lua.pushFail();
        return 1;
    };

    return 0;
}

pub fn tlistTaskHasLaterId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const later_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    lua.pushBoolean(tlist.taskHasLaterId(@intCast(id), @intCast(later_id)) catch {
        lua.pushFail();
        return 1;
    });
    return 1;
}

pub fn tlistTaskAddNextId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const next_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    tlist.taskAddNextId(@intCast(id), @intCast(next_id)) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskRemoveNextId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const next_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    tlist.taskRemoveNextId(@intCast(id), @intCast(next_id)) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskAddPreviousId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const previous_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    tlist.taskAddPreviousId(@intCast(id), @intCast(previous_id)) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn tlistTaskRemovePreviousId(lua: *Lua) i32 {
    const tlist: *Tlist = lua.toUserdata(Tlist, 1) catch {
        lua.pushFail();
        return 1;
    };

    const id = lua.toInteger(2) catch {
        lua.pushFail();
        return 1;
    };

    const previous_id = lua.toInteger(3) catch {
        lua.pushFail();
        return 1;
    };

    tlist.taskRemovePreviousId(@intCast(id), @intCast(previous_id)) catch {
        lua.pushFail();
        return 1;
    };
    return 0;
}

pub fn initState(lua: *Lua, tlist: *Tlist) void {
    // this is the module table

    //lua.newTable();
    //const module_table_index = lua.getTop();

    {
        //this is the module.Task table
        lua.newTable();
        //defer lua.setField(module_table_index, "Task");
        defer lua.setGlobal("Task");

        const task_table_index = lua.getTop();

        lua.pushFunction(ziglua.wrap(taskNew));
        lua.setField(task_table_index, "new");

        lua.pushFunction(ziglua.wrap(taskSetName));
        lua.setField(task_table_index, "setName");

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
    {
        //this is the module.Tlist table
        lua.newTable();
        //defer lua.setField(module_table_index, "Tlist");
        defer lua.setGlobal("Tlist");

        const tlist_table_index = lua.getTop();

        lua.pushFunction(ziglua.wrap(tlistNew));
        lua.setField(tlist_table_index, "new");

        lua.pushFunction(ziglua.wrap(tlistClear));
        lua.setField(tlist_table_index, "clear");

        lua.pushFunction(ziglua.wrap(tlistGetSize));
        lua.setField(tlist_table_index, "getSize");

        lua.pushFunction(ziglua.wrap(tlistGetTask));
        lua.setField(tlist_table_index, "getTask");

        lua.pushFunction(ziglua.wrap(tlistAddTask));
        lua.setField(tlist_table_index, "addTask");

        lua.pushFunction(ziglua.wrap(tlistRemoveTaskById));
        lua.setField(tlist_table_index, "removeTaskById");

        lua.pushFunction(ziglua.wrap(tlistTaskSetProgress));
        lua.setField(tlist_table_index, "taskSetProgress");

        lua.pushFunction(ziglua.wrap(tlistTaskHasGrandChild));
        lua.setField(tlist_table_index, "taskHasGrandChild");

        lua.pushFunction(ziglua.wrap(tlistTaskUpdateProgressFromChildren));
        lua.setField(tlist_table_index, "taskUpdateProgressFromChildren");

        lua.pushFunction(ziglua.wrap(tlistTaskAddChildId));
        lua.setField(tlist_table_index, "taskAddChildId");

        lua.pushFunction(ziglua.wrap(tlistTaskRemoveChildId));
        lua.setField(tlist_table_index, "taskRemoveChildId");

        lua.pushFunction(ziglua.wrap(tlistTaskAddParentId));
        lua.setField(tlist_table_index, "taskAddParentId");

        lua.pushFunction(ziglua.wrap(tlistTaskRemoveParentId));
        lua.setField(tlist_table_index, "taskRemoveParentId");

        lua.pushFunction(ziglua.wrap(tlistTaskHasLaterId));
        lua.setField(tlist_table_index, "taskHasLaterId");

        lua.pushFunction(ziglua.wrap(tlistTaskAddNextId));
        lua.setField(tlist_table_index, "taskAddNextId");

        lua.pushFunction(ziglua.wrap(tlistTaskRemoveNextId));
        lua.setField(tlist_table_index, "taskRemoveNextId");

        lua.pushFunction(ziglua.wrap(tlistTaskAddPreviousId));
        lua.setField(tlist_table_index, "taskAddPreviousId");

        lua.pushFunction(ziglua.wrap(tlistTaskRemovePreviousId));
        lua.setField(tlist_table_index, "taskRemovePreviousId");
    }
    //lua.setGlobal("TaskTree");

    lua.pushLightUserdata(tlist);
    //TODO: metatable of tlist
    lua.setGlobal("tlist");

    lua.pushLightUserdata(&tlist.allocator);
    lua.setGlobal("allocator");
}

test "bismi_allah" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;
    const lua = try Lua.init(&allocator);
    defer Lua.deinit(lua);

    const tlist = try Tlist.new(std.testing.allocator);
    initState(lua, tlist);

    lua.doString(
        \\task0 = Task.new(allocator)
        \\Task.setName(task0, "in the name of Allah")
        \\
        \\Tlist.addTask(tlist, task0)
    ) catch {
        std.debug.print("alhamdo li Allah error: {s}\n", .{try lua.toString(-1)});
    };

    {
        _ = try lua.getGlobal("task0");
        const task0 = try lua.toUserdata(Task, -1);
        const name = [_]u8{ 'i', 'n', ' ', 't', 'h', 'e', ' ', 'n', 'a', 'm', 'e', ' ', 'o', 'f', ' ', 'A', 'l', 'l', 'a', 'h' };
        var i: usize = 0;
        while (i < task0.name.len and i < name.len) : (i += 1) {
            try expect(task0.name[i] == name[i]);
        }
    }

    try tlist.clear();
    allocator.destroy(tlist);
}

test "Tlist" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;
    const lua = try Lua.init(&allocator);
    defer Lua.deinit(lua);

    const tlist = try Tlist.new(std.testing.allocator);
    initState(lua, tlist);

    lua.doString(
        \\Tlist.addTask(tlist, Task.new(allocator))
        \\Tlist.addTask(tlist, Task.new(allocator))
        \\Tlist.addTask(tlist, Task.new(allocator))
        \\Tlist.addTask(tlist, Task.new(allocator))
        \\Tlist.addTask(tlist, Task.new(allocator))
        \\Tlist.addTask(tlist, Task.new(allocator))
        \\Tlist.removeTaskById(tlist, 0)
        \\Tlist.removeTaskById(tlist, 1)
        \\Tlist.removeTaskById(tlist, 2)
        \\Tlist.removeTaskById(tlist, 3)
        \\Tlist.removeTaskById(tlist, 4)
        \\Tlist.removeTaskById(tlist, 5)
    ) catch {
        std.debug.print("alhamdo li Allah error: {s}\n", .{try lua.toString(-1)});
    };
    for (tlist.data.?) |task| {
        try expect(null == task);
    }

    lua.doString(
        \\Tlist.clear(tlist)
    ) catch {
        std.debug.print("alhamdo li Allah error: {s}\n", .{try lua.toString(-1)});
    };
    try expect(null == tlist.data);

    allocator.destroy(tlist);
}
