// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ViewModels",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ViewModels",
            targets: ["ViewModels"]
        )
    ],
    dependencies: [
        .package(path: "../../TIER-0-Foundation/EduGoCommon"),
        .package(path: "../../TIER-1-Core/Models"),
        .package(path: "../../TIER-2-Domain/CQRS"),
        .package(path: "../../TIER-2-Domain/UseCases"),
        .package(path: "../../TIER-3-Domain/Roles"),
        .package(path: "../../TIER-2-Infrastructure/LocalPersistence"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ViewModels",
            dependencies: [
                .product(name: "EduGoCommon", package: "EduGoCommon"),
                .product(name: "Models", package: "Models"),
                .product(name: "CQRS", package: "CQRS"),
                .product(name: "UseCases", package: "UseCases"),
                .product(name: "Roles", package: "Roles"),
                .product(name: "LocalPersistence", package: "LocalPersistence")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "ViewModelsTests",
            dependencies: ["ViewModels"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
