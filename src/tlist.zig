//بسم الله الرحمن الرحيم
//la ilaha illa Allah mohammed rassoul Allah

const std = @import("std");
pub const Task = @import("task.zig").Task;

pub const Tlist = struct {
    data: ?[]?*Task = null,
    allocator: std.mem.Allocator,

    /// the errorset of this struct:
    /// OutOfMemory:                    passed from aloocating functions
    ///
    /// OutOfBounds:                    requested an id bigger than @{tlist.data.?.len}
    /// DataIsNull:                     @{tlist.data} == null
    ///
    /// TaskDoesNotExist:               requested a deleted task @{tlist.data.?[id]} == null
    /// TaskHasChildren:                tried to set progress of task directly when it had children
    /// TaskDoesNotHaveChildren:        @{task.children_ids} == null
    /// TaskHasIncompletePreviousTasks: tried to set the task's prgress while one of its previous tasks where incomplete
    ///
    /// TaskCanNotBeGrandChildOfItSelf: tried to set a task as parent of one of its parents
    /// TaskCanNotBeNextOfItSelf:       tried to make a task next of one of its later tasks
    ///
    pub const Error = error{
        /// passed from aloocating functions
        OutOfMemory,

        /// an id bigger than @{tlist.data.?.len}
        OutOfBounds,
        /// @{tlist.data} == null
        DataIsNull,

        /// requested a deleted task @{tlist.data.?[id]} == null
        TaskDoesNotExist,
        /// tried to set progress of task directly when it had children
        TaskHasChildren,
        /// @{task.children_ids} == null
        TaskDoesNotHaveChildren,
        /// tried to set the task's prgress while one of its previous tasks where incomplete
        TaskHasIncompletePreviousTasks,

        /// tried to set a task as parent of one of its parents
        TaskCanNotBeGrandChildOfItSelf,
        /// tried to make a task next of one of its later tasks
        TaskCanNotBeNextOfItSelf,

        // InvalidOperation:
        //InvalidOperation,
    };

    /// returns a new initialized Tlist with @{allocator} as @{tlist.allocator}
    pub fn new(allocator: std.mem.Allocator) !*Tlist {
        const tlist: *Tlist = try allocator.create(Tlist);
        tlist.* = Tlist{ .allocator = allocator };
        return tlist;
    }

    /// removes all tasks int @{tlist.data} by calling 'tlist.removeTaskById(tlist.data.?.len - 1, allocator)'
    pub fn clear(tlist: *Tlist) !void {
        if (null == tlist.data) return;
        for (tlist.data.?) |task| {
            if (null == task) continue;
            tlist.removeTaskById(task.?.id, false) catch {};
        }
        tlist.allocator.free(tlist.data.?);
        tlist.data = null;
    }

    /// returns @{tlist.data[id]}
    /// if requested an id bigger than @{tlist.data.?.len} returns Error.OutOfBound
    pub fn getTask(tlist: *Tlist, id: u32) Error!*Task {
        if (null == tlist.data) return Error.DataIsNull;
        if (tlist.data.?.len <= id) return Error.OutOfBounds;
        if (null == tlist.data.?[id]) return Error.TaskDoesNotExist;
        return tlist.data.?[id].?;
    }

    /// adds @{*task} to @{tlist.data}
    /// @{task} should be an pointer to a Task object created by allocator.create()
    ///
    /// can be used with
    /// try tlist.addTask(try Task.new(allocator), allocator);
    pub fn addTask(tlist: *Tlist, task: *Task) !void {
        if (null == tlist.data) {
            tlist.data = try tlist.allocator.alloc(?*Task, 1);
        } else {
            tlist.data = try tlist.allocator.realloc(tlist.data.?, tlist.data.?.len + 1);
        }
        task.id = @truncate(tlist.data.?.len - 1);
        tlist.data.?[tlist.data.?.len - 1] = task;
    }

    /// removes @{task.id} from its parents, children, next and previous tasks
    /// frees the @{task} pointer and sets it to null
    /// removes @{task} from @{tlist}
    /// if requested an id bigger than @{tlist.data.?.len} returns Error.OutOfBounds
    /// note: it does not resize @{tlist} after freeing the task
    pub fn removeTaskById(tlist: *Tlist, id: u32, update_progress: bool) !void {
        const task = try tlist.getTask(id);

        while (null != task.parents_ids) {
            try tlist.taskRemoveParentId(id, task.parents_ids.?[0], update_progress);
        }

        while (null != task.children_ids) {
            try tlist.taskRemoveChildId(id, task.children_ids.?[0], update_progress);
        }

        while (null != task.next_tasks_ids) {
            try tlist.taskRemoveNextId(id, task.next_tasks_ids.?[0]);
        }

        while (null != task.previous_tasks_ids) {
            try tlist.taskRemovePreviousId(id, task.previous_tasks_ids.?[0]);
        }

        tlist.allocator.destroy(task);
        tlist.data.?[id] = null;
    }

    /// sets @{tlist.?.data.?[id].progress} to @{progress} if it has no children and no incomplete previous_tasks_ids
    /// orelse it returns Tlist.Error
    pub fn taskSetProgress(tlist: *Tlist, id: u32, progress: u8, update_parents_progress: bool) Error!void {
        const task: *Task = try tlist.getTask(id);
        if (null != task.children_ids) return Error.TaskHasChildren;

        if (null != task.previous_tasks_ids) {
            for (task.previous_tasks_ids.?) |previous_id| {
                const previous_task: *Task = try tlist.getTask(previous_id);
                if (previous_task.progress < 100) return Error.TaskHasIncompletePreviousTasks;
            }
        }

        tlist.data.?[id].?.setProgress(progress);

        if (false == update_parents_progress or null == task.parents_ids) return;
        for (task.parents_ids.?) |parent_id| {
            try tlist.taskUpdateProgressFromChildren(parent_id, true);
        }
    }

    /// tests if @{task} has the @{grand_child_id} else it calls itself for each of its children
    pub fn taskHasGrandChild(tlist: *Tlist, id: u32, grand_child_id: u32) Error!bool {
        const task = try tlist.getTask(id);
        if (null == task.children_ids) return false;

        if (task.hasChildId(grand_child_id)) return true;

        for (task.children_ids.?) |child_id| {
            if (tlist.taskHasGrandChild(child_id, grand_child_id)) |result| {
                if (result) return true;
            } else |e| {
                return e;
            }
        }
        return false;
    }

    /// updates @{tlist.?.data.?[id].progress} by calculating it from children
    pub fn taskUpdateProgressFromChildren(tlist: *Tlist, id: u32, update_parents: bool) Error!void {
        const task: *Task = try tlist.getTask(id);
        // if this function was called automatically and the next if is true
        // then this means that it was called when removing its last child
        if (null == task.children_ids) return;

        var progress_sum: u16 = 0;
        for (task.children_ids.?) |child_id| {
            const child: *Task = try tlist.getTask(child_id);
            progress_sum += child.progress;
        }

        const len: u16 = @truncate(task.children_ids.?.len);
        progress_sum = progress_sum / len;
        if (progress_sum > 100) progress_sum = 100;
        task.setProgress(@truncate(progress_sum));

        if (false == update_parents or null == task.parents_ids) return;
        for (task.parents_ids.?) |parent_id| {
            try tlist.taskUpdateProgressFromChildren(parent_id, true);
        }
    }

    /// adds @{child_id} to @{task.children_ids}
    /// adds @{id} to @{child.parents_ids}
    pub fn taskAddChildId(tlist: *Tlist, id: u32, child_id: u32, update_progress: bool) Error!void {
        const task = try tlist.getTask(id);
        const child = try tlist.getTask(child_id);

        if (id == child_id or try tlist.taskHasGrandChild(child_id, id)) return Error.TaskCanNotBeGrandChildOfItSelf;

        task.addChildId(child_id, tlist.allocator) catch return Error.OutOfMemory;
        child.addParentId(id, tlist.allocator) catch return Error.OutOfMemory;

        if (update_progress) try tlist.taskUpdateProgressFromChildren(id, true);
    }

    /// remove @{child_id} from @{task.children_ids}
    /// remove @{id} from @{child.parents_ids}
    pub fn taskRemoveChildId(tlist: *Tlist, id: u32, child_id: u32, update_progress: bool) Error!void {
        const task = try tlist.getTask(id);
        const child = try tlist.getTask(child_id);

        task.removeChildId(child_id, tlist.allocator) catch return Error.OutOfMemory;
        child.removeParentId(id, tlist.allocator) catch return Error.OutOfMemory;

        if (update_progress) try tlist.taskUpdateProgressFromChildren(id, true);
    }

    /// forwards the call to tlist.taskAddChildId(parent_id, id, update_progress)
    pub fn taskAddParentId(tlist: *Tlist, id: u32, parent_id: u32, update_progress: bool) Error!void {
        try tlist.taskAddChildId(parent_id, id, update_progress);
    }

    /// forwards the call tlist.taskRemoveChildId(parent_id, id, update_progress)
    pub fn taskRemoveParentId(tlist: *Tlist, id: u32, parent_id: u32, update_progress: bool) Error!void {
        try tlist.taskRemoveChildId(parent_id, id, update_progress);
    }

    /// tests if @{task} has the @{later_id} else it calls itself for each of its next tasks
    pub fn taskHasLaterId(tlist: *Tlist, id: u32, later_id: u32) Error!bool {
        const task = try tlist.getTask(id);
        if (null == task.next_tasks_ids) return false;

        if (task.hasNextId(later_id)) return true;

        for (task.next_tasks_ids.?) |next_id| {
            if (tlist.taskHasLaterId(next_id, later_id)) |result| {
                if (result) return true;
            } else |e| {
                return e;
            }
        }
        return false;
    }

    /// adds @{next_id} to @{task.next_tasks_ids}
    /// adds @{id} to @{next_task.preivious_tasks_ids}
    pub fn taskAddNextId(tlist: *Tlist, id: u32, next_id: u32) Error!void {
        const task = try tlist.getTask(id);
        const next_task = try tlist.getTask(next_id);

        if (try tlist.taskHasLaterId(next_id, id)) return Error.TaskCanNotBeNextOfItSelf;

        task.addNextId(next_id, tlist.allocator) catch return Error.OutOfMemory;
        next_task.addPreviousId(id, tlist.allocator) catch return Error.OutOfMemory;
    }

    /// remove @{next_id} from @{task.next_tasks_ids}
    /// remove @{id} from @{next_task.previous_tasks_ids}
    pub fn taskRemoveNextId(tlist: *Tlist, id: u32, next_id: u32) Error!void {
        const task = try tlist.getTask(id);
        const next_task = try tlist.getTask(next_id);

        task.removeNextId(next_id, tlist.allocator) catch return Error.OutOfMemory;
        next_task.removePreviousId(id, tlist.allocator) catch return Error.OutOfMemory;
    }

    /// adds @{previous_id} to @{task.previous_tasks_ids}
    /// adds @{id} to @{previous_task.next_tasks_ids}
    ///
    /// note: it forwards the call to tlist.taskAddNextId(previous_id, id)
    pub fn taskAddPreviousId(tlist: *Tlist, id: u32, previous_id: u32) Error!void {
        try tlist.taskAddNextId(previous_id, id);
    }

    /// remove @{previous_id} from @{task.previous_tasks_ids}
    /// remove @{id} from @{previous_task.next_tasks_ids}
    ///
    /// note: it forwards the call to tlist.taskRemoveNextId(previous_id, id)
    pub fn taskRemovePreviousId(tlist: *Tlist, id: u32, previous_id: u32) Error!void {
        try tlist.taskRemoveNextId(previous_id, id);
    }

    /// writes tlist.data to the @stream
    /// stream should have:
    /// 1- read(buffer: []u8) !somethingToBeIgnoredForNow
    ///
    /// can pass a file like:
    /// tlist.saveToStream(file)
    ///
    /// saveToStream() tries to optimize by only saving the parents and next tasks ids
    ///
    /// TODO: deal with version changes
    pub fn saveToStream(tlist: *Tlist, stream: anytype) !void {
        // save order:
        // 1. tlist.data.len
        // 2. tasks
        // id - name - progress - x - y
        // parents_ids_size - [ id1, id2 ]
        // children_ids_size - [ id1, id2 ]
        // previous_tasks_ids_size - [ id1, id2 ]
        // next_tasks_ids_size - [ id1, id2 ]

        if (null == tlist.data) return Error.DataIsNull;

        {
            const len: u32 = @truncate(tlist.data.?.len);
            _ = try stream.write(std.mem.asBytes(&len));
        }

        for (tlist.data.?) |task| {
            if (null == task) continue;
            _ = try stream.write(std.mem.asBytes(&task.?.id));
            _ = try stream.write(&task.?.name);
            _ = try stream.write(std.mem.asBytes(&task.?.progress));
            _ = try stream.write(std.mem.asBytes(&task.?.x));
            _ = try stream.write(std.mem.asBytes(&task.?.y));

            save_parents: {
                if (null == task.?.parents_ids) {
                    var len: u32 = 0;
                    _ = try stream.write(std.mem.asBytes(&len));
                    break :save_parents;
                }

                const len: u32 = @truncate(task.?.parents_ids.?.len);
                _ = try stream.write(std.mem.asBytes(&len));

                for (task.?.parents_ids.?) |parent_id| {
                    _ = try stream.write(std.mem.asBytes(&parent_id));
                }
            }

            save_children: {
                if (null == task.?.children_ids) {
                    var len: u32 = 0;
                    _ = try stream.write(std.mem.asBytes(&len));
                    break :save_children;
                }

                const len: u32 = @truncate(task.?.children_ids.?.len);
                _ = try stream.write(std.mem.asBytes(&len));

                for (task.?.children_ids.?) |child_id| {
                    _ = try stream.write(std.mem.asBytes(&child_id));
                }
            }

            save_next_tasks: {
                if (null == task.?.next_tasks_ids) {
                    var len: u32 = 0;
                    _ = try stream.write(std.mem.asBytes(&len));
                    break :save_next_tasks;
                }

                const len: u32 = @truncate(task.?.next_tasks_ids.?.len);
                _ = try stream.write(std.mem.asBytes(&len));

                for (task.?.next_tasks_ids.?) |next_task_id| {
                    _ = try stream.write(std.mem.asBytes(&next_task_id));
                }
            }

            save_previous_tasks: {
                if (null == task.?.previous_tasks_ids) {
                    var len: u32 = 0;
                    _ = try stream.write(std.mem.asBytes(&len));
                    break :save_previous_tasks;
                }

                const len: u32 = @truncate(task.?.previous_tasks_ids.?.len);
                _ = try stream.write(std.mem.asBytes(&len));

                for (task.?.previous_tasks_ids.?) |previous_task_id| {
                    _ = try stream.write(std.mem.asBytes(&previous_task_id));
                }
            }
        }
    }

    /// reads from a stream after it was saved using saveToStream()
    /// used like the following:
    /// file.seekTo(0); //or wherever you put it
    /// tlist.readFromStream(file);
    ///
    /// @stream should have the read() function
    /// read(buffer: []u8) !usize
    /// it should return the number of bytes read
    ///
    /// TODO: deal with version changes
    pub fn readFromStream(tlist: *Tlist, stream: anytype, reset_tlist: bool) !void {
        if (reset_tlist) try tlist.clear();

        {
            //loading length of tlist or resizing it
            var len: u32 = 0;
            if (0 == try stream.read(std.mem.asBytes(&len))) return Error.DataIsNull;

            if (reset_tlist) try tlist.clear();

            if (null == tlist.data) {
                tlist.data = try tlist.allocator.alloc(?*Task, len);

                var i: u32 = 0;
                while (i < tlist.data.?.len) : (i += 1) {
                    tlist.data.?[i] = null;
                }
            } else if (@as(u32, @truncate(tlist.data.?.len)) < len) {
                tlist.data = try tlist.allocator.realloc(tlist.data.?, len);
            }
        }

        loading_tasks: while (true) {
            var task: *Task = try Task.new(tlist.allocator);
            // breaks if reached EndOfFile
            if (0 == try stream.read(std.mem.asBytes(&task.id))) {
                tlist.allocator.destroy(task);
                break :loading_tasks;
            }

            tlist.data.?[task.id] = task;
            if (0 == try stream.read(&task.name)) break :loading_tasks;
            if (0 == try stream.read(std.mem.asBytes(&task.progress))) break :loading_tasks;
            if (0 == try stream.read(std.mem.asBytes(&task.x))) break :loading_tasks;
            if (0 == try stream.read(std.mem.asBytes(&task.y))) break :loading_tasks;

            load_parents: {
                var len: u32 = 0;
                if (0 == try stream.read(std.mem.asBytes(&len))) break :loading_tasks;
                if (0 == len) break :load_parents;
                var i: u32 = 0;
                while (i < len) : (i += 1) {
                    var parent_id: u32 = 0;
                    _ = try stream.read(std.mem.asBytes(&parent_id));
                    try task.addParentId(parent_id, tlist.allocator);
                }
            }

            load_children: {
                var len: u32 = 0;
                if (0 == try stream.read(std.mem.asBytes(&len))) break :loading_tasks;
                if (0 == len) break :load_children;
                var i: u32 = 0;

                while (i < len) : (i += 1) {
                    var child_id: u32 = 0;
                    _ = try stream.read(std.mem.asBytes(&child_id));
                    try task.addChildId(child_id, tlist.allocator);
                }
            }

            load_next_tasks: {
                var len: u32 = 0;
                if (0 == try stream.read(std.mem.asBytes(&len))) break :loading_tasks;
                if (0 == len) break :load_next_tasks;
                var i: u32 = 0;
                while (i < len) : (i += 1) {
                    var next_task_id: u32 = 0;
                    _ = try stream.read(std.mem.asBytes(&next_task_id));
                    try task.addNextId(next_task_id, tlist.allocator);
                }
            }

            load_previous_tasks: {
                var len: u32 = 0;
                if (0 == try stream.read(std.mem.asBytes(&len))) break :loading_tasks;
                if (0 == len) break :load_previous_tasks;
                var i: u32 = 0;
                while (i < len) : (i += 1) {
                    var previous_task_id: u32 = 0;
                    _ = try stream.read(std.mem.asBytes(&previous_task_id));
                    try task.addPreviousId(previous_task_id, tlist.allocator);
                }
            }
        }
    }
};

