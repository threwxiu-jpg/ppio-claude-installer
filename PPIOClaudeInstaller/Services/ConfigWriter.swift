import Foundation

struct ConflictingExport {
    let variable: String
    let lineNumber: Int
    let line: String
}

enum ConfigWriter {

    // Variables that conflict with our config.
    // ANTHROPIC_API_KEY: old/wrong variable name, Claude Code uses AUTH_TOKEN.
    // Others: stale values from previous manual setup.
    private static let conflictingVars = [
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_MODEL",
        "ANTHROPIC_SMALL_FAST_MODEL",
        "CLAUDE_CODE_SKIP_AUTH_LOGIN",
    ]

    private static let shellFiles = [".zshrc", ".zprofile", ".bash_profile", ".bashrc"]

    static func detectConflicts() -> [ConflictingExport] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        var conflicts: [ConflictingExport] = []

        for file in shellFiles {
            let path = homeDir.appendingPathComponent(file)
            guard let content = try? String(contentsOf: path, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("#") { continue }
                for varName in conflictingVars {
                    if trimmed.contains("export \(varName)") || trimmed.hasPrefix("\(varName)=") {
                        conflicts.append(ConflictingExport(
                            variable: varName,
                            lineNumber: index + 1,
                            line: "~/" + file
                        ))
                    }
                }
            }
        }
        return conflicts
    }

    // MARK: - Clean conflicting vars from all shell files

    private static func cleanConflictsFromAllShellFiles() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser

        for file in shellFiles {
            let path = homeDir.appendingPathComponent(file)
            guard let content = try? String(contentsOf: path, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: "\n")
            var modified = false
            var newLines: [String] = []

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("#") {
                    newLines.append(line)
                    continue
                }
                var isConflicting = false
                for varName in conflictingVars {
                    if trimmed.contains("export \(varName)") || trimmed.hasPrefix("\(varName)=") {
                        newLines.append("# [PP Installer disabled] " + line)
                        isConflicting = true
                        modified = true
                        break
                    }
                }
                if !isConflicting && trimmed.hasPrefix("unset ANTHROPIC_") {
                    newLines.append("# [PP Installer disabled] " + line)
                    modified = true
                } else if !isConflicting {
                    newLines.append(line)
                }
            }

            if modified {
                let newContent = newLines.joined(separator: "\n")
                try? newContent.write(to: path, atomically: true, encoding: .utf8)
            }
        }
    }

    // MARK: - Write config

    static func writeConfig(apiKey: String, modelID: String, baseUrl: String) async -> (success: Bool, error: String?) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let claudeDir = homeDir.appendingPathComponent(".claude")

        // Ensure ~/.claude/ exists
        do {
            try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        } catch {
            return (false, "Failed to create ~/.claude/: \(error.localizedDescription)")
        }

        // 1. Remove OAuth credentials from previous `claude /login`
        //    When ANTHROPIC_AUTH_TOKEN (from credentials.json) coexists with
        //    ANTHROPIC_API_KEY, Claude Code rejects the request with 401.
        for credFile in ["credentials.json", ".credentials.json"] {
            let credPath = claudeDir.appendingPathComponent(credFile)
            if FileManager.default.fileExists(atPath: credPath.path) {
                try? FileManager.default.removeItem(at: credPath)
            }
        }
        // Also remove any lingering OAuth token files
        for suffix in ["-local-oauth.json", "-custom-oauth.json"] {
            let oauthPath = claudeDir.appendingPathComponent("credentials\(suffix)")
            if FileManager.default.fileExists(atPath: oauthPath.path) {
                try? FileManager.default.removeItem(at: oauthPath)
            }
        }

        // 2. Clean ALL conflicting exports from all shell files
        cleanConflictsFromAllShellFiles()

        // 3. Backup and write export block to ~/.zshrc
        //    Shell exports are the primary mechanism for CLI.
        //    ANTHROPIC_AUTH_TOKEN (not API_KEY) is what Claude Code reads.
        //    CLAUDE_CODE_SKIP_AUTH_LOGIN=1 prevents "unsupported country" error.
        let zshrcPath = homeDir.appendingPathComponent(".zshrc")
        if FileManager.default.fileExists(atPath: zshrcPath.path) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let timestamp = formatter.string(from: Date())
            let zshrcBackup = homeDir.appendingPathComponent(".zshrc.backup-\(timestamp)")
            try? FileManager.default.copyItem(at: zshrcPath, to: zshrcBackup)
        }
        let exportBlock = """

        # PP Claude Code Configuration (managed by PP Installer, do not edit manually)
        export PATH="$HOME/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
        export ANTHROPIC_BASE_URL="\(baseUrl)"
        export ANTHROPIC_AUTH_TOKEN="\(apiKey)"
        export ANTHROPIC_MODEL="\(modelID)"
        export ANTHROPIC_SMALL_FAST_MODEL="\(modelID)"
        export CLAUDE_CODE_SKIP_AUTH_LOGIN=1
        """
        do {
            var existing = (try? String(contentsOf: zshrcPath, encoding: .utf8)) ?? ""
            // Remove old config block if present
            if let range = existing.range(of: "# PP Claude Code Configuration") {
                let start = existing.index(range.lowerBound, offsetBy: -1, limitedBy: existing.startIndex) ?? range.lowerBound
                var end = range.upperBound
                if let eol = existing[end...].firstIndex(of: "\n") {
                    end = existing.index(after: eol)
                }
                while end < existing.endIndex {
                    let lineEnd = existing[end...].firstIndex(of: "\n") ?? existing.endIndex
                    let line = existing[end..<lineEnd].trimmingCharacters(in: .whitespaces)
                    if line.isEmpty || (!line.hasPrefix("export ") && !line.hasPrefix("unset ") && !line.hasPrefix("#")) { break }
                    end = lineEnd < existing.endIndex ? existing.index(after: lineEnd) : existing.endIndex
                }
                existing.removeSubrange(start..<end)
            }
            existing += exportBlock
            try existing.write(to: zshrcPath, atomically: true, encoding: .utf8)
        } catch {
            return (false, "Failed to write ~/.zshrc: \(error.localizedDescription)")
        }

        // 4. Write settings.json with model config (always update)
        let settingsPath = claudeDir.appendingPathComponent("settings.json")
        do {
            var settings: [String: Any] = [:]
            if FileManager.default.fileExists(atPath: settingsPath.path),
               let data = try? Data(contentsOf: settingsPath),
               let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                settings = existing
            }
            settings["model"] = modelID
            settings["smallModel"] = modelID
            settings["skipDangerousModePermissionPrompt"] = true
            let jsonData = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: settingsPath)
        } catch {
            return (false, "Failed to write settings.json: \(error.localizedDescription)")
        }

        // 5. Clean up stale proxy artifacts from previous installer versions
        let proxyPath = claudeDir.appendingPathComponent("ppio-proxy.js")
        if FileManager.default.fileExists(atPath: proxyPath.path) {
            try? FileManager.default.removeItem(at: proxyPath)
        }
        let plistPath = homeDir.appendingPathComponent("Library/LaunchAgents/com.pp.claude-proxy.plist")
        if FileManager.default.fileExists(atPath: plistPath.path) {
            _ = await ShellExecutor.run("launchctl unload \(plistPath.path) 2>/dev/null")
            try? FileManager.default.removeItem(at: plistPath)
        }

        return (true, nil)
    }
}
