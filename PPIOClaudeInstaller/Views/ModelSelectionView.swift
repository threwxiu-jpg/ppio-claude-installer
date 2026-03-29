import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Model")
                .font(.title2.bold())

            Text("Choose the default AI model for Claude Code.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(PPIOModel.builtIn) { model in
                        ModelRow(model: model, isSelected: !state.useCustomModel && state.selectedModel == model) {
                            state.useCustomModel = false
                            state.selectedModel = model
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // Custom model input
                    HStack {
                        Toggle("Custom model ID:", isOn: $state.useCustomModel)
                            .toggleStyle(.checkbox)
                            .font(.subheadline)
                        TextField("e.g. pa/my-model", text: $state.customModelID)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                            .disabled(!state.useCustomModel)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Back") { state.goBack() }
                    .buttonStyle(.bordered)
                Button("Continue") { state.goNext() }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.useCustomModel && state.customModelID.isEmpty)
            }
            .padding(.bottom, 20)
        }
        .padding(.top, 20)
    }
}

struct ModelRow: View {
    let model: PPIOModel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(model.id)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontDesign(.monospaced)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
