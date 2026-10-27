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
    branch: "main"
)
```

Then add the product to the app target:

```swift
.product(name: "SwiftGodotKit", package: "SwiftGodotKit")
```

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

## Development

This repository uses [Task](https://taskfile.dev) rather than Make.

```sh
task                    # list tasks
task build              # build the library
task build:sample       # build TrivialSample
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
