import SwiftUI

enum InstallerStep: Int, CaseIterable {
    case welcome = 0
    case dependencyCheck
    case apiKeyInput
    case modelSelection
    case validation
    case installConfig
    case completion
}

struct ContentView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            if state.currentStep != .welcome && state.currentStep != .completion {
                StepIndicator(currentStep: state.currentStep)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }

            // Main content
            Group {
                switch state.currentStep {
                case .welcome:
                    WelcomeView()
                case .dependencyCheck:
                    DependencyCheckView()
                case .apiKeyInput:
                    APIKeyInputView()
                case .modelSelection:
                    ModelSelectionView()
                case .validation:
                    ValidationView()
                case .installConfig:
                    InstallConfigView()
                case .completion:
                    CompletionView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct StepIndicator: View {
    let currentStep: InstallerStep
    private let steps = ["Environment", "API Key", "Model", "Verify", "Install"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<steps.count, id: \.self) { index in
                let stepIndex = index + 1 // dependencyCheck starts at rawValue 1
                HStack(spacing: 4) {
                    Circle()
                        .fill(stepIndex <= currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(steps[index])
                        .font(.caption2)
                        .foregroundColor(stepIndex <= currentStep.rawValue ? .primary : .secondary)
                }
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(stepIndex < currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: 20)
                }
            }
        }
        .padding(.horizontal, 40)
    }
}
