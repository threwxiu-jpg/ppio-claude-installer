import SwiftUI

struct CompletionView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("配置完成")
                    .font(.title3.weight(.medium))
                Text("Claude Code 已准备就绪")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } content: {
            if state.diagnosticStatus == .done {
                diagnosticResultsView
            } else if state.diagnosticStatus == .running {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text("正在检查环境...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                defaultContent
            }
        } actions: {
            HStack(spacing: 12) {
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                if state.diagnosticStatus == .done {
                    Button("重新检查") {
                        Task { await runDiagnostics() }
                    }
                    .buttonStyle(.bordered)
                } else if state.diagnosticStatus != .running {
                    Button("环境诊断") {
                        Task { await runDiagnostics() }
                    }
                    .buttonStyle(.bordered)
                }

                Button("打开终端") {
                    openTerminal()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Default content (before diagnostics)

    @ViewBuilder
    private var defaultContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper")
                .font(.system(size: 36, weight: .regular))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                StepItem(number: "1", text: "打开终端")
                StepItem(number: "2", text: "输入", code: "claude", suffix: "并回车")
                StepItem(number: "3", text: "开始用 AI 写代码吧！")
            }
        }
    }

    // MARK: - Diagnostic results

    @ViewBuilder
    private var diagnosticResultsView: some View {
        let criticals = state.diagnosticResults.filter { $0.level == .critical }
        let optionals = state.diagnosticResults.filter { $0.level == .optional }
        let critFail = criticals.filter { $0.status == .fail }.count
        let optFail = optionals.filter { $0.status == .fail || $0.status == .warn }.count

        VStack(spacing: 16) {
            // Summary
            if critFail == 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("核心配置正常")
                        .font(.subheadline.weight(.medium))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("\(critFail) 个必须项需修复")
                        .font(.subheadline.weight(.medium))
                }
            }

            // Results list
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if !criticals.isEmpty {
                        Text("必须")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                        ForEach(criticals) { item in
                            DiagnosticRow(item: item)
                        }
                    }
                    if !optionals.isEmpty {
                        Text("可选")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        ForEach(optionals) { item in
                            DiagnosticRow(item: item)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
        }
    }

    // MARK: - Actions

    private func runDiagnostics() async {
        state.diagnosticStatus = .running
        state.diagnosticResults = await EnvironmentDoctor.runAll(
            apiKey: state.apiKey,
            modelID: state.effectiveModelID
        )
        state.diagnosticStatus = .done
    }

    private func openTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script "source ~/.zshrc && claude"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}

// MARK: - Diagnostic row component

private struct DiagnosticRow: View {
    let item: DiagnosticResult

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
                .frame(width: 14)
            Text(item.name)
                .font(.system(.caption, design: .monospaced))
                .frame(width: 140, alignment: .leading)
            Text(item.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    private var iconName: String {
        switch item.status {
        case .pass: return "checkmark.circle.fill"
        case .fail: return "xmark.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch item.status {
        case .pass: return .green
        case .fail: return .red
        case .warn: return .yellow
        }
    }
}

private struct StepItem: View {
    let number: String
    let text: String
    var code: String? = nil
    var suffix: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text("\(number).")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 18, alignment: .trailing)
            Text(text)
                .font(.subheadline)
            if let code = code {
                Text(code)
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.08)))
            }
            if let suffix = suffix {
                Text(suffix)
                    .font(.subheadline)
            }
        }
    }
}
