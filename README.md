Zig bindings for the [Umka](https://github.com/vtereshkov/umka-lang) scripting language.

Tested against Umka 1.5.3

## Usage

There are two modules avaiable:
- "binding" is as close to the C API as possible
- "wrapper" is a more opinionated API on top which should be easier for Zig users

You can add either one as an import like this:

```zig
const umka_dependency = b.dependency("umka", .{});
exe_module.addImport("umka", umka_dependency.module("binding"));
// or
exe_module.addImport("umka", umka_dependency.module("wrapper"));
```

This project only provides the bindings!
You have to build and link Umka as a static libary.

Build configuration and further examples can be found under [examples](/examples).

## To run the examples
- install Zig, at least version 0.14.0
- get a static Umka libary build called libumka.a
- drop it into examples
- run `zig build run`