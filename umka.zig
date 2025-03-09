const std = @import("std");
const FlexibleArrayType = std.zig.c_translation.FlexibleArrayType;

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

pub const ExternFunc = fn(params: *StackSlot, result: *StackSlot) callconv(.C) void;

pub const HookEvent = enum(c_int) {
    hook_call,
    hook_return
};

pub const HookFunc = fn(file_name: [*:0]const u8, func_name: [*:0]const u8, line: c_int) callconv(.C) void;

pub const Map = extern struct {
    internal1: *anyopaque,
    internal2: *anyopaque
};

pub const Any = extern struct {
    data: *anyopaque,
    type: *anyopaque
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
    num_params: i64 align(8) = @import("std").mem.zeroes(i64),
    num_result_params: i64 = @import("std").mem.zeroes(i64),
    num_param_slots: i64 = @import("std").mem.zeroes(i64),
    
    fn firstSlotIndex(self: *const @This()) [*]const i64 {
        const byte_ptr: [*]const u8 = @ptrCast(self);
        const byte_size = @sizeOf(@This());
        const last_byte = byte_ptr + byte_size;
        const flexible_start: [*]const i64 = @ptrCast(@alignCast(last_byte));
        return flexible_start;
    }
};

pub const Instance = opaque {

    pub fn init(
        self: *Instance,
        file_name: ?[*:0]const u8,
        source_string: ?[*:0]const u8,
        stack_size: c_int,
        args: [][*:0]const u8,
        file_system_enabled: bool,
        impl_libs_enabled: bool,
        warning_callback: ?*WarningCallback) error{Init}!void {
        
        const success = umkaInit(
            self,
            file_name,
            source_string,
            stack_size,
            null,
            @intCast(args.len),
            args.ptr,
            if(file_system_enabled) 1 else 0,
            if(impl_libs_enabled) 1 else 0,
            warning_callback);
        if(success != 1) return error.Init;
    }

    pub fn compile(self: *Instance) error{Compile}!void {
        const success = umkaCompile(self);
        if(success != 1) return error.Compile;
    }

    pub fn run(self: *Instance) error{Run}!void {
        const code = umkaRun(self);
        if(code != 0) return error.Run;
    }

    pub fn call(self: *Instance, context: *FuncContext) error{Call}!void {
        const code = umkaCall(self, context);
        if(code != 0) return error.Call;
    }

    pub fn free(self: *Instance) void {
        umkaFree(self);
    }

    pub fn alive(self: *Instance) bool {
        return umkaAlive(self) == 1;
    }

    pub const assembly = umkaAsm;

    pub fn addModule(self: *Instance, file_name: [*:0]const u8, source_string: [*:0]const u8) error{AddModule}!void {
        const success = umkaAddModule(self, file_name, source_string);
        if(success != 1) return error.AddModule;
    }

    pub fn addFunc(self: *Instance, name: [*:0]const u8, func: ExternFunc) error{AddFunc}!void {
        const success = umkaAddFunc(self, name, func);
        if(success != 1) return error.AddFunc;
    }

    pub fn getFunc(self: *Instance, module_name: ?[*:0]const u8, fn_name: [*:0]const u8, context: *FuncContext) error{GetFunc}!void {
        const success = umkaGetFunc(self, module_name, fn_name, context);
        if(success != 1) return error.GetFunc;
    }

    pub const getError = umkaGetError;
};

pub fn alloc() *Instance {
    return umkaAlloc();
}

pub const getVersion = umkaGetVersion;

pub fn getParam(params: [*]StackSlot, index: c_int) error{InvalidParamIndex}!*StackSlot {

    const layout_slot = (params - 4)[0];
    const layout: *const ExternalCallParamLayout = @ptrCast(@alignCast(layout_slot.ptr));
    if(index < 0 or index >= layout.num_params - layout.num_result_params - 1) {
        return error.InvalidParamIndex;
    }

    const slot_offset: usize = @intCast(index + 1);
    const first_slot_index = layout.firstSlotIndex();
    const slot_index: usize = @intCast((first_slot_index[slot_offset]));
    return &params[slot_index];
}

pub fn getResult(params: [*]StackSlot, result: *StackSlot) *StackSlot {

    const layout_slot = (params - 4)[0];
    const layout: *const ExternalCallParamLayout = @ptrCast(@alignCast(layout_slot.ptr));
    if(layout.num_result_params == 1) {
        const slot_offset: usize = @intCast(layout.num_params - 1);
        const first_slot_index = layout.firstSlotIndex();
        const slot_index: usize = @intCast((first_slot_index[slot_offset]));
        result.ptr = params[slot_index].ptr;
    }

    return result;
}

extern fn umkaAlloc() *Instance;

extern fn umkaInit(
    umka: *Instance,
    file_name: ?[*:0]const u8,
    source_string: ?[*:0]const u8,
    stack_size: c_int,
    reserved: ?*anyopaque,
    argc: c_int,
    argv: [*][*:0]const u8,
    file_system_enabled: c_char,
    impl_libs_enabled: c_char,
    warning_callback: ?*WarningCallback
) c_char;


extern fn umkaCompile(umka: *Instance) c_char;

extern fn umkaRun(umka: *Instance) c_int;

extern fn umkaCall(umka: *Instance, context: *FuncContext) c_int; 

extern fn umkaFree(umka: *Instance) void; 

extern fn umkaGetError(umka: *Instance) *Error;

extern fn umkaAlive(umka: *Instance) c_char;

extern fn umkaAsm(umka: *Instance) [*:0]const u8;

extern fn umkaAddModule(umka: *Instance, file_name: [*:0]const u8, source_string: [*:0]const u8) c_char;

extern fn umkaAddFunc(umka: *Instance, name: [*:0]const u8, func: ExternFunc) c_char;

extern fn umkaGetFunc(umka: *Instance, module_name: ?[*:0]const u8, fn_name: [*:0]const u8, context: *FuncContext) c_char;

extern fn umkaGetCallStack(umka: *Instance, depth: c_int, name_size: c_int, offset: *c_int, file_name: [*]u8, fn_name: [*]u8, line: *c_int) c_char;

extern fn umkaSetHook(umka: *Instance, event: HookEvent, hook: HookFunc) void;

extern fn umkaAllocData(umka: *Instance, size: c_int, on_free: ExternFunc) *anyopaque;

extern fn umkaIncRef(umka: *Instance, ptr: *anyopaque) void;

extern fn umkaDecRef(umka: *Instance, ptr: *anyopaque) void;

extern fn umkaGetMapItem(umka: *Instance, map: *Map, key: StackSlot) *anyopaque;

extern fn umkaMakeStr(umka: *Instance, str: [*:0]const u8) [*]u8;

extern fn umkaGetStrLen(str: [*]const u8) c_int;

extern fn umkaMakeDynArray(umka: *Instance, array: [*]anyopaque, type: *anyopaque, len: c_int) void;

extern fn umkaGetDynArrayLen(array: [*]const anyopaque) c_int;

extern fn umkaGetVersion() [*:0]const u8;

extern fn umkaGetMemUsage(umka: *Instance) i64;

extern fn umkaMakeFuncContext(umka: *Instance, closure_type: *anyopaque, entry_offset: c_int, context: FuncContext) void;
