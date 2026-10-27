# Standalone example

This Swift package uses the local SwiftGodotKit checkout and Cafecito
SwiftGodotBinary v0.4.2. SwiftGodotKit downloads the matching Cafecito
libgodot XCFrameworks through SwiftPM. Both package manifests use the same
exact binary dependency, so the executable contains one SwiftGodot runtime.

Then build and run the macOS example:

```sh
swift run --package-path StandaloneExample StandaloneExample
```

The app creates its scene in Swift and does not need a game pack.
