import SwiftUI

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "party.popper.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow, .orange)

            Text("All Set!")
                .font(.title.bold())

            Text("Claude Code is ready to use with PPIO.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("1.")
                        .fontWeight(.bold)
                    Text("Open Terminal")
                }
                HStack(spacing: 8) {
                    Text("2.")
                        .fontWeight(.bold)
                    Text("Type")
                    Text("claude")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)))
                    Text("and press Enter")
                }
                HStack(spacing: 8) {
                    Text("3.")
                        .fontWeight(.bold)
                    Text("Start coding with AI!")
                }
            }
            .font(.subheadline)

            Spacer()

            HStack(spacing: 12) {
                Button("Open Terminal") {
                    openTerminal()
                }
                .buttonStyle(.borderedProminent)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 30)
        }
    }

    private func openTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script ""
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
