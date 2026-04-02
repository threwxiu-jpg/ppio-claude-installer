import Foundation

enum CheckLevel: String {
    case critical = "CRITICAL"
    case optional = "OPTIONAL"
}

enum CheckStatus {
    case pass
    case fail
    case warn
}

struct DiagnosticResult: Identifiable {
    let id = UUID()
    let name: String
    let level: CheckLevel
    let status: CheckStatus
    let message: String
}

enum DiagnosticStatus {
    case idle
    case running
    case done
}

enum EnvironmentDoctor {

    static func runAll(apiKey: String, modelID: String) async -> [DiagnosticResult] {
        var results: [DiagnosticResult] = []

        // --- CRITICAL checks ---

        results.append(checkClaudeInstalled())
        results.append(contentsOf: checkShellExports())
        results.append(checkSettingsJSON())
        results.append(await checkNetwork())
        results.append(await checkAPIKey(apiKey: apiKey, modelID: modelID))

        // --- OPTIONAL checks ---

        results.append(checkOptionalEnvVar("ANTHROPIC_MODEL", pattern: "pa/"))
        results.append(checkOptionalEnvVar("ANTHROPIC_SMALL_FAST_MODEL", pattern: "pa/"))
        results.append(checkSettingsSmallModel())
        results.append(checkClaudeDirPermissions())

        return results
    }

    // MARK: - CRITICAL checks

    private static func checkClaudeInstalled() -> DiagnosticResult {
        let fm = FileManager.default
        let hasApp = fm.fileExists(atPath: "/Applications/Claude.app")

        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]
        process.standardOutput = pipe
        process.standardError = pipe
        let hasCLI: Bool
        do {
            try process.run()
            process.waitUntilExit()
            hasCLI = process.terminationStatus == 0
        } catch {
            hasCLI = false
        }

