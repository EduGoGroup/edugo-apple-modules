// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Storage",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Storage",
            targets: ["Storage"]
        )
    ],
    dependencies: [
        .package(path: "../TIER-0-Foundation/EduGoCommon"),
        .package(path: "../TIER-1-Core/Logger"),
        .package(path: "../TIER-1-Core/Models")
    ],
    targets: [
        .target(
            name: "Storage",
            dependencies: [
                .product(name: "EduGoCommon", package: "EduGoCommon"),
                .product(name: "Logger", package: "Logger"),
                .product(name: "Models", package: "Models")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "StorageTests",
            dependencies: ["Storage"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
