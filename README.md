# PPIO Claude Installer

一键配置 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 使用 [PPIO API](https://ppio.com) 的跨平台安装器，同时支持 AI Proxy 及自定义 API 端点。

## Download

| Platform | Version | Link |
|----------|---------|------|
| macOS (14.0+) | v1.0.1 | [**PPIOClaudeInstaller.dmg**](https://github.com/threwxiu-jpg/ppio-claude-installer/releases/download/v1.0.1/PPIOClaudeInstaller.dmg) |
| Windows (10+) | v1.1.0 | [**PP.Claude.Installer.Setup.exe**](https://github.com/threwxiu-jpg/ppio-claude-installer/releases/download/v1.1.0/PP.Claude.Installer.Setup.exe) |

## Features

- **Multi-provider support** — PPIO / AI Proxy / Custom URL, one-click switching
- **Dependency auto-detection** — checks and installs prerequisites (Xcode CLT, Homebrew, Node.js, Claude CLI on Mac; Git, Node.js, npm, Claude CLI on Windows)
- **Grouped dependency install** — base environment must be ready before tools unlock
- **API key validation** — verifies connection before writing any config
- **10+ built-in models** — Claude, GPT, Gemini, DeepSeek, Grok, MiniMax, Doubao + custom model input
- **Environment diagnostics** — post-install health check with CRITICAL / OPTIONAL severity levels
- **Mirror acceleration** — USTC + npmmirror (macOS); npmmirror CDN for Git installer (Windows, ~19× faster than GitHub direct)

## Supported API Providers

| Provider | Base URL | Key Format |
|----------|----------|-----------|
| PPIO | `https://api.ppio.com/anthropic` | `sk_...` (length >= 20) |
| AI Proxy | `https://apiproxy.paigod.work/v1` | Any key (length >= 10) |
| Custom | User-defined | Any key (length >= 10) |

## Supported Models

### PPIO

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

### AI Proxy

| Model | ID |
|-------|-----|
| Claude Opus 4.6 | `pa/claude-opus-4-6` |
| Claude Sonnet 4.6 | `pa/claude-sonnet-4-6` |
| Claude Haiku 4.5 | `pa/claude-haiku-4-5-20251001` |
| DeepSeek V3.2 | `deepseek/deepseek-v3.2` |
| DeepSeek R1 | `deepseek/deepseek-r1-0528` |
| MiniMax M2.5 | `minimax/minimax-m2.5` |
| Doubao Seed 1.6 | `pa/doubao-seed-1.6` |

All providers also support entering any custom model ID manually.

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

### v1.1.0 (Windows)
- **Git mirror acceleration** — when mirror mode is selected, downloads Git installer from npmmirror CDN instead of winget/GitHub (~19× faster for users in China)
- **AI Proxy URL updated** to `https://apiproxy.paigod.work/v1`
- **Separate model lists** for PPIO and AI Proxy; custom URL mode shows a dedicated model ID input
- **Manual model input** added alongside preset list for PPIO and AI Proxy (type to activate, click preset to clear)
- **Clickable error links** — URLs in dependency error messages now open in the system browser

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
