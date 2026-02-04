// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EduGoModules",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        // MARK: - Presentation Libraries

        /// Complete UI module with all components
        .library(
            name: "EduUI",
            targets: ["EduUIProxy"]
        ),

        /// Theme system with colors, tokens, and styling
        .library(
            name: "EduTheme",
            targets: ["EduThemeProxy"]
        ),

        /// Visual effects (Liquid Glass, shadows, shapes)
        .library(
            name: "EduEffects",
            targets: ["EduEffectsProxy"]
        ),

        /// Navigation patterns (Split views, coordinators)
        .library(
            name: "EduNavigation",
            targets: ["EduNavigationProxy"]
        ),

        /// Accessibility utilities
        .library(
            name: "EduAccessibility",
            targets: ["EduAccessibilityProxy"]
        ),

        /// SwiftUI Bindings and state management utilities
        .library(
            name: "EduBinding",
            targets: ["EduBindingProxy"]
        ),

        // MARK: - Domain Libraries

        /// State management
        .library(
            name: "EduStateManagement",
            targets: ["EduStateManagementProxy"]
        ),

        // MARK: - Core Libraries

        /// Core models
        .library(
            name: "EduModels",
            targets: ["EduModelsProxy"]
        )
    ],
    dependencies: [
        // Presentation layer
        .package(path: "TIER-3-Presentation/UI"),
        .package(path: "TIER-3-Presentation/Theme"),
        .package(path: "TIER-3-Presentation/Effects"),
        .package(path: "TIER-3-Presentation/Navigation"),
        .package(path: "TIER-3-Presentation/Accessibility"),
        .package(path: "TIER-3-Presentation/Binding"),

        // Domain layer
        .package(path: "TIER-2-Domain/StateManagement"),

        // Core layer
        .package(path: "TIER-1-Core/Models")
    ],
    targets: [
        // MARK: - Proxy Targets

        .target(
            name: "EduUIProxy",
            dependencies: [
                .product(name: "UI", package: "UI")
            ],
            path: "Sources/EduUIProxy"
        ),

        .target(
            name: "EduThemeProxy",
            dependencies: [
                .product(name: "Theme", package: "Theme")
            ],
            path: "Sources/EduThemeProxy"
        ),

        .target(
            name: "EduEffectsProxy",
            dependencies: [
                .product(name: "Effects", package: "Effects")
            ],
            path: "Sources/EduEffectsProxy"
        ),

        .target(
            name: "EduNavigationProxy",
            dependencies: [
                .product(name: "Navigation", package: "Navigation")
            ],
            path: "Sources/EduNavigationProxy"
        ),

        .target(
            name: "EduAccessibilityProxy",
            dependencies: [
                .product(name: "EduAccessibility", package: "Accessibility")
            ],
            path: "Sources/EduAccessibilityProxy"
        ),

        .target(
            name: "EduBindingProxy",
            dependencies: [
                .product(name: "Binding", package: "Binding")
            ],
            path: "Sources/EduBindingProxy"
        ),

        .target(
            name: "EduStateManagementProxy",
            dependencies: [
                .product(name: "StateManagement", package: "StateManagement")
            ],
            path: "Sources/EduStateManagementProxy"
        ),

        .target(
            name: "EduModelsProxy",
            dependencies: [
                .product(name: "Models", package: "Models")
            ],
            path: "Sources/EduModelsProxy"
        )
    ]
)
