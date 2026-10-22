// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FamilyDashboardShared",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "DashboardCore", targets: ["DashboardCore"]),
        .library(name: "DashboardUI", targets: ["DashboardUI"]),
    ],
    targets: [
        .target(
            name: "DashboardCore",
            path: "Sources/DashboardCore"
        ),
        .target(
            name: "DashboardUI",
            dependencies: ["DashboardCore"],
            path: "Sources/DashboardUI"
        ),
        .testTarget(
            name: "DashboardCoreTests",
            dependencies: ["DashboardCore"],
            path: "Tests/DashboardCoreTests",
            resources: [.process("Fixtures")]
        ),
    ]
)
