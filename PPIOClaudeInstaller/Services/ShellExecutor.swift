import Foundation

struct ShellResult {
    let exitCode: Int32
    let output: String
    let error: String
}

enum ShellExecutor {
    static func run(_ command: String, environment: [String: String]? = nil) async -> ShellResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let outputPipe = Pipe()
                let errorPipe = Pipe()

                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-l", "-c", command]
                process.standardOutput = outputPipe
                process.standardError = errorPipe

                if let env = environment {
                    var processEnv = ProcessInfo.processInfo.environment
                    for (key, value) in env {
                        processEnv[key] = value
                    }
                    process.environment = processEnv
                }

                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    continuation.resume(returning: ShellResult(
                        exitCode: -1,
                        output: "",
                        error: error.localizedDescription
                    ))
                    return
                }

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                continuation.resume(returning: ShellResult(
                    exitCode: process.terminationStatus,
                    output: String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    error: String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                ))
            }
        }
    }
}
