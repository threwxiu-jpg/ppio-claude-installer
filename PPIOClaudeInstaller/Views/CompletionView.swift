import SwiftUI

struct CompletionView: View {
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
        } actions: {
            HStack(spacing: 16) {
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button("打开终端") {
                    openTerminal()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func openTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script ""
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
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
