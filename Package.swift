// swift-tools-version: 5.10
import PackageDescription

let featureFlags: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency=complete"),
    .enableUpcomingFeature("StrictConcurrency=complete"),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "vapor-elementary",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "VaporElementary",
            targets: ["VaporElementary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.102.0"),
        .package(url: "https://github.com/sliemeobn/elementary.git", .upToNextMajor(from: "0.3.0")),
    ],
    targets: [
        .target(
            name: "VaporElementary",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Elementary", package: "elementary"),
            ],
            swiftSettings: featureFlags
        ),
        .testTarget(
            name: "VaporElementaryTests",
            dependencies: [
                .target(name: "VaporElementary"),
                .product(name: "Elementary", package: "elementary"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: featureFlags
        ),
    ]
)
