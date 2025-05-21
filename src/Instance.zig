const types = @import("types.zig");

const Error = types.Error;
const WarningCallback = types.WarningCallback;

const ExternFunc = types.ExternFunc;
const FuncContext = types.FuncContext;
const Function = @import("Function.zig");

const functions = @import("functions.zig");

const Self = @This();

pub const Options = struct {
    stack_size: c_int = 1024 * 1024,
    args: [][*:0]const u8 = &.{},
    file_system_enabled: bool = true,
    impl_libs_enabled: bool = true,
    warning_callback: ?*WarningCallback = null
};

// internal Umka instance handle
handle: *anyopaque,

pub fn alloc() error{Alloc}!Self {

    if(functions.umkaAlloc()) |handle| {
        return .{ .handle = handle };
    } else return error.Alloc;
}

pub fn init(self: Self, file_name: ?[*:0]const u8, source_string: ?[*:0]const u8, options: Options) error{Init}!void {
    
    const success = functions.umkaInit(
        self.handle,
        file_name,
        source_string,
        options.stack_size,
        null,
        @intCast(options.args.len),
        options.args.ptr,
        if(options.file_system_enabled) 1 else 0,
        if(options.impl_libs_enabled) 1 else 0,
        options.warning_callback);

    if(success != 1) return error.Init;
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

pub fn addFunc(self: Self, name: [*:0]const u8, function: *const ExternFunc) error{AddFunc}!void {
    const success = functions.umkaAddFunc(self.handle, name, function);
    if(success != 1) return error.AddFunc;
}

pub fn getFunc(self: *const Self, module: ?[*:0]const u8, name: [*:0]const u8) error{GetFunc} !Function {
    
    var func = Function {
        .instance = self.handle,
        .context = undefined
    };

    const success = functions.umkaGetFunc(func.instance, module, name, &func.context);
    if(success != 1) return error.GetFunc;
    return func;
}

pub fn getError(self: Self) *Error {
    return functions.umkaGetError(self.handle);
}
