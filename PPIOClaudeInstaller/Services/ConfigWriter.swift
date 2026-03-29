import Foundation

struct ConflictingExport {
    let variable: String
    let lineNumber: Int
    let line: String
}

enum ConfigWriter {

    private static let conflictingVars = [
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_MODEL",
        "ANTHROPIC_SMALL_FAST_MODEL",
        "CLAUDE_CODE_SKIP_AUTH_LOGIN",
    ]

    static func detectConflicts() -> [ConflictingExport] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let shellFiles = [".zshrc", ".zprofile", ".bash_profile", ".bashrc"]
        var conflicts: [ConflictingExport] = []

        for file in shellFiles {
            let path = homeDir.appendingPathComponent(file)
            guard let content = try? String(contentsOf: path, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                // Skip comments
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

    static func writeConfig(apiKey: String, modelID: String) async -> (success: Bool, error: String?) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let claudeDir = homeDir.appendingPathComponent(".claude")

        // Ensure ~/.claude/ exists
        do {
            try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        } catch {
            return (false, "Failed to create ~/.claude/: \(error.localizedDescription)")
        }

        // Write .env
        let envContent = """
        ANTHROPIC_BASE_URL=https://api.ppio.com/anthropic
        ANTHROPIC_API_KEY=\(apiKey)
        ANTHROPIC_MODEL=\(modelID)
        ANTHROPIC_SMALL_FAST_MODEL=\(modelID)
        CLAUDE_CODE_SKIP_AUTH_LOGIN=1
        """

        let envPath = claudeDir.appendingPathComponent(".env")
        // Backup existing .env before overwriting
        if FileManager.default.fileExists(atPath: envPath.path) {
            let backupPath = claudeDir.appendingPathComponent(".env.backup")
            try? FileManager.default.removeItem(at: backupPath)
            try? FileManager.default.copyItem(at: envPath, to: backupPath)
        }
        do {
            try envContent.write(to: envPath, atomically: true, encoding: .utf8)
        } catch {
            return (false, "Failed to write ~/.claude/.env: \(error.localizedDescription)")
        }

        // Write settings.json (only if it doesn't exist, to avoid overwriting user config)
        let settingsPath = claudeDir.appendingPathComponent("settings.json")
        if !FileManager.default.fileExists(atPath: settingsPath.path) {
            let settingsContent = """
            {
              "skipDangerousModePermissionPrompt": true
            }
            """
            do {
                try settingsContent.write(to: settingsPath, atomically: true, encoding: .utf8)
            } catch {
                return (false, "Failed to write settings.json: \(error.localizedDescription)")
            }
        }

        return (true, nil)
    }
}
