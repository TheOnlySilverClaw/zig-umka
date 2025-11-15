const types = @import("types.zig");
const functions = @import("functions.zig");

const FuncContext = types.FuncContext;
const StackSlot = types.StackSlot;

const Instance = @import("Instance.zig");

const assert = @import("std").debug.assert;

const Self = @This();

// internal Umka instance handle
instance: *anyopaque,
context: FuncContext,

pub fn getResult(self: Self) *StackSlot {
    return functions.umkaGetResult(self.context.params, self.context.result);
}

pub fn setResultTarget(self: Self, target: *anyopaque) void {
    self.getResult().ptr = @ptrCast(target);
}

pub fn call(self: *Self) error{CallFunction}!void {
    const code = functions.umkaCall(self.instance, &self.context);
    if(code != 0) return error.CallFunction;
}

pub fn getParameter(self: *Self, index: i32) *StackSlot {
    return functions.umkaGetParam(self.context.params, index);
}
