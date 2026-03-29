import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        PageLayout {
            VStack(spacing: 6) {
                Text("选择模型")
                    .font(.title3.weight(.medium))
                Text("Claude Code 默认使用的 AI 模型")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } content: {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(PPIOModel.builtIn) { model in
                        ModelRow(model: model, isSelected: !state.useCustomModel && state.selectedModel == model) {
                            state.useCustomModel = false
                            state.selectedModel = model
                        }
                    }

                    Divider().padding(.vertical, 8)

                    HStack {
                        Toggle("自定义模型 ID：", isOn: $state.useCustomModel)
                            .toggleStyle(.checkbox)
                            .font(.subheadline)
                        TextField("e.g. pa/my-model", text: $state.customModelID)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                            .disabled(!state.useCustomModel)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: 440)
        } actions: {
            HStack(spacing: 16) {
                Button("上一步") { state.goBack() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                Button("继续") { state.goNext() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(state.useCustomModel && state.customModelID.isEmpty)
            }
        }
    }
}

private struct ModelRow: View {
    let model: PPIOModel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // 左侧选中指示器
                RoundedRectangle(cornerRadius: 1)
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 2, height: 28)

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
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
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.04) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
