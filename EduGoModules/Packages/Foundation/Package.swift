// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduFoundation",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "EduFoundation", targets: ["EduFoundation"])
    ],
    targets: [
        .target(
            name: "EduFoundation",
            path: "Sources/EduFoundation"
        ),
        .testTarget(
            name: "EduFoundationTests",
            dependencies: ["EduFoundation"],
            path: "Tests/EduFoundationTests"
        )
    ]
)
