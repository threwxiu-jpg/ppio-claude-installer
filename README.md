# PPIO Claude Installer

A macOS app that helps you configure [Claude Code](https://claude.ai/claude-code) to work with the [PPIO API](https://ppio.com) in just a few clicks.

## What It Does

This installer provides a step-by-step wizard that:

1. **Checks dependencies** - Verifies Xcode CLT, Homebrew, Node.js (>=18), and Claude Code CLI are installed; offers to install any missing ones
2. **Collects your API key** - Validates your PPIO API key format (`sk_...`)
3. **Lets you pick a model** - Choose from 10 built-in models (Claude, GPT, Gemini, DeepSeek, Grok, MiniMax, Doubao) or enter a custom model ID
4. **Validates the connection** - Tests your API key against the PPIO endpoint before writing any config
5. **Writes configuration** - Sets up `~/.zshrc` environment variables and `~/.claude/settings.json` so Claude Code connects through PPIO

## Supported Models

| Model | ID |
|-------|-----|
| Claude Opus 4.6 | `pa/claude-opus-4-6` |
| Claude Sonnet 4.6 | `pa/claude-sonnet-4-6` |
| GPT-4.1 | `pa/gt-4.1` |
| GPT-4.1 Mini | `pa/gt-4.1-m` |
| Gemini 2.5 Flash | `pa/gmn-2.5-fls` |
| DeepSeek V3.2 | `deepseek/deepseek-v3.2` |
| DeepSeek R1 | `deepseek/deepseek-r1-0528` |
| Grok 4 | `pa/grk-4` |
| MiniMax M2.1 | `minimax/minimax-m2.1` |
| Doubao Seed 1.6 | `pa/doubao-seed-1.6` |

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Build from Source

```bash
# Clone the repo
git clone https://github.com/ppio/ppio-claude-installer.git
cd ppio-claude-installer

# Build
swift build -c release

# Run
.build/release/PPIOClaudeInstaller
```

## Build DMG

```bash
./DMG/build-dmg.sh
# Output: dist/PPIOClaudeInstaller.dmg
```

## Project Structure

```
PPIOClaudeInstaller/
├── PPIOClaudeInstallerApp.swift   # App entry point
├── ContentView.swift              # Main view with step navigation
├── Models/
│   ├── InstallerState.swift       # App state management
│   └── PPIOModel.swift            # Model definitions
├── Services/
│   ├── ConfigWriter.swift         # Writes ~/.zshrc and settings.json
│   ├── DependencyChecker.swift    # Checks/installs dependencies
│   ├── PPIOValidator.swift        # Validates API key
│   └── ShellExecutor.swift        # Shell command runner
└── Views/                         # 7 wizard step views
```

## License

[MIT](LICENSE)
