// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

//
//  Package.swift
//  EduAccessibility
//
//  Accessibility package providing comprehensive support for:
//  - Dynamic Type with adaptive scaling
//  - Keyboard navigation and focus management
//  - VoiceOver integration and accessibility traits
//  - Reduced Motion and High Contrast preferences
//  - Adaptive layouts for accessibility sizes
//
//  Swift 6.2 strict concurrency compliant
//

import PackageDescription

let package = Package(
    name: "EduAccessibility",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "EduAccessibility",
            targets: ["EduAccessibility"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EduAccessibility",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        ),
        .testTarget(
            name: "EduAccessibilityTests",
            dependencies: ["EduAccessibility"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
