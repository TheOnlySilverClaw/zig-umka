const functions = @import("functions.zig");
const Self = @This();

// internal Umka instance handle
instance: *anyopaque,
ptr: *anyopaque,

pub fn incRef(self: Self) void {
    functions.umkaIncRef(self.instance, self.ptr);
}

pub fn decRef(self: Self) void {
    functions.umkaDecRef(self.instance, self.ptr);
}
