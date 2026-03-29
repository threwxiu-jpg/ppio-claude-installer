import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo area
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                Text("PP")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("PPIO Claude Code Installer")
                    .font(.system(size: 24, weight: .semibold))
                Text("One-click setup for Claude Code with PPIO")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "checkmark.circle", text: "Auto-detect and install dependencies")
                FeatureRow(icon: "key", text: "Configure your PPIO API key")
                FeatureRow(icon: "cpu", text: "Choose from 10+ AI models")
                FeatureRow(icon: "bolt", text: "Ready to use in minutes")
            }
            .padding(.horizontal, 60)

            Spacer()

            Button(action: { state.goNext() }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer().frame(height: 30)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}
