// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Navigation",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Navigation",
            targets: ["Navigation"]
        )
    ],
    dependencies: [
        .package(path: "../../TIER-2-Domain/CQRS"),
        .package(path: "../../TIER-1-Core/Models")
    ],
    targets: [
        .target(
            name: "Navigation",
            dependencies: [
                .product(name: "CQRS", package: "CQRS"),
                .product(name: "Models", package: "Models")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "NavigationTests",
            dependencies: ["Navigation"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
