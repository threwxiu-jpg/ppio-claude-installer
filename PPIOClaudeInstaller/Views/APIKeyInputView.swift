import SwiftUI

struct APIKeyInputView: View {
    @EnvironmentObject var state: InstallerState
    @FocusState private var isFocused: Bool

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("PP API Key")
                    .font(.title3.weight(.medium))
                Text("输入你的 API Key 以连接 Claude Code")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } content: {
            VStack(spacing: 16) {
                SecureField("sk_...", text: $state.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($isFocused)

                if !state.apiKey.isEmpty && !state.isAPIKeyFormatValid {
                    Text("API Key 需以 \"sk_\" 开头，且长度不少于 20 位")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }

                Text("可在 PP 控制台获取 API Key")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.6))
            }
        } actions: {
            HStack(spacing: 16) {
                Button("上一步") { state.goBack() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                Button("继续") { state.goNext() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!state.isAPIKeyFormatValid)
            }
        }
        .onAppear { isFocused = true }
    }
}
