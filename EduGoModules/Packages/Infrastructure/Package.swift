// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduInfrastructure",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "EduInfrastructure", targets: ["EduInfrastructure"])
    ],
    dependencies: [
        .package(path: "../Foundation"),
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "EduInfrastructure",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EduInfrastructureTests",
            dependencies: ["EduInfrastructure"],
            path: "Tests/InfrastructureTests"
        )
    ]
)
