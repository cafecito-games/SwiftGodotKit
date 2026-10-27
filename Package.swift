// swift-tools-version: 6.3
import PackageDescription
let macLibgodotTarget: Target = .binaryTarget(
    name: "mac_libgodot",
    url: "https://github.com/cafecito-games/SwiftGodotKit/releases/download/v4.7.2-20261026.1-libgodot.2/libgodot-macos.xcframework.zip",
    checksum: "6924ee56143baae80d062afee3f6afb227f0a00e2082c642a7ce163fd40e9335"
)

let iosLibgodotTarget: Target = .binaryTarget(
    name: "ios_libgodot",
    url: "https://github.com/cafecito-games/SwiftGodotKit/releases/download/v4.7.2-20261026.1-libgodot.2/libgodot-ios.xcframework.zip",
    checksum: "25242eecaee94043592636eadaf317893d36f3e78c3447d4de5fe9b2c3d8ec6d"
)

let package = Package(
    name: "SwiftGodotKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftGodotKit",
            targets: ["SwiftGodotKit"]),
        .library(
            name: "SwiftGodotRuntime",
            targets: ["SwiftGodotRuntime"]),
        .executable(name: "TrivialSample", targets: ["TrivialSample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cafecito-games/SwiftGodotBinary", exact: "0.4.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.

        // The lightweight embedded-instance boundary: SwiftGodot plus the
        // pinned libgodot payloads, with no UI hosting sources. This target is
        // the single owner of the libgodot binary metadata and C declarations.
        .target(
            name: "SwiftGodotRuntime",
            dependencies: [
                .product(name: "SwiftGodot", package: "SwiftGodotBinary"),
                "libgodot",
                .target(name: "apple_plugin_stubs", condition: .when(platforms: [.iOS])),
                .target(name: "mac_libgodot", condition: .when(platforms: [.macOS])),
                .target(name: "ios_libgodot", condition: .when(platforms: [.iOS])),
            ]
        ),

        // The SwiftUI/AppKit/UIKit view-hosting product. It keeps every UI,
        // lifecycle, routing, and sample behavior and builds on the runtime
        // target for instance creation and destruction.
        .target(
            name: "SwiftGodotKit",
            dependencies: [
                .product(name: "SwiftGodot", package: "SwiftGodotBinary"),
                .target(name: "SwiftGodotRuntime"),
                "libgodot",
            ]
        ),

        .executableTarget(
            name: "TrivialSample",
            dependencies: ["SwiftGodotKit"],
            resources: [
                .copy("main.pck"),
                .copy("AxolotlDemo-LICENSE.txt"),
                .copy("THIRD_PARTY.md"),
                .copy("Xolonium-OFL.txt"),
            ]
        ),

        .target(
            name: "apple_plugin_stubs",
            path: "Sources/apple_plugin_stubs",
            publicHeadersPath: "include"
        ),

        macLibgodotTarget,
        iosLibgodotTarget,
        .systemLibrary(
            name: "libgodot"
        ),
        .testTarget(
            name: "SwiftGodotRuntimeTests",
            dependencies: ["SwiftGodotRuntime"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
