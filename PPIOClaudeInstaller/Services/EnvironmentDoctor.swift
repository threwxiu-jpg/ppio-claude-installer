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

    static func runAll(apiKey: String, modelID: String, baseUrl: String) async -> [DiagnosticResult] {
        var results: [DiagnosticResult] = []

        // --- CRITICAL checks ---

        results.append(checkClaudeInstalled())
        results.append(contentsOf: checkShellExports(baseUrl: baseUrl))
        results.append(checkSettingsJSON())
        results.append(await checkNetwork(baseUrl: baseUrl))
        results.append(await checkAPIKey(apiKey: apiKey, modelID: modelID, baseUrl: baseUrl))

        // --- OPTIONAL checks ---

        results.append(checkOptionalEnvVar("ANTHROPIC_MODEL", pattern: "/"))
        results.append(checkOptionalEnvVar("ANTHROPIC_SMALL_FAST_MODEL", pattern: "/"))
        results.append(checkSettingsSmallModel())
        results.append(checkClaudeDirPermissions())

        return results
    }

    // MARK: - CRITICAL checks

    private static func checkClaudeInstalled() -> DiagnosticResult {
        let fm = FileManager.default
        let hasApp = fm.fileExists(atPath: "/Applications/Claude.app")

        // Check known install paths directly (GUI app PATH may not include ~/.npm-global/bin)
        let candidatePaths = [
            "\(NSHomeDirectory())/.npm-global/bin/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
        let hasCLI = candidatePaths.contains { fm.fileExists(atPath: $0) }

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

    private static func checkShellExports(baseUrl: String) -> [DiagnosticResult] {
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
            if val == baseUrl {
                results.append(DiagnosticResult(name: "ANTHROPIC_BASE_URL", level: .critical, status: .pass, message: val))
            } else {
                results.append(DiagnosticResult(name: "ANTHROPIC_BASE_URL", level: .critical, status: .fail, message: "Expected: \(baseUrl), got: \(val)"))
            }
        } else {
            results.append(DiagnosticResult(name: "ANTHROPIC_BASE_URL", level: .critical, status: .fail, message: "Not set in ~/.zshrc"))
        }

        // ANTHROPIC_AUTH_TOKEN
        if let val = extractExportValue(from: activeContent, variable: "ANTHROPIC_AUTH_TOKEN") {
            if val.count >= 10 {
                let masked = String(val.prefix(6)) + "..." + String(val.suffix(4))
                results.append(DiagnosticResult(name: "ANTHROPIC_AUTH_TOKEN", level: .critical, status: .pass, message: masked))
            } else {
                results.append(DiagnosticResult(name: "ANTHROPIC_AUTH_TOKEN", level: .critical, status: .fail, message: "Token too short"))
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

        if let model = json["model"] as? String, model.contains("/") {
            return DiagnosticResult(name: "settings.json model", level: .critical, status: .pass, message: model)
        } else {
            return DiagnosticResult(name: "settings.json model", level: .critical, status: .fail,
                                   message: "Missing or invalid model ID")
        }
    }

    private static func checkNetwork(baseUrl: String) async -> DiagnosticResult {
        guard let url = URL(string: baseUrl + "/v1/models") else {
            return DiagnosticResult(name: "Network", level: .critical, status: .fail, message: "Invalid base URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 200 {
                    return DiagnosticResult(name: "Network", level: .critical, status: .pass,
                                           message: "API reachable (\(http.statusCode))")
                } else {
                    return DiagnosticResult(name: "Network", level: .critical, status: .warn,
                                           message: "HTTP \(http.statusCode)")
                }
            }
            return DiagnosticResult(name: "Network", level: .critical, status: .fail, message: "Invalid response")
        } catch {
            return DiagnosticResult(name: "Network", level: .critical, status: .fail,
                                   message: "Cannot reach API: \(error.localizedDescription)")
        }
    }

    private static func checkAPIKey(apiKey: String, modelID: String, baseUrl: String) async -> DiagnosticResult {
        if apiKey.isEmpty {
            return DiagnosticResult(name: "API validation", level: .critical, status: .fail, message: "No API key")
        }
        let (success, error) = await PPIOValidator.validate(apiKey: apiKey, modelID: modelID, baseUrl: baseUrl)
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
                                       message: "Invalid model ID: \(val)")
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
              let val = json["smallModel"] as? String, val.contains("/") else {
            return DiagnosticResult(name: "settings.json smallModel", level: .optional, status: .warn,
                                   message: "Not set or invalid model ID")
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
