const functions = @import("functions.zig");

// internal Umka instance handle
const Instance = anyopaque;

pub const StackSlot = extern union {
    int: i64,
    uint: u64,
    ptr: *anyopaque,
    real: f64,
    real32: f32
};

pub const FuncContext = extern struct {
    entry_offset: i64,
    params: [*]StackSlot,
    result: *StackSlot
};

pub const ExternFunc = fn(params: [*]StackSlot, result: *StackSlot) callconv(.C) void;

pub const HookEvent = enum(c_int) {
    hook_call,
    hook_return
};

pub const HookFunc = fn(file_name: [*:0]const u8, func_name: [*:0]const u8, line: c_int) callconv(.C) void;

pub const Map = struct {
    instance: *anyopaque,
    ptr: *anyopaque,

    pub const Item = anyopaque;

    pub fn getItem(self: Map, key: *StackSlot) ?*Item {
        return functions.umkaGetMapItem(self.instance, self.ptr, key);
    }
};

pub const String = struct {
    ptr: [*]u8,

    pub fn len(self: String) c_int {
        return functions.umkaGetStrLen(self.ptr);
    }
};

pub const Type = anyopaque;

pub const Any = extern struct {
    data: *anyopaque,
    umka_type: *Type
};

pub const DynArray = struct {
    ptr: [*]const anyopaque,

    pub fn len(self: DynArray) c_int {
        return functions.umkaGetDynArrayLen(self.ptr);
    }
};

pub const Memory = struct {
    instance: *Instance,
    ptr: *anyopaque,

    pub fn incRef(self: Memory) void {
        functions.umkaIncRef(self.instance, self.ptr);
    }

    pub fn decRef(self: Memory) void {
        functions.umkaDecRef(self.instance, self.ptr);
    }
};


pub const Closure = extern struct {
    entry_offset: i64,
    upvalue: Any
};

pub const Error = extern struct {
    file_name: [*:0]const u8,
    fn_name: [*:0]const u8,
    line: c_int,
    pos: c_int,
    code: c_int,
    msg: [*:0]const u8
};

pub const WarningCallback = fn(warning: *Error) callconv(.C) void;

pub const ExternalCallParamLayout = extern struct {
    num_params: i64,
    num_result_params: i64,
    num_param_slots: i64,
    
    pub fn firstSlotIndex(self: *const @This()) [*]const i64 {
        const byte_ptr: [*]const u8 = @ptrCast(self);
        const byte_size = @sizeOf(@This());
        const last_byte = byte_ptr + byte_size;
        const flexible_start: [*]const i64 = @ptrCast(@alignCast(last_byte));
        return flexible_start;
    }
};
