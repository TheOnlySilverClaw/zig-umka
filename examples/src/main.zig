const std = @import("std");
const log = std.log;
const fs = std.fs;
const umka = @import("umka");

const assert = std.debug.assert;

pub fn main() !void {

    log.info("Umka version: {s}", .{ umka.getVersion() });

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

    log.debug("Added module source", .{});

    const zigMultiply = struct {
        fn multiply(params: [*]umka.StackSlot, result: *umka.StackSlot) callconv(.c) void {
            const a = params[0].int;
            const b = params[1].int;
            result.int = a * b;
        }
    };

    try instance.addFunc("zigMultiply", &zigMultiply.multiply);

    instance.compile() catch {
        const err = instance.getError();
        log.err("Failed to compile file {s} function {s} line {d} position {d}: {s}", .{ err.file_name, err.fn_name, err.line, err.pos, err.msg });
        return;
    };

    log.debug("Compiled module successfully", .{});

    var sayHello = instance.getFunc(null, "sayHello") orelse {
        log.warn("Could not find function 'sayHello'", .{});
        return;
    };

    try sayHello.call();

    var add = instance.getFunc(null, "add") orelse {
        log.warn("Could not find function 'add'", .{});
        return;
    };

    add.getParameter(0).int = 4;
    add.getParameter(1).int = 6;

    try add.call();
    add.getParameter(0).int = add.getResult().int;
    try add.call();
    log.debug("Added: {d}", .{ add.getResult().int });

    var radians = instance.getFunc(module_file_name, "radians") orelse {
        log.warn("Could not find function 'radians'", .{});
        return;
    };

    const degree_step = 45;
    var degree_param = radians.getParameter(0);
    for(0..(360 / degree_step) + 1) |index| {
        const degrees: i64 = @intCast(index * degree_step);
        degree_param.int = degrees;
        try radians.call();
        log.debug("{d:>4} deg = {d:.3} rad", .{ degrees, radians.getResult().real });
    }
    

    const Neighbors = extern struct {
        lower: i64,
        higher: i64
    };
    
    var neighbors = instance.getFunc(null, "neighbors") orelse {
        log.warn("Could not find function 'neighbors'", .{});
        return;
    };

    neighbors.getParameter(0).int = 4;
    var neighbors_result: Neighbors = undefined;
    neighbors.setResultTarget(&neighbors_result);
    try neighbors.call();
    log.debug("neighbors: {d} {d}", .{ neighbors_result.lower, neighbors_result.higher });

    var call_zig = instance.getFunc(null, "callZig") orelse {
        log.warn("Could not find function 'callZig'", .{});
        return;
    };
    try call_zig.call();

    const memory = try instance.allocData(1024 * 4, null);
    memory.incRef();
    memory.decRef();
    memory.decRef();

    var greeting = instance.getFunc(null, "greeting") orelse {
        log.warn("Could not find function 'greeting'", .{});
        return;
    };
    const name_string = try instance.makeStr("jolly good fellow");
    greeting.getParameter(0).ptr = name_string.ptr;
    try greeting.call();
    const greeting_string = greeting.getResult().str();
    log.debug("greeting: \"{s}\" (length: {d})", .{ greeting_string.slice(), greeting_string.len() });


    log.info("Memory usage: {d} bytes", .{ instance.getMemUsage() });

}

fn readFileCString(file_name: []const u8, buffer: []u8) ![*:0]u8 {

    const source = try fs.cwd().readFile(file_name, buffer);
    assert(source.len < buffer.len);
    buffer[source.len] = 0;
    return @ptrCast(source.ptr);
}