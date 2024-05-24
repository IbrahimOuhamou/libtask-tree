//بسم الله الرحمن الرحيم
//la ilaha illa Allah mohammed rassoul Allah

const std = @import("std");

pub const Task = struct {
    /// @{id}: used to identify and access the @{task} from lists
    id: u32 = undefined,
    /// @{name}: the name of this @{task}
    name: [34:0]u8 = undefined,
    /// @{progress}: the progress of this task
    /// can't update directly if it has children
    /// can't update at all if it has incompleted previous tasks
    progress: u8 = 0,
    /// @{x}: the task's x position
    x: f32 = 0,
    /// @{y}: the task's y position
    y: f32 = 0,
    /// @{parents_ids}: the progress of the parents is updated when this @{task.progress} is updated
    parents_ids: ?[]u32 = null,
    /// @{children_ids}: this @{task.progress} is updated only when it's childrens' progress is updated
    /// you can't update the task's progress directly
    children_ids: ?[]u32 = null,
    /// @{next_tasks_ids}: only after this task is completed (porgrss == 100) you can update these tasks' @{progress}
    next_tasks_ids: ?[]u32 = null,
    /// @{previous_tasks_ids}: only after all of these tasks are completed you can update this task's @{progress}
    previous_tasks_ids: ?[]u32 = null,

    /// returns a new initialized Task
    /// Task { .id = undefined, }
    /// to make sure null fields are null
    pub fn new(allocator: std.mem.Allocator) !*Task {
        const task: *Task = try allocator.create(Task);
        task.* = Task{};
        return task;
    }

    /// returns the @{task}'s name
    pub fn getName(task: *Task) []u8 {
        return task.name[0..];
    }

    /// copies the []u8 from @{name} to @{task.name}
    pub fn setName(task: *Task, name: []u8) void {
        var i: usize = 0;
        while (i < name.len and i < task.name.len) : (i += 1) {
            task.name[i] = name[i];
        }
    }

    /// returns the @{Task.id}
    pub fn getId(task: *Task) @TypeOf(Task.id) {
        return task.id;
    }

    /// sets the @{Task.id} to @{id}
    pub fn setId(task: *Task, id: @TypeOf(Task.id)) void {
        task.id = id;
    }

    /// returns the progress of @{task}
    pub fn getProgress(task: *Task) @TypeOf(task.progress) {
        return task.progress;
    }

    /// sets @{task.progress} to @{progress}
    pub fn setProgress(task: *Task, progress: @TypeOf(task.progress)) void {
        task.progress = if (progress <= 100) progress else 100;
    }

    /// returns true if @{task.parents_ids} has @{parent_id}
    pub fn hasParentId(task: *Task, parent_id: @TypeOf(task.id)) bool {
        if (null == task.parents_ids) return false;
        for (task.parents_ids.?) |id| {
            if (id == parent_id) return true;
        }
        return false;
    }

    /// adds @{parent_id} to @{task.parents_ids} if it does not exist already
    /// the error can be from the allocation
    pub fn addParentId(task: *Task, parent_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (task.hasParentId(parent_id)) return;

        if (null == task.parents_ids) {
            task.parents_ids = try allocator.alloc(@TypeOf(task.id), 1);
        } else {
            task.parents_ids = try allocator.realloc(task.parents_ids.?, task.parents_ids.?.len + 1);
        }

        task.parents_ids.?[task.parents_ids.?.len - 1] = parent_id;
    }

    /// removes @{parent_id} from @{task.parensts_ids} and replaces last id in @{parent_id}'s place
    /// after removing the last id it sets the array to null
    /// given the call 'task.removeParenetId(6);'
    /// [2, 3, 6, 1, 15, 325]
    /// ~~~~~~~^~~~~~~~~~~~~
    /// [2, 3, 325, 1, 15]
    /// ~~~~~~~^~~~~~~~~~~~~
    pub fn removeParentId(task: *Task, parent_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (null == task.parents_ids) return;

        var i: usize = 0;
        while (i < task.parents_ids.?.len) : (i += 1) {
            if (task.parents_ids.?[i] == parent_id) {
                task.parents_ids.?[i] = task.parents_ids.?[task.parents_ids.?.len - 1];
                task.parents_ids = try allocator.realloc(task.parents_ids.?, task.parents_ids.?.len - 1);
                if (task.parents_ids.?.len == 0) task.parents_ids = null;
                return;
            }
        }
    }

    /// returns true if @{task.children_ids} has @{child_id}
    pub fn hasChildId(task: *Task, child_id: @TypeOf(task.id)) bool {
        if (null == task.children_ids) return false;
        for (task.children_ids.?) |id| {
            if (id == child_id) return true;
        }
        return false;
    }

    /// adds @{child_id} to @{task.children_ids} if it does not exist already
    /// the error can be from the allocation
    pub fn addChildId(task: *Task, child_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (task.hasChildId(child_id)) return;

        if (null == task.children_ids) {
            task.children_ids = try allocator.alloc(@TypeOf(task.id), 1);
        } else {
            task.children_ids = try allocator.realloc(task.children_ids.?, task.children_ids.?.len + 1);
        }

        task.children_ids.?[task.children_ids.?.len - 1] = child_id;
    }

    /// removes @{child_id} from @{task.parensts_ids} and replaces last id in @{child_id}'s place
    /// after removing the last id it sets the array to null
    /// given the call 'task.removeParenetId(6);'
    /// [2, 3, 6, 1, 15, 325]
    /// ~~~~~~~^~~~~~~~~~~~~
    /// [2, 3, 325, 1, 15]
    /// ~~~~~~~^~~~~~~~~~~~~
    pub fn removeChildId(task: *Task, child_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (null == task.children_ids) return;

        var i: usize = 0;
        while (i < task.children_ids.?.len) : (i += 1) {
            if (task.children_ids.?[i] == child_id) {
                task.children_ids.?[i] = task.children_ids.?[task.children_ids.?.len - 1];
                task.children_ids = try allocator.realloc(task.children_ids.?, task.children_ids.?.len - 1);
                if (task.children_ids.?.len == 0) task.children_ids = null;
                return;
            }
        }
    }

    /// returns true if @{task.previous_tasks_ids} has @{previous_id}
    pub fn hasPreviousId(task: *Task, previous_id: @TypeOf(task.id)) bool {
        if (null == task.previous_tasks_ids) return false;
        for (task.previous_tasks_ids.?) |id| {
            if (id == previous_id) return true;
        }
        return false;
    }

    /// adds @{previous_id} to @{task.previous_tasks_ids} if it does not exist already
    /// the error can be from the allocation
    pub fn addPreviousId(task: *Task, previous_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (task.hasPreviousId(previous_id)) return;

        if (null == task.previous_tasks_ids) {
            task.previous_tasks_ids = try allocator.alloc(@TypeOf(task.id), 1);
        } else {
            task.previous_tasks_ids = try allocator.realloc(task.previous_tasks_ids.?, task.previous_tasks_ids.?.len + 1);
        }

        task.previous_tasks_ids.?[task.previous_tasks_ids.?.len - 1] = previous_id;
    }

    /// removes @{previous_id} from @{task.parensts_ids} and replaces last id in @{previous_id}'s place
    /// after removing the last id it sets the array to null
    /// given the call 'task.removeParenetId(6);'
    /// [2, 3, 6, 1, 15, 325]
    /// ~~~~~~~^~~~~~~~~~~~~
    /// [2, 3, 325, 1, 15]
    /// ~~~~~~~^~~~~~~~~~~~~
    pub fn removePreviousId(task: *Task, previous_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (null == task.previous_tasks_ids) return;

        var i: usize = 0;
        while (i < task.previous_tasks_ids.?.len) : (i += 1) {
            if (task.previous_tasks_ids.?[i] == previous_id) {
                task.previous_tasks_ids.?[i] = task.previous_tasks_ids.?[task.previous_tasks_ids.?.len - 1];
                task.previous_tasks_ids = try allocator.realloc(task.previous_tasks_ids.?, task.previous_tasks_ids.?.len - 1);
                if (task.previous_tasks_ids.?.len == 0) task.previous_tasks_ids = null;
                return;
            }
        }
    }
    /// returns true if @{task.next_tasks_ids} has @{next_id}
    pub fn hasNextId(task: *Task, next_id: @TypeOf(task.id)) bool {
        if (null == task.next_tasks_ids) return false;
        for (task.next_tasks_ids.?) |id| {
            if (id == next_id) return true;
        }
        return false;
    }

    /// adds @{next_id} to @{task.next_tasks_ids} if it does not exist already
    /// the error can be from the allocation
    pub fn addNextId(task: *Task, next_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (task.hasNextId(next_id)) return;

        if (null == task.next_tasks_ids) {
            task.next_tasks_ids = try allocator.alloc(@TypeOf(task.id), 1);
        } else {
            task.next_tasks_ids = try allocator.realloc(task.next_tasks_ids.?, task.next_tasks_ids.?.len + 1);
        }

        task.next_tasks_ids.?[task.next_tasks_ids.?.len - 1] = next_id;
    }

    /// removes @{next_id} from @{task.parensts_ids} and replaces last id in @{next_id}'s place
    /// after removing the last id it sets the array to null
    /// given the call 'task.removeParenetId(6);'
    /// [2, 3, 6, 1, 15, 325]
    /// ~~~~~~~^~~~~~~~~~~~~
    /// [2, 3, 325, 1, 15]
    /// ~~~~~~~^~~~~~~~~~~~~
    pub fn removeNextId(task: *Task, next_id: @TypeOf(task.id), allocator: std.mem.Allocator) !void {
        if (null == task.next_tasks_ids) return;

        var i: usize = 0;
        while (i < task.next_tasks_ids.?.len) : (i += 1) {
            if (task.next_tasks_ids.?[i] == next_id) {
                task.next_tasks_ids.?[i] = task.next_tasks_ids.?[task.next_tasks_ids.?.len - 1];
                task.next_tasks_ids = try allocator.realloc(task.next_tasks_ids.?, task.next_tasks_ids.?.len - 1);
                if (task.next_tasks_ids.?.len == 0) task.next_tasks_ids = null;
                return;
            }
        }
    }
};

