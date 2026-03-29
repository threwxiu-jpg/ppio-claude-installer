import SwiftUI

struct InstallConfigView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(spacing: 24) {
            Text("Installing Configuration")
                .font(.title2.bold())

            Spacer()

            installContent

            Spacer()

            if state.installStatus == .success {
                Button("Finish") { state.goNext() }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 20)
            }

            if state.installStatus == .failed {
                HStack(spacing: 12) {
                    Button("Back") { state.goBack() }
                        .buttonStyle(.bordered)
                    Button("Retry") {
                        Task { await install() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 20)
        .task { await install() }
    }

    @ViewBuilder
    private var installContent: some View {
        switch state.installStatus {
        case .idle, .installing:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Writing configuration files...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        case .success:
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                Text("Configuration saved!")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    ConfigFileRow(path: "~/.claude/.env", desc: "API key & proxy settings")
                    ConfigFileRow(path: "~/.claude/settings.json", desc: "Claude Code settings")
                }
                .padding(.top, 8)
            }
        case .failed:
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                Text("Configuration failed")
                    .font(.headline)
                    .foregroundColor(.red)
                if let error = state.installError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
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

struct ConfigFileRow: View {
    let path: String
    let desc: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)
                .frame(width: 16)
            VStack(alignment: .leading) {
                Text(path)
                    .font(.system(.caption, design: .monospaced))
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
