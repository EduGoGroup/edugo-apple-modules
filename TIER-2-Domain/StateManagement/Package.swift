// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StateManagement",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "StateManagement",
            targets: ["StateManagement"]
        )
    ],
    dependencies: [
        .package(path: "../../TIER-0-Foundation/EduGoCommon")
    ],
    targets: [
        .target(
            name: "StateManagement",
            dependencies: [
                .product(name: "EduGoCommon", package: "EduGoCommon")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "StateManagementTests",
            dependencies: ["StateManagement"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
