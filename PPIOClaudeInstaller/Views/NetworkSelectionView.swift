import SwiftUI

struct NetworkSelectionView: View {
    @EnvironmentObject var state: InstallerState
    @State private var isCheckingNetwork = true

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("网络环境")
                    .font(.title3.weight(.medium))
                Text("配置安装加速方式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } content: {
            if isCheckingNetwork {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text("正在测试网络连接...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 20) {
                    // 网络状态提示 — 一行文字，不抢视觉
                    HStack(spacing: 6) {
                        Image(systemName: state.networkSlow ? "exclamationmark.circle" : "checkmark.circle")
                            .font(.system(size: 12, weight: .regular))
                        Text(state.networkSlow ? "GitHub 连接较慢，建议使用镜像" : "网络连接正常")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    // 两个选择卡片
                    HStack(spacing: 12) {
                        NetworkCard(
                            title: "直连安装",
                            subtitle: "官方源",
                            icon: "globe",
                            isSelected: !state.useMirror
                        ) { state.useMirror = false }

                        NetworkCard(
                            title: "镜像加速",
                            subtitle: "USTC + npmmirror",
                            icon: "bolt",
                            isSelected: state.useMirror
                        ) { state.useMirror = true }
                    }

                    // 简短说明
                    Text("仅在本次安装过程中生效，不修改全局配置")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        } actions: {
            if !isCheckingNetwork {
                HStack(spacing: 16) {
                    Button("上一步") { state.goBack() }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    Button("开始安装") {
                        state.networkChecked = true
                        state.goNext()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .task { await checkNetwork() }
    }

    private func checkNetwork() async {
        isCheckingNetwork = true
        state.networkSlow = await DependencyChecker.checkNetworkSpeed()
        if state.networkSlow { state.useMirror = true }
        isCheckingNetwork = false
    }
}

private struct NetworkCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // 左侧选中指示器
                RoundedRectangle(cornerRadius: 1)
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 2)
                    .padding(.vertical, 8)

                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.04) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
