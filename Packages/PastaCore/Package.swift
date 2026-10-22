// swift-tools-version: 6.2
import PackageDescription

let concurrency: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]

let package = Package(
    name: "PastaCore",
    platforms: [.macOS("27.0")],
    products: [.library(name: "PastaCore", targets: ["PastaCore"])],
    targets: [
        .target(name: "PastaCore", swiftSettings: concurrency)
    ]
)
