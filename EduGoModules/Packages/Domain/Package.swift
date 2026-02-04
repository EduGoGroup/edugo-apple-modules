// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduDomain",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "EduDomain", targets: ["EduDomain"])
    ],
    dependencies: [
        .package(path: "../Foundation"),
        .package(path: "../Core"),
        .package(path: "../Infrastructure")
    ],
    targets: [
        .target(
            name: "EduDomain",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core"),
                .product(name: "EduInfrastructure", package: "Infrastructure")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EduDomainTests",
            dependencies: ["EduDomain"],
            path: "Tests/DomainTests"
        )
    ]
)
