import SwiftUI

struct APIKeyInputView: View {
    @EnvironmentObject var state: InstallerState
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("PPIO API Key")
                .font(.title2.bold())

            Text("Enter your PPIO API key to connect Claude Code.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("sk_...", text: $state.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($isFocused)

                if !state.apiKey.isEmpty && !state.isAPIKeyFormatValid {
                    Text("API key should start with \"sk_\" and be at least 20 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 60)

            Text("You can get your API key from the PPIO dashboard.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Button("Back") { state.goBack() }
                    .buttonStyle(.bordered)
                Button("Continue") { state.goNext() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!state.isAPIKeyFormatValid)
            }
            .padding(.bottom, 20)
        }
        .padding(.top, 20)
        .onAppear { isFocused = true }
    }
}
