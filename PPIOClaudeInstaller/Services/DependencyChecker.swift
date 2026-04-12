import Foundation

enum DependencyChecker {

    // Ensure common tool paths are in PATH (App sandbox may not inherit shell profile)
    private static let shellPrefix = "export PATH=\"$HOME/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:$PATH\"; "

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
        // Homebrew is optional if Node.js and Claude CLI are already installed
        let essentialReady = state.dependencies.filter { $0.id != "homebrew" }.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
        let allInstalled = state.dependencies.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
        state.allDependenciesReady = allInstalled || essentialReady
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

    // MARK: - Injectables (can be overridden in tests)

    /// Opens a Terminal window and runs the script at the given file path.
    nonisolated(unsafe) static var terminalLauncher: (String) async -> Void = { scriptPath in
        // Pass only a simple file path — avoids quoting/escaping issues in osascript
        _ = await ShellExecutor.run(
            "osascript " +
            "-e 'tell application \"Terminal\" to activate' " +
            "-e 'tell application \"Terminal\" to do script \"bash \(scriptPath)\"' " +
            "-e 'delay 0.5' " +
            "-e 'tell application \"Terminal\" to activate'"
        )
    }

    /// Nanoseconds between each brew-install poll. Set to 0 in tests.
    nonisolated(unsafe) static var pollInterval: UInt64 = 2_000_000_000  // 2 seconds

    /// Number of poll attempts before giving up. Set to small value in tests.
    nonisolated(unsafe) static var homebrewPollCount: Int = 120  // 10 minutes

    /// Checker called inside the poll loop. Defaults to the real brew check; override in tests.
    nonisolated(unsafe) static var homebrewChecker: () async -> DependencyStatus = { await checkHomebrew() }

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

    static func checkHomebrew() async -> DependencyStatus {
        // Check known brew locations directly (avoids PATH lookup failures)
        // Treat file existence as sufficient — freshly installed brew (especially via USTC
        // mirror) may exit non-zero on `--version` due to git config errors, but the
        // binary is usable for installing packages.
        let candidates = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        for path in candidates {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let result = await ShellExecutor.run("\(path) --version")
            let version = result.output.components(separatedBy: "\n").first ?? ""
            return .installed(version: version.isEmpty ? "installed" : version)
        }
        // Fallback: try via PATH
        let result = await ShellExecutor.run(shellPrefix + "brew --version")
        if result.exitCode == 0 {
            let version = result.output.components(separatedBy: "\n").first ?? ""
            return .installed(version: version.isEmpty ? "installed" : version)
        }
        return .missing
    }

    private static func installHomebrew(useMirror: Bool = false) async -> DependencyStatus {
        let envPrefix = useMirror ? mirrorEnv : ""
        let installURL = useMirror
            ? "https://mirrors.ustc.edu.cn/misc/brew-install.sh"
            : "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

        // Write install script to a temp file — avoids quoting issues when passing to osascript.
        // Homebrew refuses root AND needs sudo internally, so we run in Terminal.app.
        let scriptPath = "/tmp/ppio_brew_install.sh"
        // For the USTC mirror, the install script calls `git remote set-head origin --auto`
        // which fails because the mirror server does not expose the git symref protocol.
        // Fix: download the script, patch every `"--auto"` in a set-head call to `"main"`,
        // then run the patched version. For the official GitHub script this is a no-op safe change.
        let script = """
        #!/bin/bash
        git config --global init.defaultBranch main 2>/dev/null || true

        _RAW=/tmp/ppio_brew_raw.sh
        _PATCHED=/tmp/ppio_brew_patched.sh
        if curl -fsSL "\(installURL)" -o "$_RAW"; then
            sed 's/set-head" "origin" "--auto"/set-head" "origin" "main"/g' "$_RAW" > "$_PATCHED"
            chmod +x "$_PATCHED"
            \(envPrefix)bash "$_PATCHED"
        else
            echo "[✗ 无法下载 Homebrew 安装脚本，请检查网络]"
            exec bash
            exit 1
        fi

        echo ""
        if [ -f /opt/homebrew/bin/brew ] || [ -f /usr/local/bin/brew ]; then
            echo "[✓ Homebrew 安装完成，可关闭此窗口]"
        else
            echo "[✗ Homebrew 安装失败，请查看上方错误后重试]"
        fi
        exec bash
        """
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        _ = await ShellExecutor.run("chmod +x '\(scriptPath)'")
        await terminalLauncher(scriptPath)

        // Poll for completion
        for _ in 0..<homebrewPollCount {
            if pollInterval > 0 { try? await Task.sleep(nanoseconds: pollInterval) }
            let check = await homebrewChecker()
            if case .installed = check {
                _ = await ShellExecutor.run(
                    "echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zprofile && eval \"$(/opt/homebrew/bin/brew shellenv)\""
                )
                return check
            }
        }
        return .failed("Homebrew 安装超时，请在终端手动运行安装命令")
    }