        if hasApp && hasCLI {
            return DiagnosticResult(name: "Claude Code", level: .critical, status: .pass,
                                   message: "App + CLI installed")
        } else if hasApp || hasCLI {
            let which = hasApp ? "App only" : "CLI only"
            return DiagnosticResult(name: "Claude Code", level: .critical, status: .pass,
                                   message: "\(which) (functional)")
        } else {
            return DiagnosticResult(name: "Claude Code", level: .critical, status: .fail,
                                   message: "Neither App nor CLI found")
        }
    }

    private static func checkShellExports() -> [DiagnosticResult] {
        var results: [DiagnosticResult] = []
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let zshrcPath = homeDir.appendingPathComponent(".zshrc")
        let content = (try? String(contentsOf: zshrcPath, encoding: .utf8)) ?? ""

        // Check for wrong variable name
        let lines = content.components(separatedBy: "\n")
        let activeLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }
        let activeContent = activeLines.joined(separator: "\n")

        if activeContent.contains("ANTHROPIC_API_KEY") {
            results.append(DiagnosticResult(
                name: "Wrong var name", level: .critical, status: .fail,
                message: "Found ANTHROPIC_API_KEY (should be ANTHROPIC_AUTH_TOKEN)"))
        }

        // ANTHROPIC_BASE_URL
        if let val = extractExportValue(from: activeContent, variable: "ANTHROPIC_BASE_URL") {
            if val.contains("api.ppio.com/anthropic") && !val.hasSuffix("/v1") {
                results.append(DiagnosticResult(name: "ANTHROPIC_BASE_URL", level: .critical, status: .pass, message: val))
            } else {
                var hint = val
                if val.hasSuffix("/v1") { hint = "Remove trailing /v1" }
                results.append(DiagnosticResult(name: "ANTHROPIC_BASE_URL", level: .critical, status: .fail, message: hint))
            }
        } else {
            results.append(DiagnosticResult(name: "ANTHROPIC_BASE_URL", level: .critical, status: .fail, message: "Not set in ~/.zshrc"))
        }

        // ANTHROPIC_AUTH_TOKEN
        if let val = extractExportValue(from: activeContent, variable: "ANTHROPIC_AUTH_TOKEN") {
            if val.hasPrefix("sk_") {
                let masked = String(val.prefix(6)) + "..." + String(val.suffix(4))
                results.append(DiagnosticResult(name: "ANTHROPIC_AUTH_TOKEN", level: .critical, status: .pass, message: masked))
            } else {
                results.append(DiagnosticResult(name: "ANTHROPIC_AUTH_TOKEN", level: .critical, status: .fail, message: "Value doesn't start with sk_"))
            }
        } else {
            results.append(DiagnosticResult(name: "ANTHROPIC_AUTH_TOKEN", level: .critical, status: .fail, message: "Not set in ~/.zshrc"))
        }

        // CLAUDE_CODE_SKIP_AUTH_LOGIN
        if let val = extractExportValue(from: activeContent, variable: "CLAUDE_CODE_SKIP_AUTH_LOGIN") {
            if val == "1" {
                results.append(DiagnosticResult(name: "SKIP_AUTH_LOGIN", level: .critical, status: .pass, message: "=1"))
            } else {
                results.append(DiagnosticResult(name: "SKIP_AUTH_LOGIN", level: .critical, status: .fail, message: "Should be 1, got: \(val)"))
            }
        } else {
            results.append(DiagnosticResult(name: "SKIP_AUTH_LOGIN", level: .critical, status: .fail, message: "Not set (will cause 'unsupported country' error)"))
        }

        return results
    }

    private static func checkSettingsJSON() -> DiagnosticResult {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let path = homeDir.appendingPathComponent(".claude/settings.json")

        guard let data = try? Data(contentsOf: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return DiagnosticResult(name: "settings.json", level: .critical, status: .fail,
                                   message: "Missing or invalid ~/.claude/settings.json")
        }

        if let model = json["model"] as? String, model.hasPrefix("pa/") {
            return DiagnosticResult(name: "settings.json model", level: .critical, status: .pass, message: model)
        } else {
            return DiagnosticResult(name: "settings.json model", level: .critical, status: .fail,
                                   message: "Missing or no pa/ prefix")
        }
    }

    private static func checkNetwork() async -> DiagnosticResult {
        let url = URL(string: "https://api.ppio.com/anthropic/v1/models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 200 {
                    return DiagnosticResult(name: "Network", level: .critical, status: .pass,
                                           message: "PPIO API reachable (\(http.statusCode))")
                } else {
                    return DiagnosticResult(name: "Network", level: .critical, status: .warn,
                                           message: "HTTP \(http.statusCode)")
                }
            }
            return DiagnosticResult(name: "Network", level: .critical, status: .fail, message: "Invalid response")
        } catch {
            return DiagnosticResult(name: "Network", level: .critical, status: .fail,
                                   message: "Cannot reach api.ppio.com: \(error.localizedDescription)")
        }
    }

    private static func checkAPIKey(apiKey: String, modelID: String) async -> DiagnosticResult {
        if apiKey.isEmpty {
            return DiagnosticResult(name: "API validation", level: .critical, status: .fail, message: "No API key")
        }
        let (success, error) = await PPIOValidator.validate(apiKey: apiKey, modelID: modelID)
        if success {
            return DiagnosticResult(name: "API validation", level: .critical, status: .pass, message: "Request succeeded")
        } else {
            return DiagnosticResult(name: "API validation", level: .critical, status: .fail,
                                   message: error ?? "Unknown error")
        }
    }

    // MARK: - OPTIONAL checks

    private static func checkOptionalEnvVar(_ variable: String, pattern: String) -> DiagnosticResult {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let zshrcPath = homeDir.appendingPathComponent(".zshrc")
        let content = (try? String(contentsOf: zshrcPath, encoding: .utf8)) ?? ""
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }
        let active = lines.joined(separator: "\n")

        if let val = extractExportValue(from: active, variable: variable) {
            if val.contains(pattern) {
                return DiagnosticResult(name: variable, level: .optional, status: .pass, message: val)
            } else {
                return DiagnosticResult(name: variable, level: .optional, status: .fail,
                                       message: "Missing \(pattern) prefix: \(val)")
            }
        } else {
            return DiagnosticResult(name: variable, level: .optional, status: .warn,
                                   message: "Not set (settings.json can substitute)")
        }
    }

    private static func checkSettingsSmallModel() -> DiagnosticResult {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let path = homeDir.appendingPathComponent(".claude/settings.json")

        guard let data = try? Data(contentsOf: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let val = json["smallModel"] as? String, val.hasPrefix("pa/") else {
            return DiagnosticResult(name: "settings.json smallModel", level: .optional, status: .warn,
                                   message: "Not set or missing pa/ prefix")
        }
        return DiagnosticResult(name: "settings.json smallModel", level: .optional, status: .pass, message: val)
    }

    private static func checkClaudeDirPermissions() -> DiagnosticResult {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let claudeDir = homeDir.appendingPathComponent(".claude")

        guard FileManager.default.fileExists(atPath: claudeDir.path) else {
            return DiagnosticResult(name: "~/.claude dir", level: .optional, status: .warn,
                                   message: "Directory doesn't exist yet")
        }

        guard FileManager.default.isWritableFile(atPath: claudeDir.path) else {
            return DiagnosticResult(name: "~/.claude dir", level: .optional, status: .fail,
                                   message: "Not writable by current user")
        }

        return DiagnosticResult(name: "~/.claude dir", level: .optional, status: .pass, message: "OK")
    }

    // MARK: - Helpers

    private static func extractExportValue(from content: String, variable: String) -> String? {
        let pattern = "export \(variable)=\"?([^\"\n]+)\"?"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }
        return String(content[range]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}
