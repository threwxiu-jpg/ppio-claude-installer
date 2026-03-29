import Testing
@testable import PPIOClaudeInstaller

@Suite("PPIOModel Tests")
struct PPIOModelTests {

    @Test func builtInModelsNotEmpty() {
        #expect(!PPIOModel.builtIn.isEmpty)
    }

    @Test func allModelsHaveValidIDs() {
        for model in PPIOModel.builtIn {
            #expect(!model.id.isEmpty, "Model \(model.displayName) has empty ID")
            #expect(model.id.contains("/"), "Model ID \(model.id) should contain a '/' prefix separator")
        }
    }

    @Test func allModelsHaveDisplayNames() {
        for model in PPIOModel.builtIn {
            #expect(!model.displayName.isEmpty, "Model \(model.id) has empty display name")
        }
    }

    @Test func modelIDsAreUnique() {
        let ids = PPIOModel.builtIn.map(\.id)
        #expect(ids.count == Set(ids).count, "Duplicate model IDs found")
    }

    @Test func defaultModelExists() {
        let defaultModel = PPIOModel.builtIn.first(where: { $0.id == "pa/claude-sonnet-4-6" })
        #expect(defaultModel != nil, "Default model pa/claude-sonnet-4-6 should exist")
    }
}