test "Task.setName" {
    const expect = std.testing.expect;
    var bismi_allah = Task{};
    var bismi_allah_name = [_]u8{ 'i', 'n', ' ', 't', 'h', 'e', ' ', 'n', 'a', 'm', 'e', ' ', 'o', 'f', ' ', 'A', 'l', 'l', 'a', 'h' };
    bismi_allah_name[0] = 'i';
    bismi_allah.setName(bismi_allah_name[0..]);

    var i: usize = 0;
    while (i < bismi_allah_name.len and i < bismi_allah.name.len) : (i += 1) {
        try expect(bismi_allah_name[i] == bismi_allah.name[i]);
    }
}

test "Task.getName" {
    const expect = std.testing.expect;
    var bismi_allah = Task{};
    var bismi_allah_name = [_]u8{ 'i', 'n', ' ', 't', 'h', 'e', ' ', 'n', 'a', 'm', 'e', ' ', 'o', 'f', ' ', 'A', 'l', 'l', 'a', 'h' };
    bismi_allah_name[0] = 'i';
    bismi_allah.setName(bismi_allah_name[0..]);
    const bismi_allah_name2 = bismi_allah.getName();
    var i: usize = 0;
    while (i < bismi_allah_name2.len and i < bismi_allah.name.len) : (i += 1) {
        try expect(bismi_allah_name2[i] == bismi_allah.name[i]);
    }
}

