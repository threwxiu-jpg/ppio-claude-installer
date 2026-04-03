import SwiftUI

struct APIKeyInputView: View {
    @EnvironmentObject var state: InstallerState
    @FocusState private var isFocused: Bool

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("API 配置")
                    .font(.title3.weight(.medium))
                Text("选择服务端点并输入 API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } content: {
            VStack(spacing: 16) {
                // URL Mode Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("服务端点")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(UrlMode.allCases, id: \.self) { mode in
                            Button(mode.label) {
                                state.urlMode = mode
                                if let preset = mode.presetUrl {
                                    state.baseUrl = preset
                                } else {
                                    state.baseUrl = ""
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .fontWeight(state.urlMode == mode ? .medium : .regular)
                            .foregroundColor(state.urlMode == mode ? .accentColor : .secondary)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(state.urlMode == mode ? Color.accentColor.opacity(0.08) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(state.urlMode == mode ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 0.5)
                            )
                        }
                    }

                    if state.urlMode != .custom {
                        Text(state.baseUrl)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.6))
                    }

                    if state.urlMode == .custom {
                        TextField("https://your-proxy.example.com", text: $state.baseUrl)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                    }
                }

                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SecureField(state.urlMode == .ppio ? "sk_..." : "your-api-key", text: $state.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .focused($isFocused)

                    if !state.apiKey.isEmpty && !state.isAPIKeyFormatValid {
                        Text(state.urlMode == .ppio
                            ? "API Key 需以 \"sk_\" 开头，且长度不少于 20 位"
                            : "API Key 长度不少于 10 位")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        } actions: {
            HStack(spacing: 16) {
                Button("上一步") { state.goBack() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                Button("继续") { state.goNext() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canProceed)
            }
        }
        .onAppear { isFocused = true }
    }

    private var canProceed: Bool {
        guard state.isAPIKeyFormatValid else { return false }
        if state.urlMode == .custom {
            return state.baseUrl.hasPrefix("http") && state.baseUrl.count >= 10
        }
        return true
    }
}
