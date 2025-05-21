const types = @import("types.zig");

const Error = types.Error;
const WarningCallback = types.WarningCallback;

const FuncContext = types.FuncContext;
const ExternFunc = types.ExternFunc;

const Map = types.Map;
const StackSlot = types.StackSlot;

const HookEvent = types.HookEvent;
const HookFunc = types.HookFunc;

const Instance = anyopaque;

pub extern fn umkaAlloc() ?*Instance;

pub extern fn umkaInit(
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

pub extern fn umkaCompile(umka: *Instance) c_char;

pub extern fn umkaRun(umka: *Instance) c_int;

pub extern fn umkaCall(umka: *Instance, context: *FuncContext) c_int; 

pub extern fn umkaFree(umka: *Instance) void; 

pub extern fn umkaGetError(umka: *Instance) *Error;

pub extern fn umkaAlive(umka: *Instance) c_char;

pub extern fn umkaAsm(umka: *Instance) [*:0]const u8;

pub extern fn umkaAddModule(umka: *Instance, file_name: [*:0]const u8, source_string: [*:0]const u8) c_char;

pub extern fn umkaAddFunc(umka: *Instance, name: [*:0]const u8, func: *const ExternFunc) c_char;

pub extern fn umkaGetFunc(umka: *Instance, module_name: ?[*:0]const u8, fn_name: [*:0]const u8, context: *FuncContext) c_char;

pub extern fn umkaGetCallStack(umka: *Instance, depth: c_int, name_size: c_int, offset: *c_int, file_name: [*]u8, fn_name: [*]u8, line: *c_int) c_char;

pub extern fn umkaSetHook(umka: *Instance, event: HookEvent, hook: HookFunc) void;

pub extern fn umkaAllocData(umka: *Instance, size: c_int, on_free: ExternFunc) *anyopaque;

pub extern fn umkaIncRef(umka: *Instance, ptr: *anyopaque) void;

pub extern fn umkaDecRef(umka: *Instance, ptr: *anyopaque) void;

pub extern fn umkaGetMapItem(umka: *Instance, map: *Map, key: StackSlot) *anyopaque;

pub extern fn umkaMakeStr(umka: *Instance, str: [*:0]const u8) [*]u8;

pub extern fn umkaGetStrLen(str: [*]const u8) c_int;

pub extern fn umkaMakeDynArray(umka: *Instance, array: [*]anyopaque, type: *anyopaque, len: c_int) void;

pub extern fn umkaGetDynArrayLen(array: [*]const anyopaque) c_int;

pub extern fn umkaGetVersion() [*:0]const u8;

pub extern fn umkaGetMemUsage(umka: *Instance) i64;

pub extern fn umkaMakeFuncContext(umka: *Instance, closure_type: *anyopaque, entry_offset: c_int, context: FuncContext) void;
