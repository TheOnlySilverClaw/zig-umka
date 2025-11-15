pub const types = @import("types.zig");

pub const Instance = @import("Instance.zig");
pub const Function = @import("Function.zig");

pub const DynArray = types.DynArray;
pub const ExternFunc = types.ExternFunc;
pub const HookFunc = types.HookFunc;
pub const WarningCallback = types.WarningCallback;
pub const Any = types.Any;
pub const Closure = types.Closure;
pub const Error = types.Error;
pub const ExternalCallParamLayout = types.ExternalCallParamLayout;
pub const FuncContext = types.FuncContext;
pub const Map = types.Map;
pub const Memory = types.Memory;
pub const Metadata = types.Metadata;
pub const StackSlot = types.StackSlot;
pub const String = types.String;
pub const Type = types.Type;

const functions = @import("functions.zig");

pub const getVersion = functions.umkaGetVersion;