test "Task.progress" {
    const expect = std.testing.expect;

    var bismi_allah = Task{};
    bismi_allah.setProgress(12);
    try expect(bismi_allah.getProgress() == 12);
}

test "Task.parents_ids" {
    const expect = std.testing.expect;

    var bismi_allah = Task{};

    // alhamdo li Allah
    // testing for:
    // 1. basic add/remove
    // 2. search
    try bismi_allah.addParentId(12, std.testing.allocator);
    try expect(bismi_allah.hasParentId(12));
    try bismi_allah.removeParentId(12, std.testing.allocator);

    // making sure it sets the @{parents_ids} to null when it gets to 0
    try expect(bismi_allah.parents_ids == null);

    // testling multiple alocations
    for (0..25) |i| {
        try bismi_allah.addParentId(@intCast(i), std.testing.allocator);
    }

    // making sure all ids are added to the last element
    for (bismi_allah.parents_ids.?, 0..) |id, i| {
        try expect(id == i);
    }

    // testling the search
    for (bismi_allah.parents_ids.?) |id| {
        try expect(bismi_allah.hasParentId(id));
    }

    // testing the removal of ids
    while (bismi_allah.parents_ids != null) {
        try bismi_allah.removeParentId(bismi_allah.parents_ids.?[0], std.testing.allocator);
    }
    // retesting that it sets it to null after clearing the data
    try expect(bismi_allah.parents_ids == null);
}

