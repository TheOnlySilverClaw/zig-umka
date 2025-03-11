const types = @import("types.zig");
const functions = @import("functions.zig");
const stack = @import("stack.zig");

const FuncContext = types.FuncContext;
const StackSlot = types.StackSlot;

const Instance = @import("Instance.zig");

const assert = @import("std").debug.assert;

const Self = @This();

// internal Umka instance handle
instance: *anyopaque,
module: ?[*:0]const u8,
name: [*:0]const u8,
context: FuncContext,

pub fn new(module: ?[*:0]const u8, name: [*:0]const u8) Self {
    return .{
        .instance = undefined,
        .module = module,
        .name = name,
        .context = undefined
    };
}

pub fn get(self: *Self, instance: Instance) error{GetFunction}!void {
    self.instance = instance.handle;
    const success = functions.umkaGetFunc(instance.handle, self.module, self.name, &self.context);
    if(success != 1) return error.GetFunction;
}

pub fn getResult(self: *Self) *StackSlot {
    return stack.getResult(self.context.params, self.context.result);
}

pub fn setResultTarget(self: *Self, target: *anyopaque) void {
    self.getResult().ptr = @ptrCast(target);
}

pub fn call(self: *Self) error{CallFunction}!void {
    const code = functions.umkaCall(self.instance, &self.context);
    if(code != 0) return error.CallFunction;
}

pub fn getParameter(self: *Self, index: i32) *StackSlot {
    return stack.getParam(self.context.params, index).?;
}

pub fn setParameters(self: *Self, values: []const StackSlot) void {

    const params = self.context.params;
    const layout = stack.getParamLayout(params);
    assert(values.len <= layout.num_params - layout.num_result_params - 1);
    
    const first_slot_index = layout.firstSlotIndex();
    for(0..values.len) |index| {
        const slot_index: usize = @intCast(first_slot_index[index + 1]);
        params[slot_index] = values[index];
    }
}