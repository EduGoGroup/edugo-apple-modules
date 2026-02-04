// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "EduCore", targets: ["EduCore"])
    ],
    dependencies: [
        .package(path: "../Foundation")
    ],
    targets: [
        .target(
            name: "EduCore",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EduCoreTests",
            dependencies: ["EduCore"],
            path: "Tests/CoreTests"
        )
    ]
)
