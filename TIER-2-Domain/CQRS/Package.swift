// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CQRS",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "CQRS",
            targets: ["CQRS"]
        )
    ],
    dependencies: [
        .package(path: "../../TIER-0-Foundation/EduGoCommon"),
        .package(path: "../../TIER-1-Core/Models"),
        .package(path: "../UseCases")
    ],
    targets: [
        .target(
            name: "CQRS",
            dependencies: [
                .product(name: "EduGoCommon", package: "EduGoCommon"),
                .product(name: "Models", package: "Models"),
                .product(name: "UseCases", package: "UseCases")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "CQRSTests",
            dependencies: ["CQRS"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