test "Task.children_ids" {
    const expect = std.testing.expect;

    var bismi_allah = Task{};

    // alhamdo li Allah
    // testing for:
    // 1. basic add/remove
    // 2. search
    try bismi_allah.addChildId(12, std.testing.allocator);
    try expect(bismi_allah.hasChildId(12));
    try bismi_allah.removeChildId(12, std.testing.allocator);

    // making sure it sets the @{children_ids} to null when it gets to 0
    try expect(bismi_allah.children_ids == null);

    // testling multiple alocations
    for (0..25) |i| {
        try bismi_allah.addChildId(@intCast(i), std.testing.allocator);
    }

    // making sure all ids are added to the last element
    for (bismi_allah.children_ids.?, 0..) |id, i| {
        try expect(id == i);
    }

    // testling the search
    for (bismi_allah.children_ids.?) |id| {
        try expect(bismi_allah.hasChildId(id));
    }

    // testing the removal of ids
    while (bismi_allah.children_ids != null) {
        try bismi_allah.removeChildId(bismi_allah.children_ids.?[0], std.testing.allocator);
    }
    // retesting that it sets it to null after clearing the data
    try expect(bismi_allah.children_ids == null);
}

test "Task.previous_tasks_ids" {
    const expect = std.testing.expect;

    var bismi_allah = Task{};

    // alhamdo li Allah
    // testing for:
    // 1. basic add/remove
    // 2. search
    try bismi_allah.addPreviousId(12, std.testing.allocator);
    try expect(bismi_allah.hasPreviousId(12));
    try bismi_allah.removePreviousId(12, std.testing.allocator);

    // making sure it sets the @{previous_tasks_ids} to null when it gets to 0
    try expect(bismi_allah.previous_tasks_ids == null);

    // testling multiple alocations
    for (0..25) |i| {
        try bismi_allah.addPreviousId(@intCast(i), std.testing.allocator);
    }

    // making sure all ids are added to the last element
    for (bismi_allah.previous_tasks_ids.?, 0..) |id, i| {
        try expect(id == i);
    }

    // testling the search
    for (bismi_allah.previous_tasks_ids.?) |id| {
        try expect(bismi_allah.hasPreviousId(id));
    }

    // testing the removal of ids
    while (bismi_allah.previous_tasks_ids != null) {
        try bismi_allah.removePreviousId(bismi_allah.previous_tasks_ids.?[0], std.testing.allocator);
    }
    // retesting that it sets it to null after clearing the data
    try expect(bismi_allah.previous_tasks_ids == null);
}

test "Task.next_tasks_ids" {
    const expect = std.testing.expect;

    var bismi_allah = Task{};

    // alhamdo li Allah
    // testing for:
    // 1. basic add/remove
    // 2. search
    try bismi_allah.addNextId(12, std.testing.allocator);
    try expect(bismi_allah.hasNextId(12));
    try bismi_allah.removeNextId(12, std.testing.allocator);

    // making sure it sets the @{next_tasks_ids} to null when it gets to 0
    try expect(bismi_allah.next_tasks_ids == null);

    // testling multiple alocations
    for (0..25) |i| {
        try bismi_allah.addNextId(@intCast(i), std.testing.allocator);
    }

    // making sure all ids are added to the last element
    for (bismi_allah.next_tasks_ids.?, 0..) |id, i| {
        try expect(id == i);
    }

    // testling the search
    for (bismi_allah.next_tasks_ids.?) |id| {
        try expect(bismi_allah.hasNextId(id));
    }

    // testing the removal of ids
    while (bismi_allah.next_tasks_ids != null) {
        try bismi_allah.removeNextId(bismi_allah.next_tasks_ids.?[0], std.testing.allocator);
    }
    // retesting that it sets it to null after clearing the data
    try expect(bismi_allah.next_tasks_ids == null);
}
