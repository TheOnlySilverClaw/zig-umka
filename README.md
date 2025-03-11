Zig bindings for the [Umka](https://github.com/vtereshkov/umka-lang) scripting language.

Tested against a build from Commit f43ebf3.

## Roadmap

- [x] call a script with a main function
- [x] call an Umka function from Zig
- [x] pass parameters to Umka functions
- [x] get results from a funtion call
- [ ] call Zig functions from Umka
- [x] add Umka modules to current instance
- ...

## To run the examples
- install Zig, at least version 0.14.0
- get an Umka libary build via make (the downloaded release currently does not work)
- drop it into example/libumka.a
- run `zig build run`