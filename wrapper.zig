const binding = @import("umka.zig");
const assert = @import("std").debug.assert;


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

    pub fn assembly(self: Instance) [*:0]const u8 {
        return binding.umkaAsm(self.handle);
    }
    pub fn addModule(self: Instance, file_name: [*:0]const u8, source_string: [*:0]const u8) error{AddModule}!void {
        const success = binding.umkaAddModule(self.handle, file_name, source_string);
        if(success != 1) return error.AddModule;
    }

    pub fn addFunc(self: Instance, name: [*:0]const u8, func: binding.ExternFunc) error{AddFunc}!void {
        const success = binding.umkaAddFunc(self.handle, name, func);
        if(success != 1) return error.AddFunc;
    }

    pub fn getError(self: Instance) *binding.Error {
        return binding.umkaGetError(self.handle);
    }
};

pub const Function = struct {
        
    runtime: *binding.Instance,
    module: ?[*:0]const u8,
    name: [*:0]const u8,
    context: binding.FuncContext,

    pub fn new(module: ?[*:0]const u8, name: [*:0]const u8) Function {
        return .{
            .runtime = undefined,
            .module = module,
            .name = name,
            .context = undefined
        };
    }

    pub fn get(self: *Function, instance: Instance) error{GetFunction}!void {
        self.runtime = instance.handle;
        const success = binding.umkaGetFunc(instance.handle, self.module, self.name, &self.context);
        if(success != 1) return error.GetFunction;
    }

    pub fn getResult(self: *Function) *binding.StackSlot {
        return binding.getResult(self.context.params, self.context.result);
    }

    pub fn setResultTarget(self: *Function, target: *anyopaque) void {
        self.getResult().ptr = @ptrCast(target);
    }

    pub fn call(self: *Function) error{CallFunction}!void {
        const code = binding.umkaCall(self.runtime, &self.context);
        if(code != 0) return error.CallFunction;
    }

    pub fn getParameter(self: *Function, index: i32) *binding.StackSlot {
        return binding.getParam(self.context.params, index).?;
    }

    pub fn setParameters(self: *Function, values: []const binding.StackSlot) void {

        const params = self.context.params;
        const layout = binding.getParamLayout(params);
        assert(values.len <= layout.num_params - layout.num_result_params - 1);
        
        const first_slot_index = layout.firstSlotIndex();
        for(0..values.len) |index| {
            const slot_index: usize = @intCast(first_slot_index[index + 1]);
            params[slot_index] = values[index];
        }
    }
};
