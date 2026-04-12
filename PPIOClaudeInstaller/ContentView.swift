import SwiftUI

enum InstallerStep: Int, CaseIterable {
    case welcome = 0
    case networkSelection
    case dependencyCheck
    case apiKeyInput
    case modelSelection
    case validation
    case installConfig
    case completion
}

// MARK: - 统一三段式布局容器

struct PageLayout<Title: View, Content: View, Actions: View>: View {
    let title: Title
    let content: Content
    let actions: Actions

    init(
        @ViewBuilder title: () -> Title,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title()
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 0) {
            title
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                content
                    .frame(maxWidth: 420)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            actions
                .padding(.bottom, 32)
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(spacing: 0) {
            if state.currentStep != .welcome && state.currentStep != .completion {
                StepIndicator(currentStep: state.currentStep)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            }

            Group {
                switch state.currentStep {
                case .welcome:
                    WelcomeView()
                case .dependencyCheck:
                    DependencyCheckView()
                case .networkSelection:
                    NetworkSelectionView()
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

// MARK: - StepIndicator（精简：只有圆点，无文字标签）

struct StepIndicator: View {
    let currentStep: InstallerStep

    private let steps: [(icon: String, rawValue: Int)] = [
        ("bolt", 1),
        ("wrench.and.screwdriver", 2),
        ("key", 3),
        ("cpu", 4),
        ("checkmark.shield", 5),
        ("gear", 6),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                let step = steps[index]
                let isActive = currentStep.rawValue >= step.rawValue
                let isCurrent = isCurrentStep(step.rawValue)

                ZStack {
                    Circle()
                        .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.08))
                        .frame(width: 22, height: 22)
                    Image(systemName: step.icon)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(isActive ? .white : .secondary.opacity(0.4))
                }
                .scaleEffect(isCurrent ? 1.15 : 1.0)

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(currentStep.rawValue > step.rawValue ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.08))
                        .frame(height: 1)
                        .frame(maxWidth: 32)
                }
            }
        }
        .padding(.horizontal, 80)
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }

    private func isCurrentStep(_ rawValue: Int) -> Bool {
        switch currentStep {
        case .networkSelection: return rawValue == 1
        case .dependencyCheck: return rawValue == 2
        case .apiKeyInput: return rawValue == 3
        case .modelSelection: return rawValue == 4
        case .validation: return rawValue == 5
        case .installConfig: return rawValue == 6
        default: return false
        }
    }
}
