// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PPIOClaudeInstaller",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "PPIOClaudeInstaller",
            path: "PPIOClaudeInstaller",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
