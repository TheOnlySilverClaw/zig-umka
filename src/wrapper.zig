pub usingnamespace @import("types.zig");

pub const Instance = @import("Instance.zig");
pub const Function = @import("Function.zig");

const functions = @import("functions.zig");

pub const getVersion = functions.umkaGetVersion;