test "get/remove task" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;
    var bismi_allah_tlist = try Tlist.new(allocator);

    var i: u32 = 0;
    while (i < 50) : (i += 1) {
        try bismi_allah_tlist.addTask(try Task.new(allocator));
    }

    i = 0;
    while (i < 50) : (i += 1) {
        try expect(i == bismi_allah_tlist.data.?[i].?.id);
    }

    try bismi_allah_tlist.removeTaskById(22, false);
    try expect(null == bismi_allah_tlist.data.?[22]);

    try bismi_allah_tlist.removeTaskById(12, false);
    try expect(null == bismi_allah_tlist.data.?[12]);

    try bismi_allah_tlist.removeTaskById(7, false);
    try expect(null == bismi_allah_tlist.data.?[7]);

    try bismi_allah_tlist.removeTaskById(40, false);
    try expect(null == bismi_allah_tlist.data.?[40]);

    for (bismi_allah_tlist.data.?) |task| {
        if (null == task) continue;
    }

    try bismi_allah_tlist.clear();
    try expect(null == bismi_allah_tlist.data);
    allocator.destroy(bismi_allah_tlist);
}

// due to the parents' function forwarding the call to the Children's functions
// only the Children's functions will be tested by the will of Allah
test "add/remove Child" {
    const allocator = std.testing.allocator;
    const tlist: *Tlist = try Tlist.new(allocator);

    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));

    try tlist.taskAddChildId(0, 1, false);
    try tlist.taskAddChildId(1, 2, false);
    try tlist.taskAddChildId(2, 3, false);
    try tlist.taskAddChildId(1, 3, false);

    tlist.taskAddChildId(1, 0, false) catch |e| if (Tlist.Error.TaskCanNotBeGrandChildOfItSelf != e) return e;

    try tlist.clear();
    allocator.destroy(tlist);
}

