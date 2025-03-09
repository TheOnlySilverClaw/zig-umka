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

    try instance.init(file_name, source, stack_size, &.{}, true, true, null);
    assert(instance.alive());

    instance.compile() catch {
        const err = instance.getError();
        print("failed to compile file {s} function {s} line {d} position {d}: {s}\n", .{ err.file_name, err.fn_name, err.line, err.pos, err.msg });
        return;
    };

    var sayHello: umka.FuncContext = undefined;
    try instance.getFunc(null, "sayHello", &sayHello);
    try instance.call(&sayHello);

    var add: umka.FuncContext = undefined;
    try instance.getFunc(null, "add", &add);
    {        
        var a = umka.getParam(add.params, 0).?;
        a.int = 7;

        var b = umka.getParam(add.params, 1).?;
        b.int = 13;

        try instance.call(&add);
        const result = umka.getResult(add.params, add.result);
        print("added: {d}\n", .{ result.int });
    }

    var radians: umka.FuncContext = undefined;
    try instance.getFunc(null, "radians", &radians);
    {
        var degrees = umka.getParam(radians.params, 0).?;
        degrees.int = 45;

        try instance.call(&radians);
        const result = umka.getResult(radians.params, radians.result);
        print("radians: {d:.5}\n", .{ result.real });
    }

    var neighbors: umka.FuncContext = undefined;
    try instance.getFunc(null, "neighbors", &neighbors);
    {
        var value = umka.getParam(neighbors.params, 0).?;
        value.int = 4;

        var result: [2]i64 = .{ 0, 0 };
        var result_param = &neighbors.params[0];
        result_param.ptr = @ptrCast(&result);

        try instance.call(&neighbors);
        print("neighbors: {d} {d}\n", .{ result[0], result[1] });
    }

    var next_three: umka.FuncContext = undefined;
    try instance.getFunc(null, "nextThree", &next_three);
    {
        var value = umka.getParam(next_three.params, 0).?;
        value.int = 3;

        var result: [3]i64 = undefined;
        var result_param = &next_three.params[0];
        result_param.ptr = @ptrCast(&result);

        try instance.call(&next_three);
        print("next three: {d}\n", .{ result });
    }

    instance.free();
}

fn readFileCString(file_name: []const u8, buffer: []u8) ![*:0]u8 {

    const source = try fs.cwd().readFile(file_name, buffer);
    assert(source.len < buffer.len);
    buffer[source.len] = 0;
    return @ptrCast(source.ptr);
}