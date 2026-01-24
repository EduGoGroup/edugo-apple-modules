// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AI",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "AI",
            targets: ["AI"]
        )
    ],
    dependencies: [
        .package(path: "../TIER-0-Foundation/EduGoCommon"),
        .package(path: "../TIER-1-Core/Logger"),
        .package(path: "../TIER-1-Core/Models"),
        .package(path: "../TIER-2-Infrastructure/Network"),
        .package(path: "../TIER-3-Domain/Auth")
    ],
    targets: [
        .target(
            name: "AI",
            dependencies: [
                .product(name: "EduGoCommon", package: "EduGoCommon"),
                .product(name: "Logger", package: "Logger"),
                .product(name: "Models", package: "Models"),
                .product(name: "Network", package: "Network"),
                .product(name: "Auth", package: "Auth")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "AITests",
            dependencies: ["AI"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