test "hasGrandChild" {
    const allocator = std.testing.allocator;
    const tlist: *Tlist = try Tlist.new(allocator);
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));

    try tlist.taskAddChildId(0, 1, false);
    try tlist.taskAddChildId(1, 2, false);
    try tlist.taskAddChildId(2, 3, false);
    try std.testing.expect(try tlist.taskHasGrandChild(0, 1));
    try std.testing.expect(try tlist.taskHasGrandChild(0, 2));
    try std.testing.expect(try tlist.taskHasGrandChild(0, 3));
    try std.testing.expect(try tlist.taskHasGrandChild(0, 4) != true);
    try std.testing.expect(try tlist.taskHasGrandChild(0, 0) != true);

    try tlist.clear();
    allocator.destroy(tlist);
}

test "previousTasks" {
    //const expect = std.testing.expect;
    const allocator = std.testing.allocator;
    const tlist: *Tlist = try Tlist.new(allocator);
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));

    try tlist.taskAddPreviousId(1, 0);
    tlist.taskSetProgress(1, 100, false) catch |e| if (Tlist.Error.TaskHasIncompletePreviousTasks != e) return e;
    try tlist.taskSetProgress(0, 100, true);
    try tlist.taskSetProgress(1, 100, true);

    try tlist.clear();
    allocator.destroy(tlist);
}

