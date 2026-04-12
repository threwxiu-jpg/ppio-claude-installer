import Testing
@testable import PPIOClaudeInstaller

@Suite("DependencyChecker Tests")
struct DependencyCheckerTests {

    private func withFastDefaults(
        checker: @escaping () async -> DependencyStatus = { .missing },
        _ body: () async -> Void
    ) async {
        let origInterval = DependencyChecker.pollInterval
        let origPollCount = DependencyChecker.homebrewPollCount
        let origLauncher = DependencyChecker.terminalLauncher
        let origChecker = DependencyChecker.homebrewChecker

        DependencyChecker.pollInterval = 0
        DependencyChecker.homebrewPollCount = 3
        DependencyChecker.terminalLauncher = { _ in }
        DependencyChecker.homebrewChecker = checker
        await body()

        DependencyChecker.pollInterval = origInterval
        DependencyChecker.homebrewPollCount = origPollCount
        DependencyChecker.terminalLauncher = origLauncher
        DependencyChecker.homebrewChecker = origChecker
    }

    // MARK: - Command construction

    @Test("install command does not contain NONINTERACTIVE=1")
    func noNonInteractiveFlag() async {
        var capturedPath = ""
        await withFastDefaults {
            DependencyChecker.terminalLauncher = { path in capturedPath = path }
            _ = await DependencyChecker.install("homebrew")
        }
        let content = (try? String(contentsOfFile: capturedPath, encoding: .utf8)) ?? ""
        #expect(!content.contains("NONINTERACTIVE"))
    }

    @Test("install without mirror uses GitHub URL")
    func commandUsesGithubURL() async {
        var capturedPath = ""
        await withFastDefaults {
            DependencyChecker.terminalLauncher = { path in capturedPath = path }
            _ = await DependencyChecker.install("homebrew", useMirror: false)
        }
        let content = (try? String(contentsOfFile: capturedPath, encoding: .utf8)) ?? ""
        #expect(content.contains("raw.githubusercontent.com/Homebrew"))
    }

    @Test("install with mirror uses USTC URL")
    func commandUsesMirrorURL() async {
        var capturedPath = ""
        await withFastDefaults {
            DependencyChecker.terminalLauncher = { path in capturedPath = path }
            _ = await DependencyChecker.install("homebrew", useMirror: true)
        }
        let content = (try? String(contentsOfFile: capturedPath, encoding: .utf8)) ?? ""
        #expect(content.contains("mirrors.ustc.edu.cn"))
    }

    // MARK: - Poll success path

    @Test("returns .installed when checker succeeds on first poll")
    func successOnFirstPoll() async {
        var result: DependencyStatus = .missing
        await withFastDefaults(checker: { .installed(version: "Homebrew 4.0.0") }) {
            result = await DependencyChecker.install("homebrew")
        }
        if case .installed(let version) = result {
            #expect(version == "Homebrew 4.0.0")
        } else {
            Issue.record("Expected .installed but got \(result)")
        }
    }

    @Test("returns .installed after 3rd poll, stops polling early")
    func successOnThirdPoll() async {
        var callCount = 0
        var result: DependencyStatus = .missing
        await withFastDefaults(checker: {
            callCount += 1
            return callCount >= 3 ? .installed(version: "Homebrew 4.0.0") : .missing
        }) {
            DependencyChecker.homebrewPollCount = 60
            result = await DependencyChecker.install("homebrew")
        }
        if case .installed = result {
            #expect(callCount == 3)
        } else {
            Issue.record("Expected .installed but got \(result)")
        }
    }

    // MARK: - Timeout path

    @Test("returns .failed with timeout message after exhausting poll count")
    func timeoutAfterPollCount() async {
        var result: DependencyStatus = .missing
        await withFastDefaults {
            // homebrewPollCount = 3, checker always returns .missing
            result = await DependencyChecker.install("homebrew")
        }
        if case .failed(let msg) = result {
            #expect(msg.contains("超时"))
        } else {
            Issue.record("Expected .failed but got \(result)")
        }
    }
}
