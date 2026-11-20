// swift-tools-version: 6.3
import PackageDescription
let macLibgodotTarget: Target = .binaryTarget(
    name: "mac_libgodot",
    url: "https://github.com/cafecito-games/SwiftGodotKit/releases/download/v4.7.2-20261120.4-libgodot.1/libgodot-macos.xcframework.zip",
    checksum: "6448f52bc0b4fe966e83a11dbdad85f7b581c9e1fa009581e3c4329049dfc62c"
)

let iosLibgodotTarget: Target = .binaryTarget(
    name: "ios_libgodot",
    url: "https://github.com/cafecito-games/SwiftGodotKit/releases/download/v4.7.2-20261120.4-libgodot.1/libgodot-ios.xcframework.zip",
    checksum: "3b6a4eada91d47528d439eb90e0d2d1771f27426dca9e52cb6a9df7da0b0b857"
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
        .package(url: "https://github.com/cafecito-games/SwiftGodotBinary", exact: "0.6.0"),
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
