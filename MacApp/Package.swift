// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GoldDesk",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "GoldDesk", targets: ["GoldDesk"])],
    targets: [
        .executableTarget(
            name: "GoldDesk",
            path: "Sources/GoldDesk"
        )
    ]
)
