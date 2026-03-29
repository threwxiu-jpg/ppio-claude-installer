import Testing
@testable import PPIOClaudeInstaller

@Suite("InstallerState Tests")
@MainActor
struct InstallerStateTests {

    @Test func initialStep() {
        let state = InstallerState()
        #expect(state.currentStep == .welcome)
    }

    @Test func goNext() {
        let state = InstallerState()
        state.goNext()
        #expect(state.currentStep == .dependencyCheck)
        state.goNext()
        #expect(state.currentStep == .apiKeyInput)
    }

    @Test func goBack() {
        let state = InstallerState()
        state.goNext()
        state.goNext()
        state.goBack()
        #expect(state.currentStep == .dependencyCheck)
    }

    @Test func goBackFromWelcomeStays() {
        let state = InstallerState()
        state.goBack()
        #expect(state.currentStep == .welcome)
    }

    @Test func goNextFromCompletionStays() {
        let state = InstallerState()
        for _ in InstallerStep.allCases.dropFirst() {
            state.goNext()
        }
        #expect(state.currentStep == .completion)
        state.goNext()
        #expect(state.currentStep == .completion)
    }

    @Test func apiKeyFormatValidation() {
        let state = InstallerState()
        state.apiKey = ""
        #expect(!state.isAPIKeyFormatValid)

        state.apiKey = "invalid_key"
        #expect(!state.isAPIKeyFormatValid)

        state.apiKey = "sk_short"
        #expect(!state.isAPIKeyFormatValid)

        state.apiKey = "sk_G16mBG9wvThq1wPJxICpf5WX"
        #expect(state.isAPIKeyFormatValid)
    }

    @Test func effectiveModelID() {
        let state = InstallerState()
        #expect(state.effectiveModelID == "pa/claude-sonnet-4-6")

        state.useCustomModel = true
        state.customModelID = "pa/custom-model"
        #expect(state.effectiveModelID == "pa/custom-model")

        state.customModelID = ""
        #expect(state.effectiveModelID == "pa/claude-sonnet-4-6")

        state.useCustomModel = false
        state.customModelID = "pa/custom-model"
        #expect(state.effectiveModelID == "pa/claude-sonnet-4-6")
    }

    @Test func dependenciesInitialState() {
        let state = InstallerState()
        #expect(state.dependencies.count == 4)
        #expect(!state.allDependenciesReady)
    }
}
