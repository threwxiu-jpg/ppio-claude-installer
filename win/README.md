# PP Claude Installer (Windows)

一键配置 Claude Code 使用 PPIO API 的 Windows 安装向导。

## 功能

- 自动检测并安装 Git、Node.js、npm、Claude Code CLI
- 支持 PPIO / AI Proxy / 自定义 API 端点
- 验证 API 连接后再写入配置
- Git 镜像加速（npmmirror CDN，国内约快 19 倍）
- 错误信息中的链接可直接点击打开浏览器
- 写入 Claude Code 配置文件（`~/.claude/.env` + `settings.json`）

## 支持的服务商与模型

### PPIO

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

### AI Proxy (`https://apiproxy.paigod.work/v1`)

| 模型 | ID |
|------|----|
| Claude Opus 4.6 | `pa/claude-opus-4-6` |
| Claude Sonnet 4.6 | `pa/claude-sonnet-4-6` |
| Claude Haiku 4.5 | `pa/claude-haiku-4-5-20251001` |
| DeepSeek V3.2 | `deepseek/deepseek-v3.2` |
| DeepSeek R1 | `deepseek/deepseek-r1-0528` |
| MiniMax M2.5 | `minimax/minimax-m2.5` |
| Doubao Seed 1.6 | `pa/doubao-seed-1.6` |

所有模式均支持手动输入自定义模型 ID。

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
  services/        # shell/dependency/config/validator/doctor
src/               # React 渲染进程
  components/      # PageLayout, StepIndicator
  pages/           # 8 个安装步骤页面
  styles/          # 全局样式
```

## Changelog

### v1.1.0
- Git 安装新增镜像加速（npmmirror CDN，选镜像模式时生效，国内约快 19 倍）
- AI Proxy 端点更新为 `https://apiproxy.paigod.work/v1`
- PPIO 和 AI Proxy 使用独立预设模型列表
- 自定义模式新增独立模型 ID 输入框
- PPIO / AI Proxy 模型选择页新增手动输入栏（直接输入即激活，点击预设自动清空）
- 依赖安装失败的错误信息中 URL 现在可点击直接打开浏览器

### v1.0.0
- 初始发布
