import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var state: InstallerState
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon + Title 区域
            VStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    .scaleEffect(appeared ? 1.0 : 0.9)
                    .opacity(appeared ? 1.0 : 0)

                VStack(spacing: 4) {
                    Text("PP Claude Code")
                        .font(.system(size: 22, weight: .semibold))

                    Text("安装助手 · v\(AppVersion.current)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer().frame(height: 36)

            // Features — 细线图标，统一 .secondary
            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "checkmark.shield", text: "自动检测并安装所需依赖")
                FeatureRow(icon: "key", text: "配置你的 PP API Key")
                FeatureRow(icon: "cpu", text: "支持 10+ 主流 AI 模型")
                FeatureRow(icon: "bolt", text: "几分钟即可开始使用")
            }

            Spacer()

            // CTA
            Button("开始安装") { state.goNext() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            Spacer().frame(height: 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
