# RuntimeExample

A fresh macOS command-line consumer of the `SwiftGodotRuntime` product. It
proves the headless boundary is usable without the `SwiftGodotKit` UI target
and without copying any libgodot header, module map, binary URL, or checksum:
the package depends on exactly one product from this repository.

The executable bundles a minimal Godot project and exercises the complete
headless lifecycle — create, start, confirm started, a few main-loop
iterations, destroy — exiting `0` only when every step passes.

Run it directly:

```sh
swift run RuntimeExample
```

Or through the repository gate, which also runs the runtime unit tests and a
verbose build-plan assertion that the fixture build compiles no
`Sources/SwiftGodotKit/` UI sources:

```sh
task test:runtime        # from the repository root
```
