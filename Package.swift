// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PPIOClaudeInstaller",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PPIOClaudeInstaller",
            path: "PPIOClaudeInstaller",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "PPIOClaudeInstallerTests",
            dependencies: ["PPIOClaudeInstaller"],
            path: "Tests",
            swiftSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-framework", "Testing"
                ])
            ]
        )
    ]
)
