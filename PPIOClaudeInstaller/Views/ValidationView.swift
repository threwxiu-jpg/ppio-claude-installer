import SwiftUI

struct ValidationView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("验证连接")
                    .font(.title3.weight(.medium))
                HStack(spacing: 8) {
                    Text(maskedKey)
                    Text("·")
                    Text(state.effectiveModelID)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .fontDesign(.monospaced)
            }
        } content: {
            validationContent
                .animation(.easeInOut(duration: 0.25), value: state.validationStatus)
        } actions: {
            HStack(spacing: 16) {
                Button("上一步") { state.goBack() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                if state.validationStatus == .success {
                    Button("继续") { state.goNext() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }

                if state.validationStatus == .failed {
                    Button("重试") { Task { await validate() } }
                        .buttonStyle(.bordered)
                }
            }
        }
        .task { await validate() }
    }

    @ViewBuilder
    private var validationContent: some View {
        switch state.validationStatus {
        case .idle, .validating:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.regular)
                Text("正在验证...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        case .success:
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.green)
                Text("连接验证成功")
                    .font(.subheadline.weight(.medium))
            }
        case .failed:
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.red)
                Text("验证失败")
                    .font(.subheadline.weight(.medium))
                if let error = state.validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var maskedKey: String {
        let key = state.apiKey
        if key.count > 10 {
            return String(key.prefix(6)) + "..." + String(key.suffix(4))
        }
        return "***"
    }

    private func validate() async {
        state.validationStatus = .validating
        state.validationError = nil
        let (success, error) = await PPIOValidator.validate(
            apiKey: state.apiKey,
            modelID: state.effectiveModelID,
            baseUrl: state.baseUrl
        )
        state.validationStatus = success ? .success : .failed
        state.validationError = error
    }
}
