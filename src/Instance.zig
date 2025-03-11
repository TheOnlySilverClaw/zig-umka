const types = @import("types.zig");

const Error = types.Error;
const WarningCallback = types.WarningCallback;

const ExternFunc = types.ExternFunc;
const FuncContext = types.FuncContext;

const functions = @import("functions.zig");

const Self = @This();

// internal Umka instance handle
handle: *anyopaque,

pub fn alloc(
    file_name: ?[*:0]const u8,
    source_string: ?[*:0]const u8,
    stack_size: c_int,
    args: [][*:0]const u8,
    file_system_enabled: bool,
    impl_libs_enabled: bool,
    warning_callback: ?*WarningCallback) error{Init}!Self {
    
    const handle = functions.umkaAlloc();

    const success = functions.umkaInit(
        handle,
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

    return .{ .handle = handle };
}

pub fn free(self: Self) void {
    functions.umkaFree(self.handle);
}

pub fn compile(self: Self) error{Compile}!void {
    const success = functions.umkaCompile(self.handle);
    if(success != 1) return error.Compile;
}

pub fn run(self: Self) error{Run}!void {
    const code = functions.umkaRun(self.handle);
    if(code != 0) return error.Run;
}

pub fn call(self: Self, context: *FuncContext) error{Call}!void {
    const code = functions.umkaCall(self.handle, context);
    if(code != 0) return error.Call;
}

pub fn alive(self: Self) bool {
    return functions.umkaAlive(self.handle) == 1;
}

pub fn assembly(self: Self) [*:0]const u8 {
    return functions.umkaAsm(self.handle);
}
pub fn addModule(self: Self, file_name: [*:0]const u8, source_string: [*:0]const u8) error{AddModule}!void {
    const success = functions.umkaAddModule(self.handle, file_name, source_string);
    if(success != 1) return error.AddModule;
}

pub fn addFunc(self: Self, name: [*:0]const u8, function: *const ExternFunc) error{AddFunction}!void {
    const success = functions.umkaAddFunc(self.handle, name, function);
    if(success != 1) return error.AddFunction;
}

pub fn getError(self: Self) *Error {
    return functions.umkaGetError(self.handle);
}
