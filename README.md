# SwiftGodotKit

SwiftGodotKit embeds Godot in an existing SwiftUI application and lets Swift
code drive the engine without loading a separate GDExtension.

This is Cafecito Games' hard fork of
[migueldeicaza/SwiftGodotKit](https://github.com/migueldeicaza/SwiftGodotKit).
It targets these exact binary/runtime inputs:

- [cafecito-games/SwiftGodotBinary](https://github.com/cafecito-games/SwiftGodotBinary)
  v0.4.2, produced by the matching Cafecito SwiftGodot release;
- [Cafecito Godot v4.7.2-20261026.1](https://github.com/cafecito-games/custom-godot/releases/tag/v4.7.2-20261026.1)
  with Godot base commit `ed1daf0bf001b61586d9930840f2f1394092c079`; and
- Swift 6.3 or later, compiling this package in Swift 5 language mode.

## Fork status

The Swift source now builds against Cafecito SwiftGodot. The old split
`SwiftGodotRuntime` and `GDExtension` module imports have been migrated to the
fork's consolidated `SwiftGodot` module, and engine-facing APIs are isolated to
the main actor used by SwiftGodot's engine-thread executor.

SwiftPM downloads both SwiftGodot and libgodot from public, immutable Cafecito
releases. The libgodot payloads are derived from the checksum-locked custom
Godot SDK and published in
[v4.7.2-20261026.1-libgodot.2](https://github.com/cafecito-games/SwiftGodotKit/releases/tag/v4.7.2-20261026.1-libgodot.2).

Run the contract check at any time:

```sh
task compatibility:sdk
```

Use `task compatibility:check` instead when validating a local custom-Godot
source checkout.

## Add the package

```swift
.package(
    url: "https://github.com/cafecito-games/SwiftGodotKit",
    from: "0.1.0"
)
```

Then add the product to the app target:

```swift
.product(name: "SwiftGodotKit", package: "SwiftGodotKit")
```

Use `branch: "main"` instead of a version only when you deliberately want to
track development. The semver line starts at `0.1.0`; the older tags inherited
from the upstream fork have been removed so range requirements resolve to
Cafecito releases only. The `v*-libgodot.*` tags are payload releases managed
by `task release:publish` (see below), not package versions, and never satisfy
a version requirement.

The package already resolves the exact `cafecito-games/SwiftGodotBinary`
v0.4.2 package. Do not also depend on source `SwiftGodot`; one executable must
contain exactly one SwiftGodot module/runtime.

SwiftGodot and GDExtensionC arrive as prebuilt XCFrameworks. SwiftPM builds the
small `SwiftGodotMacroLibrary` target from its exact release sources, which
introduces the intentional `swift-syntax` dependency. This avoids compiling
SwiftGodot's generated bindings and generators while using SwiftPM's supported
compiler-macro model.

When moving an existing checkout from source SwiftGodot to this binary release,
discard the old resolution and build products before resolving again:

```sh
swift package reset
rm -f Package.resolved
swift package resolve
```

The exact pin is intentional: SwiftGodot's compiled Swift ABI, generated Godot
API, macro sources, and GDExtension C module must come from one release.

## Choosing a product

The package exposes two library products:

- **`SwiftGodotRuntime`** — the lightweight embedded-instance boundary for
  headless and command-line consumers such as asset exporters and CI tooling.
  It creates, starts, and destroys a Godot instance through libgodot and
  depends only on SwiftGodot plus the pinned libgodot payloads; it compiles no
  SwiftUI/AppKit/UIKit hosting code. This is the seam UzirEdit's asset-pack
  exporter and any other standalone tool should depend on.
- **`SwiftGodotKit`** — the native view-hosting product. It keeps the
  `GodotApp` application lifecycle, `GodotAppView` windows, message routing,
  and display-server integration, and builds on `SwiftGodotRuntime` for
  instance creation and destruction. Existing `import SwiftGodotKit` consumers
  keep compiling unchanged: the runtime boundary and the `initHookCb` /
  `deinitHookCb` hooks are re-exported from this target.

Lifecycle ownership lives entirely in the runtime target. Every instance —
headless or UI-hosted — is created and destroyed through
`GodotRuntime.createInstance(args:initHook:deinitHook:)` /
`GodotRuntime.destroyInstance(_:)`, and every initialization hook is composed
by that one authority: the module-scope compatibility hooks run first, then
the per-instance hooks. A failed creation returns `nil` and needs no
compensating cleanup; a successful instance must be destroyed exactly once.

One executable must contain exactly one SwiftGodot module/runtime and the
platform-appropriate libgodot payload. Both products resolve the same pinned
targets, so mixing them in one dependency graph does not duplicate binaries —
but do not also depend on source `SwiftGodot` (see above).

## Headless example

`RuntimeExample` is a fresh macOS command-line package that depends only on
the `SwiftGodotRuntime` product:

```swift
import SwiftGodotRuntime

guard let instance = GodotRuntime.createInstance(args: ["--headless", "--path", projectPath]) else {
    fatalError("embedded Godot could not create an instance")
}
defer { GodotRuntime.destroyInstance(instance) }
instance.start()
```

The fixture bundles a minimal Godot project, starts the instance, runs a few
main-loop iterations, and destroys it cleanly. Run the whole gate — unit
tests, the fixture, and a build-plan assertion that no UI sources are
compiled — with:

```sh
task test:runtime
```

## SwiftUI example

Add an exported Godot PCK to the application bundle, then create one
`GodotApp` for the process:

```swift
import SwiftGodot
import SwiftGodotKit
import SwiftUI

struct ContentView: View {
    @State private var app = GodotApp(packFile: "game.pck")

    var body: some View {
        GodotAppView()
            .environment(\.godotApp, app)
    }
}
```

`Samples/AxolotlDemo` demonstrates macOS and iOS embedding plus two-way
messages between SwiftUI and Godot. `TrivialSample` builds a scene entirely
from Swift on macOS.

## Releases

Package releases use semantic versioning starting at `v0.1.0`. Trigger the
**Release** workflow from the repository's Actions tab ("Run workflow") with a
version such as `0.1.0` on `main`. The workflow then:

1. validates the version and refuses one that already has a tag, or that an
   existing tag in the same major range would shadow for range-based
   consumers;
2. builds every product and runs the `SwiftGodotRuntime` tests;
3. tags `main` and publishes a GitHub release with generated notes.

The workflow never touches libgodot payload releases: tags of the form
`v*-libgodot.*` are created by `task release:publish` and exist only to host
the binary XCFrameworks that `Package.swift` references.

## Development

This repository uses [Task](https://taskfile.dev) rather than Make.

```sh
task                    # list tasks
task build              # build the library
task build:sample       # build TrivialSample
task test:runtime       # runtime unit tests plus the headless fixture gate
task sample             # PCK + Xcode project
task sample:macos
task sample:ios-simulator
```

The default checkout layout is:

```text
~/CafecitoGames/SwiftGodotKit
~/CafecitoGames/SwiftGodot
~/custom-godot/godot
```

Override any path when needed:

```sh
task build SWIFTGODOT=/path/to/SwiftGodot
task compatibility:check GODOT=/path/to/custom-godot/godot
```

## Build and publish libgodot payloads

The approved custom-Godot release and SDK checksum are pinned in
`config/libgodot-sdk.json`. To fetch, verify, and package that SDK:

```sh
task payload:release
```

This downloads the locked Apple SDK, verifies its release commit, archive
checksum, manifest, and every file, then creates reproducible XCFramework ZIPs
under `build/`. Use `task payload:build` only when testing a local custom-Godot
source checkout; source-built payloads cannot be published as the locked SDK.

To publish the payloads on this repository and rewrite their URLs/checksums in
`Package.swift`:

```sh
task release:publish VERSION=v4.7.2-20261026.1-libgodot.2
```

Use a fresh tag for every payload because SwiftPM caches binary-target URLs.
Set `RELEASE_PRERELEASE=1` for a prerelease. `RELEASE_REPO`, `GODOT_REPO`,
`LIBGODOT_SDK`, `LIBGODOT_SDK_LOCK`, and `OUTPUT` are overrideable Task
variables. `CUSTOM_GODOT` and `GODOT` apply only to source-build and
compatibility tasks.

The original MIT license and attribution are retained in [LICENSE](LICENSE).
