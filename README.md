Zig bindings for the [Umka](https://github.com/vtereshkov/umka-lang) scripting language.

Tested against a build from Commit 127e678.

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

## What works so far

- call a script with a main function
- call an Umka function from Zig
- pass parameters to Umka functions
- get results from a funtion call
- call Zig functions from Umka
- add Umka modules to current instance

## To run the examples
- install Zig, at least version 0.14.0
- get an Umka libary build via make (the downloaded release currently does not work)
- drop it into example/libumka.a
- run `zig build run`