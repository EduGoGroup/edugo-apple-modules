// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Effects",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Effects",
            targets: ["Effects"]
        )
    ],
    dependencies: [
        .package(path: "../Theme")
    ],
    targets: [
        .target(
            name: "Effects",
            dependencies: [
                .product(name: "Theme", package: "Theme")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "EffectsTests",
            dependencies: ["Effects"]
        )
    ]
)
