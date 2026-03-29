import Foundation

enum ConfigWriter {
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
