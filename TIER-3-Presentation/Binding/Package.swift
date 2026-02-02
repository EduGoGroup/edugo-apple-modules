// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Binding",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Binding",
            targets: ["Binding"]
        )
    ],
    dependencies: [
        .package(path: "../Theme")
    ],
    targets: [
        .target(
            name: "Binding",
            dependencies: [
                .product(name: "Theme", package: "Theme")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "BindingTests",
            dependencies: ["Binding"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
