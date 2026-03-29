import Foundation
import SwiftUI

enum DependencyStatus: Equatable {
    case unchecked
    case checking
    case installed(version: String)
    case missing
    case installing
    case failed(String)
}

struct DependencyItem: Identifiable {
    let id: String
    let name: String
    var status: DependencyStatus = .unchecked
}

@MainActor
class InstallerState: ObservableObject {
    @Published var currentStep: InstallerStep = .welcome

    // Dependencies
    @Published var dependencies: [DependencyItem] = [
        DependencyItem(id: "xcode-clt", name: "Xcode Command Line Tools"),
        DependencyItem(id: "homebrew", name: "Homebrew"),
        DependencyItem(id: "nodejs", name: "Node.js (>=18)"),
        DependencyItem(id: "claude-cli", name: "Claude Code CLI"),
    ]
    @Published var allDependenciesReady = false

    // API Key
    @Published var apiKey = ""
    var isAPIKeyFormatValid: Bool {
        apiKey.hasPrefix("sk_") && apiKey.count >= 20
    }

    // Model
    @Published var selectedModel: PPIOModel? = PPIOModel.builtIn.first(where: { $0.id == "pa/claude-sonnet-4-6" })
    @Published var customModelID = ""
    @Published var useCustomModel = false

    var effectiveModelID: String {
        if useCustomModel && !customModelID.isEmpty {
            return customModelID
        }
        return selectedModel?.id ?? "pa/claude-sonnet-4-6"
    }

    // Validation
    @Published var validationStatus: ValidationStatus = .idle
    @Published var validationError: String?

    // Install
    @Published var installStatus: InstallStatus = .idle
    @Published var installError: String?

    func goNext() {
        if let next = InstallerStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
            }
        }
    }

    func goBack() {
        if let prev = InstallerStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = prev
            }
        }
    }
}

enum ValidationStatus {
    case idle
    case validating
    case success
    case failed
}

enum InstallStatus {
    case idle
    case installing
    case success
    case failed
}
