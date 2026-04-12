import Foundation
import SwiftUI

enum UrlMode: String, CaseIterable {
    case ppio
    case aiproxy
    case custom

    var label: String {
        switch self {
        case .ppio: return "PPIO"
        case .aiproxy: return "AI Proxy"
        case .custom: return "自定义"
        }
    }

    var presetUrl: String? {
        switch self {
        case .ppio: return "https://api.ppio.com/anthropic"
        case .aiproxy: return "https://apiproxy.paigod.work"
        case .custom: return nil
        }
    }
}

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
    @Published var useMirror = false
    @Published var networkChecked = false
    @Published var networkSlow = false
    @Published var needsInstall = false

    // URL Mode
    @Published var urlMode: UrlMode = .ppio
    @Published var baseUrl: String = "https://api.ppio.com/anthropic"

    // API Key
    @Published var apiKey = ""
    var isAPIKeyFormatValid: Bool {
        if urlMode == .ppio {
            return apiKey.hasPrefix("sk_") && apiKey.count >= 20
        }
        return apiKey.count >= 10
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

    // Conflict detection
    @Published var conflicts: [ConflictingExport] = []
    @Published var conflictsAcknowledged = false

    // Install
    @Published var installStatus: InstallStatus = .idle
    @Published var installError: String?

    // Diagnostics
    @Published var diagnosticResults: [DiagnosticResult] = []
    @Published var diagnosticStatus: DiagnosticStatus = .idle

    func goNext() {
        let nextRaw = currentStep.rawValue + 1
        if let next = InstallerStep(rawValue: nextRaw) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
            }
        }
    }

    func goBack() {
        let prevRaw = currentStep.rawValue - 1
        if let prev = InstallerStep(rawValue: prevRaw) {
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
