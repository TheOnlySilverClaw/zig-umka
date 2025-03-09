const binding = @import("umka.zig");


pub const getVersion = binding.umkaGetVersion;

pub const Instance = struct {

    handle: *binding.Instance,

    pub fn alloc(
        file_name: ?[*:0]const u8,
        source_string: ?[*:0]const u8,
        stack_size: c_int,
        args: [][*:0]const u8,
        file_system_enabled: bool,
        impl_libs_enabled: bool,
        warning_callback: ?*binding.WarningCallback) error{Init}!Instance {
        
        const handle = binding.umkaAlloc();

        const success = binding.umkaInit(
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

    pub fn free(self: Instance) void {
        binding.umkaFree(self.handle);
    }

    pub fn compile(self: Instance) error{Compile}!void {
        const success = binding.umkaCompile(self.handle);
        if(success != 1) return error.Compile;
    }

    pub fn run(self: Instance) error{Run}!void {
        const code = binding.umkaRun(self.handle);
        if(code != 0) return error.Run;
    }

    pub fn call(self: Instance, context: *binding.FuncContext) error{Call}!void {
        const code = binding.umkaCall(self.handle, context);
        if(code != 0) return error.Call;
    }

    pub fn alive(self: Instance) bool {
        return binding.umkaAlive(self.handle) == 1;
    }

    pub const assembly = binding.umkaAsm;

    pub fn addModule(self: Instance, file_name: [*:0]const u8, source_string: [*:0]const u8) error{AddModule}!void {
        const success = binding.umkaAddModule(self.handle, file_name, source_string);
        if(success != 1) return error.AddModule;
    }

    pub fn addFunc(self: Instance, name: [*:0]const u8, func: binding.ExternFunc) error{AddFunc}!void {
        const success = binding.umkaAddFunc(self.handle, name, func);
        if(success != 1) return error.AddFunc;
    }

    pub fn getFunc(self: Instance, module_name: ?[*:0]const u8, fn_name: [*:0]const u8, context: *binding.FuncContext) error{GetFunc}!void {

        const success = binding.umkaGetFunc(self.handle, module_name, fn_name, context);
        if(success != 1) return error.GetFunc;
    }

    pub fn getError(self: Instance) *binding.Error {
        return binding.umkaGetError(self.handle);
    }
};

pub fn Function(R: type) type {

    return struct {
        
        const Self = @This();
        
        runtime: *binding.Instance,
        module: ?[*:0]const u8,
        name: [*:0]const u8,
        context: binding.FuncContext,

        pub fn new(module: ?[*:0]const u8, name: [*:0]const u8) Self {
            return .{
                .runtime = undefined,
                .module = module,
                .name = name,
                .context = undefined
            };
        }

        pub fn get(self: *Self, instance: Instance) error{GetFunction}!void {
            self.runtime = instance.handle;
            const success = binding.umkaGetFunc(instance.handle, self.module, self.name, &self.context);
            if(success != 1) return error.GetFunction;
        }

        pub fn call(self: *Self) error{CallFunction}!R {
            
            switch (@typeInfo(R)) {
                .void => try self.callVoid(),
                .@"struct", .array => return try self.callMultiReturn(),
                .int, .float => return try self.callSingleReturn(),
                else => @compileError("Unsupported return type")
            }
        }

        fn callVoid(self: *Self) error{CallFunction}!void {

            const code = binding.umkaCall(self.runtime, &self.context);
            if(code != 0) return error.CallFunction;
        }

        fn callSingleReturn(self: *Self) error{CallFunction}!R {

            try self.callVoid();

            const result = binding.getResult(self.context.params, self.context.result);
            return switch (R) {
                i64 => result.int,
                u64 => result.uint,
                f64 => result.real,
                f32 => result.real32,
                else => @compileError("Unsupported return type")
            };
        }

        fn callMultiReturn(self: *Self) error{CallFunction}!R {

            var result: R = undefined;
            var param = binding.getResult(self.context.params, self.context.result);
            param.ptr = @ptrCast(&result);

            try self.callVoid();

            return result;
        }

        pub fn setParameter(self: *Self, index: c_int, value: binding.StackSlot) !void {
            const param = try binding.getParam(self.context.params, index);
            param.* = value;
        }
    };
}
