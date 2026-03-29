import Foundation

enum DependencyChecker {

    // MARK: - Check all

    @MainActor
    static func checkAll(state: InstallerState) async {
        let count = state.dependencies.count
        for i in 0..<count {
            state.dependencies[i].status = .checking
            let depID = state.dependencies[i].id
            let status = await check(depID)
            state.dependencies[i].status = status
        }
        state.allDependenciesReady = state.dependencies.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
    }

    // MARK: - Check individual

    static func check(_ id: String) async -> DependencyStatus {
        switch id {
        case "xcode-clt":
            return await checkXcodeCLT()
        case "homebrew":
            return await checkHomebrew()
        case "nodejs":
            return await checkNodeJS()
        case "claude-cli":
            return await checkClaudeCLI()
        default:
            return .missing
        }
    }

    // MARK: - Install individual

    static func install(_ id: String) async -> DependencyStatus {
        switch id {
        case "xcode-clt":
            return await installXcodeCLT()
        case "homebrew":
            return await installHomebrew()
        case "nodejs":
            return await installNodeJS()
        case "claude-cli":
            return await installClaudeCLI()
        default:
            return .failed("Unknown dependency")
        }
    }

    // MARK: - Xcode CLT

    private static func checkXcodeCLT() async -> DependencyStatus {
        let result = await ShellExecutor.run("xcode-select -p")
        if result.exitCode == 0 {
            return .installed(version: "installed")
        }
        return .missing
    }

    private static func installXcodeCLT() async -> DependencyStatus {
        // xcode-select --install opens a system dialog, we trigger it and wait
        _ = await ShellExecutor.run("xcode-select --install 2>&1; sleep 1")
        // This is interactive - user needs to click Install in the system dialog
        // We poll for completion
        for _ in 0..<120 { // wait up to 10 minutes
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            let check = await ShellExecutor.run("xcode-select -p")
            if check.exitCode == 0 {
                return .installed(version: "installed")
            }
        }
        return .failed("Xcode CLT installation timed out. Please install manually.")
    }

    // MARK: - Homebrew

    private static func checkHomebrew() async -> DependencyStatus {
        let result = await ShellExecutor.run("brew --version")
        if result.exitCode == 0, let firstLine = result.output.components(separatedBy: "\n").first {
            return .installed(version: firstLine)
        }
        return .missing
    }

    private static func installHomebrew() async -> DependencyStatus {
        let result = await ShellExecutor.run(
            "NONINTERACTIVE=1 /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        )
        if result.exitCode == 0 {
            // Add brew to PATH for Apple Silicon
            _ = await ShellExecutor.run(
                "echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zprofile && eval \"$(/opt/homebrew/bin/brew shellenv)\""
            )
            return await checkHomebrew()
        }
        return .failed("Homebrew install failed: \(result.error)")
    }

    // MARK: - Node.js

    private static func checkNodeJS() async -> DependencyStatus {
        let result = await ShellExecutor.run("node --version")
        if result.exitCode == 0 {
            let version = result.output.replacingOccurrences(of: "v", with: "")
            if let major = Int(version.components(separatedBy: ".").first ?? "0"), major >= 18 {
                return .installed(version: result.output)
            }
            return .failed("Node.js version too old: \(result.output). Need >= 18.")
        }
        return .missing
    }

    private static func installNodeJS() async -> DependencyStatus {
        let result = await ShellExecutor.run("brew install node")
        if result.exitCode == 0 {
            return await checkNodeJS()
        }
        return .failed("Node.js install failed: \(result.error)")
    }

    // MARK: - Claude CLI

    private static func checkClaudeCLI() async -> DependencyStatus {
        let result = await ShellExecutor.run("claude --version")
        if result.exitCode == 0 {
            return .installed(version: result.output)
        }
        return .missing
    }

    private static func installClaudeCLI() async -> DependencyStatus {
        let result = await ShellExecutor.run("npm install -g @anthropic-ai/claude-code")
        if result.exitCode == 0 {
            return await checkClaudeCLI()
        }
        return .failed("Claude CLI install failed: \(result.error)")
    }
}
