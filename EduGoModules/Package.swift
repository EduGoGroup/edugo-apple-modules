// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduGoModules",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        // Exponer todos los modulos como bibliotecas
        .library(name: "EduFoundation", targets: ["EduFoundationProxy"]),
        .library(name: "EduCore", targets: ["EduCoreProxy"]),
        .library(name: "EduInfrastructure", targets: ["EduInfrastructureProxy"]),
        .library(name: "EduDomain", targets: ["EduDomainProxy"]),
        .library(name: "EduPresentation", targets: ["EduPresentationProxy"]),
        .library(name: "EduFeatures", targets: ["EduFeaturesProxy"]),
        // Umbrella para importar todo
        .library(name: "EduGoModules", targets: ["EduGoModulesUmbrella"])
    ],
    dependencies: [
        .package(path: "Packages/Foundation"),
        .package(path: "Packages/Core"),
        .package(path: "Packages/Infrastructure"),
        .package(path: "Packages/Domain"),
        .package(path: "Packages/Presentation"),
        .package(path: "Packages/Features")
    ],
    targets: [
        // Proxy targets para reexportar
        .target(
            name: "EduFoundationProxy",
            dependencies: [.product(name: "EduFoundation", package: "Foundation")]
        ),
        .target(
            name: "EduCoreProxy",
            dependencies: [.product(name: "EduCore", package: "Core")]
        ),
        .target(
            name: "EduInfrastructureProxy",
            dependencies: [.product(name: "EduInfrastructure", package: "Infrastructure")]
        ),
        .target(
            name: "EduDomainProxy",
            dependencies: [.product(name: "EduDomain", package: "Domain")]
        ),
        .target(
            name: "EduPresentationProxy",
            dependencies: [.product(name: "EduPresentation", package: "Presentation")]
        ),
        .target(
            name: "EduFeaturesProxy",
            dependencies: [.product(name: "EduFeatures", package: "Features")]
        ),
        // Umbrella target
        .target(
            name: "EduGoModulesUmbrella",
            dependencies: [
                "EduFoundationProxy",
                "EduCoreProxy",
                "EduInfrastructureProxy",
                "EduDomainProxy",
                "EduPresentationProxy",
                "EduFeaturesProxy"
            ]
        )
    ]
)