test "add/remove next Tasks" {
    const allocator = std.testing.allocator;
    const tlist: *Tlist = try Tlist.new(allocator);
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));

    try tlist.taskAddNextId(0, 1);
    try tlist.taskAddNextId(1, 2);
    try tlist.taskAddNextId(2, 3);
    tlist.taskAddNextId(3, 0) catch |e| if (Tlist.Error.TaskCanNotBeNextOfItSelf != e) return e;

    try tlist.clear();
    allocator.destroy(tlist);
}

test "hasLaterId" {
    const allocator = std.testing.allocator;
    const tlist: *Tlist = try Tlist.new(allocator);
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));

    try tlist.taskAddNextId(0, 1);
    try tlist.taskAddNextId(1, 2);
    try tlist.taskAddNextId(2, 3);
    try std.testing.expect(try tlist.taskHasLaterId(0, 1));
    try std.testing.expect(try tlist.taskHasLaterId(0, 2));
    try std.testing.expect(try tlist.taskHasLaterId(0, 3));
    try std.testing.expect(try tlist.taskHasLaterId(1, 2));
    try std.testing.expect(try tlist.taskHasLaterId(1, 3));
    try std.testing.expect(try tlist.taskHasLaterId(2, 3));
    try std.testing.expect(try tlist.taskHasLaterId(0, 0) != true);

    try tlist.clear();
    allocator.destroy(tlist);
}

