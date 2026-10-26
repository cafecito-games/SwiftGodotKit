# SwiftGodotKit

SwiftGodotKit embeds Godot in an existing SwiftUI application and lets Swift
code drive the engine without loading a separate GDExtension.

This is Cafecito Games' hard fork of
[migueldeicaza/SwiftGodotKit](https://github.com/migueldeicaza/SwiftGodotKit).
It targets:

- [cafecito-games/SwiftGodot](https://github.com/cafecito-games/SwiftGodot)
  v0.4.0;
- Cafecito Godot 4.7.2 from the private `cafecito-games/custom-godot`
  repository; and
- Swift 6.3 or later, compiling this package in Swift 5 language mode.

## Fork status

The Swift source now builds against Cafecito SwiftGodot. The old split
`SwiftGodotRuntime` and `GDExtension` module imports have been migrated to the
fork's consolidated `SwiftGodot` module, and engine-facing APIs are isolated to
the main actor used by SwiftGodot's engine-thread executor.

The binary `libgodot` URLs in `Package.swift` are temporarily still the
upstream Godot 4.7.3-rc payloads. They make source-level development possible,
but they are not the final Cafecito runtime contract. Do not publish a stable
SwiftGodotKit release until custom Godot provides the Apple embedding APIs and
replacement XCFrameworks described in [the porting notes](docs/PORTING.md).

Run the contract check at any time:

```sh
task compatibility:check
```

It intentionally fails on an engine checkout that only implements Godot's
basic create/destroy `libgodot` API.

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

The package already resolves `cafecito-games/SwiftGodot` v0.4.0. Do not add a
second SwiftGodot implementation to the same target.

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

Once the custom engine includes the required Apple embedding patch set:

```sh
task compatibility:check
task payload:release
```

This builds macOS arm64/x86_64 shared libraries and iOS arm64 device/simulator
static libraries, then creates zipped XCFrameworks under `build/`.

To publish the payloads on this repository and rewrite their URLs/checksums in
`Package.swift`:

```sh
task release:publish VERSION=v0.1.0-libgodot.1
```

Use a fresh tag for every payload because SwiftPM caches binary-target URLs.
Set `RELEASE_PRERELEASE=1` for a prerelease. `RELEASE_REPO`, `GODOT_REPO`,
`CUSTOM_GODOT`, `GODOT`, and `OUTPUT` are overrideable Task variables.

The original MIT license and attribution are retained in [LICENSE](LICENSE).
