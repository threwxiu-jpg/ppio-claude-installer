import SwiftUI

struct ValidationView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(spacing: 24) {
            Text("Verify Connection")
                .font(.title2.bold())

            VStack(spacing: 8) {
                Text("API Key: \(maskedKey)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Model: \(state.effectiveModelID)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            validationContent

            Spacer()

            HStack(spacing: 12) {
                Button("Back") { state.goBack() }
                    .buttonStyle(.bordered)

                if state.validationStatus == .success {
                    Button("Continue") { state.goNext() }
                        .buttonStyle(.borderedProminent)
                }

                if state.validationStatus == .failed {
                    Button("Retry") {
                        Task { await validate() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.top, 20)
        .task { await validate() }
    }

    @ViewBuilder
    private var validationContent: some View {
        switch state.validationStatus {
        case .idle, .validating:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Validating API key and model...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        case .success:
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                Text("Connection verified!")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        case .failed:
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                Text("Verification failed")
                    .font(.headline)
                    .foregroundColor(.red)
                if let error = state.validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
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
            modelID: state.effectiveModelID
        )

        state.validationStatus = success ? .success : .failed
        state.validationError = error
    }
}
