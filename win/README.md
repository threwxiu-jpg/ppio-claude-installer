# PP Claude Installer (Windows)

一键配置 Claude Code 使用 PPIO API 的 Windows 安装向导。

## 功能

- 自动检测并安装 Node.js、npm、Claude Code CLI
- 验证 PPIO API 连接
- 写入 Claude Code 配置文件（`~/.claude/.env` + `settings.json`）
- 支持 10+ 内置模型 + 自定义模型

## 支持的模型

| 模型 | ID |
|------|----|
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

## 技术栈

- Electron 33+
- React 19 + Vite
- TypeScript
- Lucide Icons

## 开发

```bash
npm install
npm run dev
```

## 打包

```bash
npm run build
```

输出：`release/PP Claude Installer Setup.exe`

## 项目结构

```
electron/          # Electron 主进程 + 服务层
  main.ts          # 窗口创建 + IPC
  preload.ts       # contextBridge
  services/        # shell/dependency/config/validator
src/               # React 渲染进程
  components/      # PageLayout, StepIndicator
  pages/           # 8 个安装步骤页面
  styles/          # 全局样式
```
