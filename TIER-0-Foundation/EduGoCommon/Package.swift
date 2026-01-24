// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EduGoCommon",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "EduGoCommon",
            targets: ["EduGoCommon"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EduGoCommon",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "EduGoCommonTests",
            dependencies: ["EduGoCommon"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
