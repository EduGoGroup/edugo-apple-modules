// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UseCases",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "UseCases",
            targets: ["UseCases"]
        )
    ],
    dependencies: [
        .package(path: "../../TIER-0-Foundation/EduGoCommon"),
        .package(path: "../../TIER-1-Core/Models")
    ],
    targets: [
        .target(
            name: "UseCases",
            dependencies: [
                .product(name: "EduGoCommon", package: "EduGoCommon"),
                .product(name: "Models", package: "Models")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "UseCasesTests",
            dependencies: ["UseCases"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
