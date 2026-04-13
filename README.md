# PPIO Claude Installer

A cross-platform installer that configures [Claude Code](https://docs.anthropic.com/en/docs/claude-code) to work with the [PPIO API](https://ppio.com), [AI Proxy](https://apiproxy.paigod.work), or any custom API endpoint.

**[Download Latest Release](https://github.com/threwxiu-jpg/ppio-claude-installer/releases/latest)**

| Platform | Tech Stack | File |
|----------|-----------|------|
| macOS | SwiftUI | `PPIOClaudeInstaller.dmg` |
| Windows | Electron + React | `PP Claude Installer Setup.exe` |

## Features

- **Multi-provider support** — PPIO / AI Proxy / Custom URL, one-click switching
- **Dependency auto-detection** — checks and installs prerequisites (Xcode CLT, Homebrew, Node.js, Claude CLI on Mac; Git, Node.js, npm, Claude CLI on Windows)
- **Grouped dependency install** — base environment must be ready before tools unlock
- **API key validation** — verifies connection before writing any config
- **10+ built-in models** — Claude, GPT, Gemini, DeepSeek, Grok, MiniMax, Doubao + custom model input
- **Environment diagnostics** — post-install health check with CRITICAL / OPTIONAL severity levels
- **Mirror acceleration** (macOS) — USTC + npmmirror for users in China

## Supported API Providers

| Provider | Base URL | Key Format |
|----------|----------|-----------|
| PPIO | `https://api.ppio.com/anthropic` | `sk_...` (length >= 20) |
| AI Proxy | `https://apiproxy.paigod.work` | Any key (length >= 10) |
| Custom | User-defined | Any key (length >= 10) |

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

You can also enter any custom model ID in `vendor/model` format.

## Configuration Written

### macOS (`~/.zshrc`)

```bash
export ANTHROPIC_BASE_URL="https://api.ppio.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="sk_your_key"
export ANTHROPIC_MODEL="pa/claude-sonnet-4-6"
export ANTHROPIC_SMALL_FAST_MODEL="pa/claude-sonnet-4-6"
export CLAUDE_CODE_SKIP_AUTH_LOGIN=1
```

### Windows (`~/.claude/.env`)

```env
ANTHROPIC_BASE_URL=https://api.ppio.com/anthropic
ANTHROPIC_AUTH_TOKEN=your_key
ANTHROPIC_MODEL=pa/claude-sonnet-4-6
ANTHROPIC_SMALL_FAST_MODEL=pa/claude-sonnet-4-6
CLAUDE_CODE_SKIP_AUTH_LOGIN=1
```

### Both platforms (`~/.claude/settings.json`)

```json
{
  "model": "pa/claude-sonnet-4-6",
  "smallModel": "pa/claude-sonnet-4-6",
  "skipDangerousModePermissionPrompt": true
}
```

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| macOS | 14.0 (Sonoma) |
| Windows | 10+ |

## Build from Source

### macOS

```bash
cd ppio-claude-installer
swift build -c release
.build/release/PPIOClaudeInstaller
```

Build DMG:

```bash
./DMG/build-dmg.sh
# Output: dist/PPIOClaudeInstaller.dmg
```

### Windows

```bash
cd win
npm install
npm run dev      # development
npm run build    # production → release/PP Claude Installer Setup.exe
```

## Project Structure

```
PPIOClaudeInstaller/           # macOS (SwiftUI)
├── PPIOClaudeInstallerApp.swift
├── Models/
│   ├── InstallerState.swift
│   └── PPIOModel.swift
├── Services/
│   ├── ConfigWriter.swift
│   ├── DependencyChecker.swift
│   ├── EnvironmentDoctor.swift
│   ├── PPIOValidator.swift
│   └── ShellExecutor.swift
└── Views/                     # 8 wizard step views

win/                           # Windows (Electron + React)
├── electron/
│   ├── main.ts
│   ├── preload.ts
│   └── services/              # shell/dependency/config/validator/doctor
├── src/
│   ├── components/            # PageLayout, StepIndicator
│   ├── pages/                 # 8 wizard step pages
│   └── styles/
├── package.json
└── electron-builder.yml
```

## Changelog

### v1.0.1
- Fix Homebrew install failure on USTC mirror (`git remote set-head --auto` error)
- Fix Homebrew detection showing "未安装" after successful USTC mirror install
- Fix installer step order (network selection was being skipped)
- Fix Claude CLI detection in post-install diagnostics (GUI app PATH issue)
- Shrink network selection card UI
- Add `--with-xcode-clt` flag to `uninstall-for-test.sh`

### v1.0.0
- Initial release

## License

[MIT](LICENSE)
