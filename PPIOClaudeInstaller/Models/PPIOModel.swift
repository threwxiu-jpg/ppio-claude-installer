import Foundation

struct PPIOModel: Identifiable, Hashable {
    let id: String      // e.g. "pa/claude-opus-4-6"
    let displayName: String

    static let builtIn: [PPIOModel] = [
        PPIOModel(id: "pa/claude-opus-4-6", displayName: "Claude Opus 4.6"),
        PPIOModel(id: "pa/claude-sonnet-4-6", displayName: "Claude Sonnet 4.6"),
        PPIOModel(id: "pa/gt-4.1", displayName: "GPT-4.1"),
        PPIOModel(id: "pa/gt-4.1-m", displayName: "GPT-4.1 Mini"),
        PPIOModel(id: "pa/gmn-2.5-fls", displayName: "Gemini 2.5 Flash"),
        PPIOModel(id: "deepseek/deepseek-v3.2", displayName: "DeepSeek V3.2"),
        PPIOModel(id: "deepseek/deepseek-r1-0528", displayName: "DeepSeek R1"),
        PPIOModel(id: "pa/grk-4", displayName: "Grok 4"),
        PPIOModel(id: "minimax/minimax-m2.1", displayName: "MiniMax M2.1"),
        PPIOModel(id: "pa/doubao-seed-1.6", displayName: "Doubao Seed 1.6"),
    ]
}