    // MARK: - Node.js

    private static func checkNodeJS() async -> DependencyStatus {
        // Check known node paths directly first (same strategy as checkHomebrew)
        let candidates = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
        ]
        for path in candidates {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let result = await ShellExecutor.run("\(path) --version")
            if result.exitCode == 0 {
                let v = result.output.replacingOccurrences(of: "v", with: "")
                if let major = Int(v.components(separatedBy: ".").first ?? "0"), major >= 18 {
                    return .installed(version: result.output)
                }
                // Found but too old — keep checking other paths
            }
        }
        // Fallback: try via PATH
        let result = await ShellExecutor.run(shellPrefix + "node --version")
        if result.exitCode == 0 {
            let v = result.output.replacingOccurrences(of: "v", with: "")
            if let major = Int(v.components(separatedBy: ".").first ?? "0"), major >= 18 {
                return .installed(version: result.output)
            }
            return .failed("Node.js 版本过低: \(result.output)，需要 >= 18")
        }
        return .missing
    }

    private static func installNodeJS(useMirror: Bool = false) async -> DependencyStatus {
        // Verify Homebrew is available first
        let brewCheck = await checkHomebrew()
        guard case .installed = brewCheck else {
            return .failed("请先安装 Homebrew，再安装 Node.js")
        }

        let envPrefix = useMirror ? mirrorEnv : ""
        // Use `brew upgrade node || brew install node` to handle both fresh and old installs
        let result = await ShellExecutor.run(
            shellPrefix + envPrefix + "(brew upgrade node 2>/dev/null || brew install node)"
        )
        if result.exitCode == 0 {
            return await checkNodeJS()
        }
        return .failed("Node.js 安装失败: \(result.error)")
    }

    // MARK: - Claude CLI

    private static func checkClaudeCLI() async -> DependencyStatus {
        let candidates = [
            "\(NSHomeDirectory())/.npm-global/bin/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
        for path in candidates {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let result = await ShellExecutor.run("\(path) --version")
            if result.exitCode == 0 {
                return .installed(version: result.output)
            }
        }
        // Fallback: try via PATH
        let result = await ShellExecutor.run(shellPrefix + "claude --version")
        if result.exitCode == 0 {
            return .installed(version: result.output)
        }
        return .missing
    }

    private static func installClaudeCLI(useMirror: Bool = false) async -> DependencyStatus {
        let registryCmd = useMirror ? npmMirrorCmd : ""
        // First try without sudo
        let result = await ShellExecutor.run(shellPrefix + registryCmd + "npm install -g @anthropic-ai/claude-code")
        if result.exitCode == 0 {
            return await checkClaudeCLI()
        }
        // EACCES error — fix npm prefix permissions, then retry
        if result.error.contains("EACCES") {
            // Create user-owned npm global directory to avoid sudo
            let fixPerms = await ShellExecutor.run(
                "mkdir -p ~/.npm-global && npm config set prefix '~/.npm-global' && " +
                "export PATH=~/.npm-global/bin:$PATH && " +
                shellPrefix + registryCmd + "npm install -g @anthropic-ai/claude-code"
            )
            if fixPerms.exitCode == 0 {
                // Add to shell profile so claude is found later
                _ = await ShellExecutor.run(
                    "echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zprofile"
                )
                return await checkClaudeCLI()
            }
            // Last resort: sudo via temp script to avoid osascript escaping issues
            let sudoScript = "/tmp/ppio_npm_sudo.sh"
            let sudoContent = "#!/bin/bash\n" + shellPrefix + registryCmd + "npm install -g @anthropic-ai/claude-code\n"
            try? sudoContent.write(toFile: sudoScript, atomically: true, encoding: .utf8)
            _ = await ShellExecutor.run("chmod +x '\(sudoScript)'")
            let sudoResult = await ShellExecutor.run(
                "osascript -e 'do shell script \"bash \(sudoScript)\" with administrator privileges'"
            )
            if sudoResult.exitCode == 0 {
                return await checkClaudeCLI()
            }
        }
        return .failed("Claude CLI 安装失败: \(result.error)")
    }
}
