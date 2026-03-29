import SwiftUI

struct DependencyCheckView: View {
    @EnvironmentObject var state: InstallerState
    @State private var isChecking = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Environment Check")
                .font(.title2.bold())

            Text("Checking required dependencies...")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ForEach(state.dependencies) { dep in
                    DependencyRow(item: dep) {
                        await installDependency(dep.id)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 12) {
                Button("Back") { state.goBack() }
                    .buttonStyle(.bordered)

                if state.allDependenciesReady {
                    Button("Continue") { state.goNext() }
                        .buttonStyle(.borderedProminent)
                } else if !isChecking {
                    Button("Check Again") {
                        Task { await runChecks() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.top, 20)
        .task { await runChecks() }
    }

    private func runChecks() async {
        isChecking = true
        await DependencyChecker.checkAll(state: state)
        isChecking = false
    }

    private func installDependency(_ id: String) async {
        guard let index = state.dependencies.firstIndex(where: { $0.id == id }) else { return }
        state.dependencies[index].status = .installing
        let status = await DependencyChecker.install(id)
        state.dependencies[index].status = status
        // Re-evaluate overall readiness
        state.allDependenciesReady = state.dependencies.allSatisfy {
            if case .installed = $0.status { return true }
            return false
        }
    }
}

struct DependencyRow: View {
    let item: DependencyItem
    let onInstall: () async -> Void
    @State private var isInstalling = false

    var body: some View {
        HStack {
            statusIcon
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                statusText
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if case .missing = item.status {
                Button("Install") {
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

            if case .failed = item.status {
                Button("Retry") {
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .unchecked:
            Image(systemName: "circle.dashed")
                .foregroundColor(.secondary)
        case .checking, .installing:
            ProgressView()
                .controlSize(.small)
        case .installed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .missing:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.orange)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch item.status {
        case .unchecked:
            Text("Waiting...")
        case .checking:
            Text("Checking...")
        case .installing:
            Text("Installing...")
        case .installed(let version):
            Text(version)
        case .missing:
            Text("Not found - click Install")
        case .failed(let msg):
            Text(msg)
                .lineLimit(2)
        }
    }
}
