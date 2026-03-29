import Testing
@testable import PPIOClaudeInstaller

@Suite("AppVersion Tests")
struct AppVersionTests {

    @Test func versionIsNotEmpty() {
        #expect(!AppVersion.current.isEmpty)
    }

    @Test func versionFollowsSemVer() {
        let parts = AppVersion.current.split(separator: ".")
        #expect(parts.count == 3, "Version should be MAJOR.MINOR.PATCH")
        for part in parts {
            #expect(Int(part) != nil, "Each version component should be a number, got '\(part)'")
        }
    }
}
