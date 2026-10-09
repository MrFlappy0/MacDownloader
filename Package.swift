// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacDownloader",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "macdownloader", targets: ["MacDownloaderCLI"]),
        .library(name: "MacDownloaderCore", targets: ["MacDownloaderCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "MacDownloaderCore",
            dependencies: [
                "Alamofire",
                "SwiftSoup",
            ],
            path: "Sources/MacDownloaderCore",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "MacDownloaderCLI",
            dependencies: ["MacDownloaderCore"],
            path: "Sources/MacDownloaderCLI"
        ),
        .target(
            name: "MacDownloaderApp",
            dependencies: ["MacDownloaderCore"],
            path: "Sources/MacDownloaderApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MacDownloaderCoreTests",
            dependencies: ["MacDownloaderCore"],
            path: "Tests/MacDownloaderCoreTests"
        ),
    ]
)
