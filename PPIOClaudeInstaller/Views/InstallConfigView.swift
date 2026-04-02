import SwiftUI

struct InstallConfigView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("安装配置")
                    .font(.title3.weight(.medium))
                Text("写入 Claude Code 配置文件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } content: {
            if !state.conflicts.isEmpty && !state.conflictsAcknowledged {
                conflictWarningContent
            } else {
                installContent
            }
        } actions: {
            if state.installStatus == .success {
                Button("完成") { state.goNext() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }

            if state.installStatus == .failed {
                HStack(spacing: 16) {
                    Button("上一步") { state.goBack() }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    Button("重试") { Task { await install() } }
                        .buttonStyle(.bordered)
                }
            }
        }
        .task { await checkAndInstall() }
    }

    @ViewBuilder
    private var conflictWarningContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.orange)

            Text("检测到已有配置")
                .font(.subheadline.weight(.medium))

            Text("以下 export 语句会覆盖新配置，建议先注释掉。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 冲突列表 — 左侧橙色竖线
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.orange.opacity(0.6))
                    .frame(width: 2)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(state.conflicts, id: \.lineNumber) { conflict in
                        HStack(spacing: 4) {
                            Text("\(conflict.line):\(conflict.lineNumber)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text(conflict.variable)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.leading, 10)
                .padding(.vertical, 8)
            }

            HStack(spacing: 16) {
                Button("重新检测") {
                    state.conflicts = ConfigWriter.detectConflicts()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button("仍然继续") {
                    state.conflictsAcknowledged = true
                    Task { await install() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var installContent: some View {
        switch state.installStatus {
        case .idle, .installing:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.regular)
                Text("正在写入配置...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        case .success:
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.green)
                Text("配置保存成功")
                    .font(.subheadline.weight(.medium))

                VStack(alignment: .leading, spacing: 6) {
                    Text("~/.zshrc")
                        .font(.system(.caption, design: .monospaced))
                    Text("~/.claude/settings.json")
                        .font(.system(.caption, design: .monospaced))
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
        case .failed:
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.red)
                Text("配置写入失败")
                    .font(.subheadline.weight(.medium))
                if let error = state.installError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func checkAndInstall() async {
        state.conflicts = ConfigWriter.detectConflicts()
        if state.conflicts.isEmpty { await install() }
    }

    private func install() async {
        state.installStatus = .installing
        state.installError = nil
        let (success, error) = await ConfigWriter.writeConfig(
            apiKey: state.apiKey,
            modelID: state.effectiveModelID
        )
        state.installStatus = success ? .success : .failed
        state.installError = error
    }
}
