// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Roles",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Roles",
            targets: ["Roles"]
        )
    ],
    dependencies: [
        .package(path: "../../TIER-0-Foundation/EduGoCommon"),
        .package(path: "../../TIER-1-Core/Logger"),
        .package(path: "../../TIER-1-Core/Models"),
        .package(path: "../../TIER-2-Infrastructure/Storage")
    ],
    targets: [
        .target(
            name: "Roles",
            dependencies: [
                .product(name: "EduGoCommon", package: "EduGoCommon"),
                .product(name: "Logger", package: "Logger"),
                .product(name: "Models", package: "Models"),
                .product(name: "Storage", package: "Storage")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete"),
                .enableUpcomingFeature("InferSendableFromCaptures"),
                .enableUpcomingFeature("RegionBasedIsolation")
            ]
        ),
        .testTarget(
            name: "RolesTests",
            dependencies: ["Roles"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete"),
                .enableUpcomingFeature("InferSendableFromCaptures"),
                .enableUpcomingFeature("RegionBasedIsolation")
            ]
        )
    ]
)
