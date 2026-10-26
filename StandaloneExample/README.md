# Standalone example

This Swift package uses the local SwiftGodotKit checkout and Cafecito
SwiftGodot v0.4.0. SwiftGodotKit downloads its libgodot XCFrameworks through
SwiftPM.

Then build and run the macOS example:

```sh
swift run --package-path StandaloneExample StandaloneExample
```

The app creates its scene in Swift and does not need a game pack.