test "taskSetProgress" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;
    const tlist: *Tlist = try Tlist.new(allocator);
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));
    try tlist.addTask(try Task.new(allocator));

    try tlist.taskAddChildId(0, 1, false);
    try tlist.taskAddChildId(0, 2, false);
    try tlist.taskAddChildId(2, 3, false);
    try tlist.taskAddChildId(2, 4, false);

    try tlist.taskSetProgress(3, 100, true);
    try expect(100 == tlist.data.?[3].?.progress);

    try tlist.taskSetProgress(4, 150, true);
    try expect(100 == tlist.data.?[4].?.progress);

    try expect(100 == tlist.data.?[2].?.progress);
    try expect(50 == tlist.data.?[0].?.progress);
    try expect(0 == tlist.data.?[1].?.progress);

    try tlist.removeTaskById(4, true);
    try expect(100 == tlist.data.?[2].?.progress);
    try expect(100 == tlist.data.?[3].?.progress);
    try expect(50 == tlist.data.?[0].?.progress);
    try expect(50 == tlist.data.?[0].?.progress);

    try tlist.removeTaskById(3, true);
    try expect(100 == tlist.data.?[2].?.progress);
    try expect(50 == tlist.data.?[0].?.progress);
    try expect(50 == tlist.data.?[0].?.progress);

    try tlist.clear();
    allocator.destroy(tlist);
}

