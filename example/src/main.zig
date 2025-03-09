const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const umka = @import("umka");

const print = debug.print;
const assert = debug.assert;

pub fn main() !void {

    print("Umka version: {s}\n", .{ umka.getVersion() });

    const file_name = "test.um";
    var buffer: [1024]u8 = undefined;
    const source = try readFileCString(file_name, &buffer);
    
    const stack_size = 1024 * 4;
    var instance: *umka.Instance = @ptrCast(@alignCast(umka.alloc()));

    const ok = instance.init(file_name, source, stack_size, &.{}, true, true, null);
    assert(ok);
    assert(instance.alive());

    if(instance.compile()) {

        var sayHello: umka.FuncContext = undefined;
        if(instance.getFunc(null, "sayHello", &sayHello)) {
            _ = instance.call(&sayHello);
        }

        var calculate: umka.FuncContext = undefined;
        if(instance.getFunc(null, "calculate", &calculate)) {
            
            var a_param = umka.getParam(calculate.params, 0);
            a_param.?.int = 7;

            var b_param = umka.getParam(calculate.params, 1);
            b_param.?.int = 11;

            if(instance.call(&calculate)) {
                const result = umka.getResult(calculate.params, calculate.result).int;
                print("result from Umka: {d}\n", .{ result });
            }
        }

    } else {
        const err = instance.getError();
        print("failed to compile file {s} function {s} line {d} position {d}: {s}\n", .{ err.file_name, err.fn_name, err.line, err.pos, err.msg });
    }

    instance.free();
}

fn readFileCString(file_name: []const u8, buffer: []u8) ![*:0]u8 {

    const source = try fs.cwd().readFile(file_name, buffer);
    assert(source.len < buffer.len);
    buffer[source.len] = 0;
    return @ptrCast(source.ptr);
}