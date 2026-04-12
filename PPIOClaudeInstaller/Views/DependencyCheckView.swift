import SwiftUI

private let prereqIDs: Set<String> = ["xcode-clt", "homebrew", "nodejs"]
private let toolIDs: Set<String> = ["claude-cli"]

struct DependencyCheckView: View {
    @EnvironmentObject var state: InstallerState
    @State private var isChecking = false

    private var prereqs: [DependencyItem] {
        state.dependencies.filter { prereqIDs.contains($0.id) }
    }
    private var tools: [DependencyItem] {
        state.dependencies.filter { toolIDs.contains($0.id) }
    }
    private var prereqsReady: Bool {
        // Homebrew is optional — mirror essentialReady logic in DependencyChecker.checkAll
        prereqs.filter { $0.id != "homebrew" }.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
    }

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
                // Group 1: Prerequisites
                Text("基础环境")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)

                ForEach(Array(prereqs.enumerated()), id: \.element.id) { index, dep in
                    DependencyRow(item: dep) {
                        await installDependency(dep.id)
                    }
                    if index < prereqs.count - 1 {
                        Divider().padding(.leading, 32)
                    }
                }

                Divider().padding(.vertical, 8)

                // Group 2: Tools (locked until prereqs ready)
                HStack(spacing: 6) {
                    Text("Claude Code")
                        .font(.system(.caption2, design: .monospaced))
                    if !prereqsReady {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("请先完成基础环境安装")
                            .font(.caption2)
                    }
                }
                .foregroundColor(prereqsReady ? .secondary : .secondary.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                Group {
                    ForEach(Array(tools.enumerated()), id: \.element.id) { index, dep in
                        DependencyRow(item: dep, disabled: !prereqsReady) {
                            await installDependency(dep.id)
                        }
                        if index < tools.count - 1 {
                            Divider().padding(.leading, 32)
                        }
                    }
                }
                .opacity(prereqsReady ? 1 : 0.4)
            }

            // Mirror toggle
            if hasMissing {
                HStack(spacing: 6) {
                    Toggle(isOn: $state.useMirror) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt")
                                .font(.system(size: 10, weight: .regular))
                            Text("镜像加速（USTC + npmmirror）")
                                .font(.caption)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
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
                    Button("继续") { state.goNext() }
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

    private var hasMissing: Bool {
        state.dependencies.contains { dep in
            if case .missing = dep.status { return true }
            if case .failed = dep.status { return true }
            return false
        }
    }

    private var statusMessage: String {
        if state.allDependenciesReady { return "所有依赖已就绪" }
        return "以下依赖需要安装"
    }

    private func runChecks() async {
        isChecking = true
        await DependencyChecker.checkAll(state: state)
        isChecking = false
    }

    private func installDependency(_ id: String) async {
        guard let index = state.dependencies.firstIndex(where: { $0.id == id }) else { return }
        state.dependencies[index].status = .installing
        let status = await DependencyChecker.install(id, useMirror: state.useMirror)
        state.dependencies[index].status = status
        let essentialReady = state.dependencies.filter { $0.id != "homebrew" }.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
        let allInstalled = state.dependencies.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
        state.allDependenciesReady = allInstalled || essentialReady
    }
}

private struct DependencyRow: View {
    let item: DependencyItem
    var disabled: Bool = false
    let onInstall: () async -> Void
    @State private var isInstalling = false
    @State private var installProgress: Double = 0
    @State private var progressMessage: String = "准备中..."

    // Expected install durations (seconds) for determinate progress
    // Use generous values — bar caps at 0.95 so it won't run out early
    private var expectedDuration: Double {
        switch item.id {
        case "nodejs":    return 180
        case "claude-cli": return 120
        default:          return 0   // 0 = indeterminate
        }
    }

    private func stepMessage(for progress: Double) -> String {
        switch item.id {
        case "nodejs":
            if progress < 0.15 { return "连接 Homebrew..." }
            if progress < 0.65 { return "下载 Node.js..." }
            return "安装中..."
        case "claude-cli":
            if progress < 0.25 { return "连接 npm 仓库..." }
            if progress < 0.75 { return "下载 claude-code 包..." }
            return "安装中..."
        case "homebrew":
            return "请切换到终端窗口并输入密码（未看到请点击 Dock 中的终端图标）"
        default:
            return "安装中..."
        }
    }

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

            if !disabled {
                if case .missing = item.status {
                    installButton
                }
                if case .failed = item.status {
                    installButton
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .task(id: isInstalling) {
            guard isInstalling else { return }
            // Set the initial message immediately for ALL items (incl. indeterminate)
            installProgress = 0
            progressMessage = stepMessage(for: 0)
            guard expectedDuration > 0 else { return }  // indeterminate stops here
            let start = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                let p = min(Date().timeIntervalSince(start) / expectedDuration, 0.95)
                installProgress = p
                progressMessage = stepMessage(for: p)
            }
        }
    }

    private var installButton: some View {
        Button("安装") {
            isInstalling = true
            Task {
                await onInstall()
                isInstalling = false
                installProgress = 1.0
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
        case .installing:
            VStack(alignment: .leading, spacing: 4) {
                if expectedDuration > 0 {
                    ProgressView(value: installProgress)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                }
                Text(progressMessage)
                    .font(.caption2)
                    .foregroundColor(item.id == "homebrew" ? .orange : .secondary)
            }
            .padding(.top, 2)
        case .installed(let version): Text(version)
        case .missing: Text("未安装")
        case .failed(let msg): Text(msg).lineLimit(2)
        }
    }
}