test "save/load" {
    //in the name of Allah
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;
    const tlist: *Tlist = try Tlist.new(allocator);
    try tlist.addTask(try Task.new(allocator)); //0
    try tlist.addTask(try Task.new(allocator)); //1
    try tlist.addTask(try Task.new(allocator)); //2
    try tlist.addTask(try Task.new(allocator)); //3
    try tlist.addTask(try Task.new(allocator)); //4
    try tlist.addTask(try Task.new(allocator)); //5

    try tlist.removeTaskById(2, false);

    try tlist.taskAddChildId(0, 1, false);
    try tlist.taskAddChildId(1, 3, false);
    try tlist.taskAddChildId(3, 4, false);
    try tlist.taskAddChildId(3, 5, false);

    try tlist.taskSetProgress(4, 50, true);
    try tlist.taskSetProgress(5, 20, true);

    try tlist.taskAddNextId(4, 5);

    const file = try std.fs.cwd().createFile("bismi_allah.bin", .{ .read = true });
    defer {
        file.close();
        std.fs.cwd().deleteFile("bismi_allah.bin") catch {};
    }

    try tlist.saveToStream(file);
    try tlist.clear();

    try file.seekTo(0);
    try tlist.readFromStream(file, true);

    try expect(null != tlist.data);
    try expect(null != tlist.data.?[0]);
    try expect(null != tlist.data.?[1]);
    try expect(null == tlist.data.?[2]);
    try expect(null != tlist.data.?[3]);
    try expect(null != tlist.data.?[4]);
    try expect(null != tlist.data.?[5]);

    try expect(tlist.data.?[0].?.hasChildId(1));
    try expect(tlist.data.?[1].?.hasChildId(3));
    try expect(tlist.data.?[3].?.hasChildId(4));

    try expect(tlist.data.?[1].?.hasParentId(0));
    try expect(tlist.data.?[3].?.hasParentId(1));
    try expect(tlist.data.?[4].?.hasParentId(3));

    try expect(50 == tlist.data.?[4].?.progress);
    try expect(35 == tlist.data.?[3].?.progress);
    try expect(35 == tlist.data.?[1].?.progress);
    try expect(35 == tlist.data.?[0].?.progress);

    try expect(tlist.data.?[4].?.hasNextId(5));
    try expect(tlist.data.?[5].?.hasPreviousId(4));

    try tlist.clear();
    allocator.destroy(tlist);
}
