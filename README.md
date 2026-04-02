# PPIO Claude Installer

A macOS app that helps you configure [Claude Code](https://claude.ai/claude-code) to work with the [PPIO API](https://ppio.com) in just a few clicks.

## What It Does

This installer provides a step-by-step wizard that:

1. **Checks dependencies** - Verifies Xcode CLT, Homebrew, Node.js (>=18), and Claude Code CLI are installed; offers to install any missing ones
2. **Collects your API key** - Validates your PPIO API key format (`sk_...`)
3. **Lets you pick a model** - Choose from 10 built-in models (Claude, GPT, Gemini, DeepSeek, Grok, MiniMax, Doubao) or enter a custom model ID
4. **Validates the connection** - Tests your API key against the PPIO endpoint before writing any config
5. **Writes configuration** - Sets up `~/.zshrc` environment variables and `~/.claude/settings.json` so Claude Code connects through PPIO
6. **Runs environment diagnostics** - Post-install health check verifying all configuration is effective, with CRITICAL / OPTIONAL severity levels

## Configuration Written

### ~/.zshrc

```bash
export ANTHROPIC_BASE_URL="https://api.ppio.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="sk_your_key"
export ANTHROPIC_MODEL="pa/claude-sonnet-4-6"
export ANTHROPIC_SMALL_FAST_MODEL="pa/claude-sonnet-4-6"
export CLAUDE_CODE_SKIP_AUTH_LOGIN=1
```

### ~/.claude/settings.json

```json
{
  "model": "pa/claude-sonnet-4-6",
  "smallModel": "pa/claude-sonnet-4-6",
  "skipDangerousModePermissionPrompt": true
}
```

## Environment Diagnostics

The completion page includes a built-in **Environment Doctor** that checks:

| Check | Level | What it verifies |
|-------|-------|-----------------|
| Claude Code installed | CRITICAL | App in /Applications or CLI in PATH |
| ANTHROPIC_BASE_URL | CRITICAL | Correct URL, no trailing `/v1` |
| ANTHROPIC_AUTH_TOKEN | CRITICAL | Present and starts with `sk_` |
| CLAUDE_CODE_SKIP_AUTH_LOGIN | CRITICAL | Set to `1` |
| Network connectivity | CRITICAL | Can reach api.ppio.com |
| API key validation | CRITICAL | Actual API request succeeds |
| settings.json model | CRITICAL | Has `pa/` prefix |
| Wrong variable name | CRITICAL | No `ANTHROPIC_API_KEY` (common mistake) |
| ANTHROPIC_MODEL env | OPTIONAL | settings.json can substitute |
| ANTHROPIC_SMALL_FAST_MODEL env | OPTIONAL | settings.json can substitute |
| settings.json smallModel | OPTIONAL | Not strictly required |
| ~/.claude permissions | OPTIONAL | Writable by current user |

A standalone shell diagnostic script is also available at `scripts/cc-ppio-doctor.sh`.

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
git clone https://github.com/threwxiu-jpg/ppio-claude-installer.git
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
│   ├── EnvironmentDoctor.swift    # Post-install environment diagnostics
│   ├── PPIOValidator.swift        # Validates API key
│   └── ShellExecutor.swift        # Shell command runner
└── Views/                         # 8 wizard step views
```

## License

[MIT](LICENSE)
