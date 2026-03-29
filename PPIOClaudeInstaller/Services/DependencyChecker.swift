import Foundation

enum DependencyChecker {

    // Ensure common tool paths are in PATH (App sandbox may not inherit shell profile)
    private static let shellPrefix = "export PATH=\"/opt/homebrew/bin:/usr/local/bin:$PATH\"; "

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

    // MARK: - Network check

    static func checkNetworkSpeed() async -> Bool {
        // Test connection to GitHub (used by Homebrew) with 5s timeout
        // Returns true if slow (>3s or failed)
        let url = URL(string: "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")!
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let elapsed = Date().timeIntervalSince(start)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return true // treat non-200 as slow
            }
            return elapsed > 3.0
        } catch {
            return true // timeout or error = slow
        }
    }

    // MARK: - Mirror config

    private static let mirrorEnv = "export HOMEBREW_BREW_GIT_REMOTE=\"https://mirrors.ustc.edu.cn/brew.git\"; export HOMEBREW_CORE_GIT_REMOTE=\"https://mirrors.ustc.edu.cn/homebrew-core.git\"; export HOMEBREW_API_DOMAIN=\"https://mirrors.ustc.edu.cn/homebrew-bottles/api\"; export HOMEBREW_BOTTLE_DOMAIN=\"https://mirrors.ustc.edu.cn/homebrew-bottles\"; "

    private static let npmMirrorCmd = "npm config set registry https://registry.npmmirror.com && "

    // MARK: - Install individual

    static func install(_ id: String, useMirror: Bool = false) async -> DependencyStatus {
        switch id {
        case "xcode-clt":
            return await installXcodeCLT()
        case "homebrew":
            return await installHomebrew(useMirror: useMirror)
        case "nodejs":
            return await installNodeJS(useMirror: useMirror)
        case "claude-cli":
            return await installClaudeCLI(useMirror: useMirror)
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
        let result = await ShellExecutor.run(shellPrefix + "brew --version")
        if result.exitCode == 0, let firstLine = result.output.components(separatedBy: "\n").first {
            return .installed(version: firstLine)
        }
        return .missing
    }

    private static func installHomebrew(useMirror: Bool = false) async -> DependencyStatus {
        let envPrefix = useMirror ? mirrorEnv : ""
        let installURL = useMirror
            ? "https://mirrors.ustc.edu.cn/misc/brew-install.sh"
            : "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
        let result = await ShellExecutor.run(
            "\(envPrefix) NONINTERACTIVE=1 /bin/bash -c \"$(curl -fsSL \(installURL))\""
        )
        if result.exitCode == 0 {
            _ = await ShellExecutor.run(
                "echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zprofile && eval \"$(/opt/homebrew/bin/brew shellenv)\""
            )
            return await checkHomebrew()
        }
        return .failed("Homebrew 安装失败: \(result.error)")
    }

    // MARK: - Node.js

    private static func checkNodeJS() async -> DependencyStatus {
        let result = await ShellExecutor.run(shellPrefix + "node --version")
        if result.exitCode == 0 {
            let version = result.output.replacingOccurrences(of: "v", with: "")
            if let major = Int(version.components(separatedBy: ".").first ?? "0"), major >= 18 {
                return .installed(version: result.output)
            }
            return .failed("Node.js version too old: \(result.output). Need >= 18.")
        }
        return .missing
    }

    private static func installNodeJS(useMirror: Bool = false) async -> DependencyStatus {
        let envPrefix = useMirror ? mirrorEnv : ""
        let result = await ShellExecutor.run(shellPrefix + envPrefix + "brew install node")
        if result.exitCode == 0 {
            return await checkNodeJS()
        }
        return .failed("Node.js 安装失败: \(result.error)")
    }

    // MARK: - Claude CLI

    private static func checkClaudeCLI() async -> DependencyStatus {
        let result = await ShellExecutor.run(shellPrefix + "claude --version")
        if result.exitCode == 0 {
            return .installed(version: result.output)
        }
        return .missing
    }

    private static func installClaudeCLI(useMirror: Bool = false) async -> DependencyStatus {
        let registryCmd = useMirror ? npmMirrorCmd : ""
        let result = await ShellExecutor.run(shellPrefix + registryCmd + "npm install -g @anthropic-ai/claude-code")
        if result.exitCode == 0 {
            return await checkClaudeCLI()
        }
        return .failed("Claude CLI 安装失败: \(result.error)")
    }
}
