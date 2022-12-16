# Changelog for trace.zig

## 0.2.0

* Changed instrument function to only support non generic and non-variadic functions
  * But supports now arbitrary number of (non-generic) arguments 
* Fixed issues
  * [More function argument patterns for instrument](https://gitlab.com/zig_tracing/trace.zig/-/issues/6)
  * [Reorganize instrument into own folder and split into several files](https://gitlab.com/zig_tracing/trace.zig/-/issues/7)
  * [Restructure instument tests](https://gitlab.com/zig_tracing/trace.zig/-/issues/9)

## 0.1.0

* First release
* Realizes Span and instrument
  * instrument is only supported for some functions
* Documentation and tests but no code coverage
