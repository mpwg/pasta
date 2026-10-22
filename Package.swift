// swift-tools-version: 6.2
import PackageDescription

let concurrency: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]

let package = Package(
    name: "Pasta",
    defaultLocalization: "de",
    platforms: [.macOS("27.0")],
    products: [
        .executable(name: "Pasta", targets: ["Pasta"]),
        .executable(name: "PastaProbe", targets: ["PastaProbe"])
    ],
    dependencies: [
        .package(path: "Packages/PastaCore"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "3.1.0")
    ],
    targets: [
        .executableTarget(
            name: "Pasta",
            dependencies: [
                .product(name: "PastaCore", package: "PastaCore"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            swiftSettings: concurrency
        ),
        .executableTarget(
            name: "PastaProbe",
            dependencies: [.product(name: "PastaCore", package: "PastaCore")],
            swiftSettings: concurrency
        )
    ]
)
