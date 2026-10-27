// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StandaloneExample",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "StandaloneExample",
            targets: ["StandaloneExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cafecito-games/SwiftGodotBinary", exact: "0.4.2"),
        .package(name: "SwiftGodotKit", path: "..")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "StandaloneExample",
            dependencies: [
                .product(name: "SwiftGodot", package: "SwiftGodotBinary"),
                .product(name: "SwiftGodotKit", package: "SwiftGodotKit"),
            ]),
        .testTarget(
            name: "StandaloneExampleTests",
            dependencies: ["StandaloneExample"]),
    ]
)
