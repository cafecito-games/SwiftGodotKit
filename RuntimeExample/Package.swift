// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "RuntimeExample",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "RuntimeExample", targets: ["RuntimeExample"]),
    ],
    dependencies: [
        // Path dependency so the fixture always exercises this checkout. A
        // published consumer would use the repository URL instead.
        .package(name: "SwiftGodotKit", path: "..")
    ],
    targets: [
        .executableTarget(
            name: "RuntimeExample",
            dependencies: [
                .product(name: "SwiftGodotRuntime", package: "SwiftGodotKit"),
            ],
            resources: [
                .copy("Fixtures/HeadlessProject")
            ]
        ),
    ]
)
