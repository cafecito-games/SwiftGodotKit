# Cafecito porting contract

This document records the compatibility boundary between SwiftGodotKit,
Cafecito SwiftGodot, and Cafecito Godot.

## Completed in this repository

- SwiftPM resolves the exact public `cafecito-games/SwiftGodotBinary` v0.4.1
  package, avoiding source SwiftGodot, SwiftSyntax, and binding generators.
- Runtime SPI imports use the consolidated `SwiftGodot` module.
- The removed `GDExtension` module import has been eliminated.
- Godot object access is main-actor isolated to match SwiftGodot's
  engine-thread executor.
- Makefiles were replaced by root and sample Taskfiles.
- Payload publishing targets `cafecito-games/SwiftGodotKit`, while release
  notes retain both the custom-Godot orchestrator commit and upstream engine
  base commit as provenance.
- iOS builds use Cafecito Godot's `ios_simulator=yes` SCons option.
- Apple libgodot payloads are published from custom-Godot release
  `v4.7.2-20261026.1` and record orchestrator commit
  `8c7cff31a7cf9412447ee51ff9a6fde8137ae67f` plus Godot base commit
  `ed1daf0bf001b61586d9930840f2f1394092c079`.

## Custom Godot contract

Godot 4.7.2 already provides:

```text
libgodot_create_godot_instance
libgodot_destroy_godot_instance
```

SwiftGodotKit's iOS host also requires:

```text
libgodot_ios_create_rendering_layer
libgodot_ios_initialize_rendering_layer
libgodot_ios_layout_rendering_layer
libgodot_ios_start_rendering_layer
libgodot_ios_stop_rendering_layer
```

The reference implementation is the following ordered commit series on
`migueldeicaza/godot:swiftgodotkit-4.7`:

1. `108d2fd2e4` — Apple native surface and macOS embedded display server
2. `41dd7f4e91` — iOS libgodot build wiring
3. `b50b730f1d` — iOS libgodot implementation
4. `063e9e72e6` — expose `DisplayServerAppleEmbedded` host APIs
5. `2d2d383cf4` — remove standalone entry-point objects from iOS archives
6. `39453590a4` — include-order correction
7. `9738ba5426` — Godot 4.7 embedded API adaptation
8. `324455d4e7` — expose embedded display classes in API dumps
9. `4c95248ac7` — SDL device checks for static iOS libgodot

The port is delivered by Cafecito custom-Godot release
`v4.7.2-20261026.1`. The historical reference series is retained below to
explain the runtime contract; Cafecito targets 4.7.2 rather than that branch's
Godot 4.7.3-rc base.

SwiftGodotKit dynamically binds these classes and methods, so their names and
signatures are part of the runtime contract:

- `RenderingNativeSurfaceApple.create`
- `Window.set_native_surface`
- `DisplayServerMacOSEmbedded.set_native_surface`
- `DisplayServerMacOSEmbedded.resize_window`
- `DisplayServerAppleEmbedded.get_singleton`
- `DisplayServerAppleEmbedded.set_native_surface`
- `DisplayServerAppleEmbedded.resize_window`
- `DisplayServerAppleEmbedded.touch_press`
- `DisplayServerAppleEmbedded.touch_drag`
- `DisplayServerAppleEmbedded.touches_canceled`

The embedded display classes must also be visible while dumping the extension
API so SwiftGodot and engine builds can be validated from the same source.

## Payload acceptance checks

`scripts/make-libgodot.xcframework` enforces the critical iOS conditions:

- all seven C symbols above are exported;
- the archive does not export `_main`;
- no standalone `app.*.o` object is present; and
- exact device and simulator architectures are packaged into one XCFramework.

For the locked custom-Godot SDK release, run:

```sh
task payload:release
task build
task build:sample
```

`payload:release` fetches and verifies `config/libgodot-sdk.json`; use
`payload:build` for an explicitly local source build. Publication also checks a
provenance stamp binding the ZIP checksums to the locked SDK. Then publish a
payload, update `Package.swift`, and test both the
Axolotl macOS target and iOS Simulator target before declaring the fork stable.
