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
    
    const instance = try umka.Instance.alloc();
    try instance.init(file_name, source, .{});
    defer instance.free();
        
    assert(instance.alive());

    var module_buffer: [256]u8 = undefined;
    const module_file_name = "module.um";
    const module_source = try readFileCString(module_file_name, &module_buffer);
    try instance.addModule(module_file_name, module_source);

    const zigMultiply = struct {
        fn multiply(params: [*]umka.StackSlot, result: *umka.StackSlot) callconv(.C) void {
            const a = params[0].int;
            const b = params[1].int;
            result.int = a * b;
        }
    };

    try instance.addFunc("zigMultiply", &zigMultiply.multiply);

    instance.compile() catch {
        const err = instance.getError();
        print("failed to compile file {s} function {s} line {d} position {d}: {s}\n", .{ err.file_name, err.fn_name, err.line, err.pos, err.msg });
        return;
    };

    var sayHello = try instance.getFunc(null, "sayHello");
    try sayHello.call();

    var add = try instance.getFunc(null, "add");
    add.setParameters(&.{ .{ .int = 4 }, .{ .int = 6 } });
    try add.call();
    add.getParameter(0).int = add.getResult().int;
    try add.call();
    print("added: {d}\n", .{ add.getResult().int });

    var radians = try instance.getFunc(module_file_name, "radians");
    const degree_step = 45;
    var degree_param = radians.getParameter(0);
    for(0..(360 / degree_step) + 1) |index| {
        const degrees: i64 = @intCast(index * degree_step);
        degree_param.int = degrees;
        try radians.call();
        print("{d:>4} deg = {d:.3} rad\n", .{ degrees, radians.getResult().real });
    }

    const Neighbors = extern struct {
        lower: i64,
        higher: i64
    };
    var neighbors = try instance.getFunc(null, "neighbors");
    neighbors.getParameter(0).int = 4;
    var neighbors_result: Neighbors = undefined;
    neighbors.setResultTarget(&neighbors_result);
    try neighbors.call();
    print("neighbors: {d} {d}\n", .{ neighbors_result.lower, neighbors_result.higher });

    var call_zig = try instance.getFunc(null, "callZig");
    try call_zig.call();

    const memory = try instance.allocData(1024 * 4, null);
    memory.incRef();
    memory.decRef();
    memory.decRef();

    var greeting = try instance.getFunc(null, "greeting");
    const name_string = try instance.makeStr("jolly good fellow");
    greeting.getParameter(0).ptr = name_string.ptr;
    try greeting.call();
    const greeting_string = greeting.getResult().str();

    print("greeting: \"{s}\" (length: {d})\n", .{ greeting_string.slice(), greeting_string.len() });

    print("Memory usage: {d} bytes\n", .{ instance.getMemUsage() });

}

fn readFileCString(file_name: []const u8, buffer: []u8) ![*:0]u8 {

    const source = try fs.cwd().readFile(file_name, buffer);
    assert(source.len < buffer.len);
    buffer[source.len] = 0;
    return @ptrCast(source.ptr);
}