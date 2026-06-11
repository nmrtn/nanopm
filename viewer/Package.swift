// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NanoPMViewer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "NanoPMViewer",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: "Sources/NanoPMViewer",
            resources: [
                .copy("Resources/PhaseIcons"),
                .copy("Resources/mascot.png"),
            ]
        ),
    ]
)
