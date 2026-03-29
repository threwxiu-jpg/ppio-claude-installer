import SwiftUI

struct DependencyCheckView: View {
    @EnvironmentObject var state: InstallerState
    @State private var isChecking = false

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("环境检测")
                    .font(.title3.weight(.medium))
                Text(isChecking ? "正在检查所需依赖..." : statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } content: {
            VStack(spacing: 0) {
                ForEach(Array(state.dependencies.enumerated()), id: \.element.id) { index, dep in
                    DependencyRow(item: dep) {
                        await installDependency(dep.id)
                    }
                    if index < state.dependencies.count - 1 {
                        Divider().padding(.leading, 32)
                    }
                }
            }

            if state.useMirror && state.networkChecked {
                HStack(spacing: 4) {
                    Image(systemName: "bolt")
                        .font(.system(size: 10, weight: .regular))
                    Text("镜像加速已开启")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.top, 12)
            }
        } actions: {
            HStack(spacing: 16) {
                Button("上一步") { state.goBack() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                if state.allDependenciesReady {
                    Button("继续") { state.currentStep = .apiKeyInput }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                } else if !isChecking {
                    Button("重新检查") { Task { await runChecks() } }
                        .buttonStyle(.bordered)
                }
            }
        }
        .task { await runChecks() }
    }

    private var statusMessage: String {
        if state.allDependenciesReady { return "所有依赖已就绪" }
        return "以下依赖需要安装"
    }

    private func runChecks() async {
        isChecking = true
        await DependencyChecker.checkAll(state: state)
        isChecking = false

        let hasMissing = state.dependencies.contains { dep in
            if case .missing = dep.status { return true }
            if case .failed = dep.status { return true }
            return false
        }

        if hasMissing && !state.networkChecked {
            state.needsInstall = true
            state.goNext()
        }
    }

    private func installDependency(_ id: String) async {
        guard let index = state.dependencies.firstIndex(where: { $0.id == id }) else { return }
        state.dependencies[index].status = .installing
        let status = await DependencyChecker.install(id, useMirror: state.useMirror)
        state.dependencies[index].status = status
        state.allDependenciesReady = state.dependencies.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
    }
}

private struct DependencyRow: View {
    let item: DependencyItem
    let onInstall: () async -> Void
    @State private var isInstalling = false

    var body: some View {
        HStack(spacing: 10) {
            statusIcon
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.subheadline)
                statusText
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if case .missing = item.status {
                installButton
            }
            if case .failed = item.status {
                installButton
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private var installButton: some View {
        Button("安装") {
            isInstalling = true
            Task {
                await onInstall()
                isInstalling = false
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(isInstalling)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .unchecked:
            Image(systemName: "circle.dashed")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary.opacity(0.4))
        case .checking, .installing:
            ProgressView()
                .controlSize(.small)
        case .installed:
            Image(systemName: "checkmark.circle")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.green)
        case .missing:
            Image(systemName: "xmark.circle")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.orange)
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.red)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch item.status {
        case .unchecked: Text("等待检查...")
        case .checking: Text("检查中...")
        case .installing: Text("安装中...")
        case .installed(let version): Text(version)
        case .missing: Text("未安装")
        case .failed(let msg): Text(msg).lineLimit(2)
        }
    }
}
