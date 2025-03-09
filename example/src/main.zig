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
    const instance = try umka.Instance.alloc(file_name, source, stack_size, &.{}, true, true, null);
    defer instance.free();
    
    assert(instance.alive());

    instance.compile() catch {
        const err = instance.getError();
        print("failed to compile file {s} function {s} line {d} position {d}: {s}\n", .{ err.file_name, err.fn_name, err.line, err.pos, err.msg });
        return;
    };

    var sayHello = umka.Function(void).new(null, "sayHello");
    try sayHello.get(instance);
    try sayHello.call();

    var add = umka.Function(i64).new(null, "add");
    try add.get(instance);
    try add.setParameter(0, .{ .int = 4 });
    try add.setParameter(1, .{ .int = 6 });
    const add_result = try add.call();
    print("added: {d}\n", .{ add_result });


    var radians = umka.Function(f64).new(null, "radians");
    try radians.get(instance);
    try radians.setParameter(0, .{ .int = 45 });
    const radians_result = try radians.call();
    print("radians: {d:.5}\n", .{ radians_result });

    const Neighbors = extern struct {
        lower: i64,
        higher: i64
    };

    var neighbors = umka.Function(Neighbors).new(null, "neighbors");
    try neighbors.get(instance);
    try neighbors.setParameter(0, .{ .int = 4 });
    const neighboes_result = try neighbors.call();
    print("neighbors: {d} {d}\n", .{ neighboes_result.lower, neighboes_result.higher });
}

fn readFileCString(file_name: []const u8, buffer: []u8) ![*:0]u8 {

    const source = try fs.cwd().readFile(file_name, buffer);
    assert(source.len < buffer.len);
    buffer[source.len] = 0;
    return @ptrCast(source.ptr);
}