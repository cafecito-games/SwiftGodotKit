// swift-tools-version: 6.3
import PackageDescription
let macLibgodotTarget: Target = .binaryTarget(
    name: "mac_libgodot",
    url: "https://github.com/cafecito-games/SwiftGodotKit/releases/download/v4.7.2-20261026.1-libgodot.1/libgodot-macos.xcframework.zip",
    checksum: "1c189a4f5a8974779b7b7561ff9e0cf2da8d499c9747f116ef1e465d694c1a32"
)

let iosLibgodotTarget: Target = .binaryTarget(
    name: "ios_libgodot",
    url: "https://github.com/cafecito-games/SwiftGodotKit/releases/download/v4.7.2-20261026.1-libgodot.1/libgodot-ios.xcframework.zip",
    checksum: "eeaa323f5450a4c7e3f7004494a85220260981b04d70683f0d3bd85669040456"
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
        .executable(name: "TrivialSample", targets: ["TrivialSample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cafecito-games/SwiftGodotBinary", exact: "0.4.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGodotKit",
            dependencies: [
                .product(name: "SwiftGodot", package: "SwiftGodotBinary"),
                "libgodot",
                .target(name: "apple_plugin_stubs", condition: .when(platforms: [.iOS])),
                .target(name: "mac_libgodot", condition: .when(platforms: [.macOS])),
                .target(name: "ios_libgodot", condition: .when(platforms: [.iOS])),
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
    ],
    swiftLanguageModes: [.v5]
)
