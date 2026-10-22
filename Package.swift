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
    products: [.executable(name: "PastaProbe", targets: ["PastaProbe"])],
    targets: [
        .target(name: "PastaCore", swiftSettings: concurrency),
        .executableTarget(name: "PastaProbe", dependencies: ["PastaCore"], swiftSettings: concurrency),
        .testTarget(name: "PastaCoreTests", dependencies: ["PastaCore"], swiftSettings: concurrency)
    ]
)
