// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Portside",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(name: "PortlessCore"),
        .executableTarget(
            name: "Portside",
            dependencies: ["PortlessCore", .product(name: "Sparkle", package: "Sparkle")],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        .testTarget(name: "PortlessCoreTests", dependencies: ["PortlessCore"]),
    ]
)
