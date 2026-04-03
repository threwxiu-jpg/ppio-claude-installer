import fs from 'fs'
import path from 'path'
import os from 'os'
import { runCommand, runCommandWithProgress } from './shell'

// Common paths where npm.cmd lives on Windows
const COMMON_NPM_PATHS = [
  'C:\\Program Files\\nodejs\\npm.cmd',
  'C:\\Program Files (x86)\\nodejs\\npm.cmd',
  path.join(os.homedir(), 'AppData', 'Roaming', 'npm', 'npm.cmd'),
]

async function findNpm(): Promise<string | null> {
  // Try PATH first (shell.ts already injects extra paths)
  const result = await runCommand('where.exe npm.cmd 2>$null')
  if (result.exitCode === 0 && result.output.trim()) {
    return result.output.trim().split('\n')[0].trim()
  }
  // Try known locations
  for (const p of COMMON_NPM_PATHS) {
    if (fs.existsSync(p)) return p
  }
  return null
}

const COMMON_GIT_PATHS = [
  'C:\\Program Files\\Git\\bin\\bash.exe',
  'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
  path.join(os.homedir(), 'AppData', 'Local', 'Programs', 'Git', 'bin', 'bash.exe'),
]

export async function checkDependency(id: string): Promise<{ installed: boolean; version?: string }> {
  switch (id) {
    case 'git': {
      const result = await runCommand('git --version')
      if (result.exitCode === 0) {
        const ver = result.output.replace('git version ', '').trim()
        // Also verify bash.exe exists
        const bashCheck = await runCommand('where.exe bash.exe 2>$null')
        if (bashCheck.exitCode === 0) return { installed: true, version: ver }
        // Check common paths
        for (const p of COMMON_GIT_PATHS) {
          if (fs.existsSync(p)) return { installed: true, version: ver }
        }
        return { installed: true, version: ver + ' (bash 未在 PATH)' }
      }
      // Check common paths
      for (const p of COMMON_GIT_PATHS) {
        if (fs.existsSync(p)) {
          return { installed: true, version: 'Git Bash found' }
        }
      }
      return { installed: false }
    }
    case 'nodejs': {
      const result = await runCommand('node --version')
      if (result.exitCode === 0) {
        const ver = result.output.replace('v', '').trim()
        const major = parseInt(ver.split('.')[0], 10)
        if (major >= 18) return { installed: true, version: ver }
      }
      return { installed: false }
    }
    case 'npm': {
      // First try via PATH (enhanced in shell.ts)
      const result = await runCommand('npm --version')
      if (result.exitCode === 0) return { installed: true, version: result.output.trim() }
      // Try known absolute paths
      const npmPath = await findNpm()
      if (npmPath) {
        const r2 = await runCommand(`& "${npmPath}" --version`)
        if (r2.exitCode === 0) return { installed: true, version: r2.output.trim() }
      }
      return { installed: false }
    }
    case 'claude-cli': {
      const result = await runCommand('claude --version')
      if (result.exitCode === 0) return { installed: true, version: result.output.trim() }
      // Try known absolute paths
      const claudePaths = [
        path.join(os.homedir(), 'AppData', 'Roaming', 'npm', 'claude.cmd'),
        path.join(os.homedir(), '.npm-global', 'claude.cmd'),
      ]
      for (const p of claudePaths) {
        if (fs.existsSync(p)) {
          const r2 = await runCommand(`& "${p}" --version`)
          if (r2.exitCode === 0) return { installed: true, version: r2.output.trim() }
        }
      }
      return { installed: false }
    }
    default:
      return { installed: false }
  }
}

export async function installDependency(id: string, useMirror: boolean, onProgress?: (line: string) => void): Promise<{ success: boolean; error?: string }> {
  const run = onProgress
    ? (cmd: string, timeoutMs?: number) => runCommandWithProgress(cmd, onProgress, timeoutMs)
    : runCommand

  switch (id) {
    case 'git': {
      const result = await run('winget install Git.Git --accept-source-agreements --accept-package-agreements', 600000)
      if (result.exitCode === 0) return { success: true }
      return { success: false, error: result.error || 'Git 安装失败。请手动从 https://git-scm.com/downloads/win 下载安装' }
    }
    case 'nodejs': {
      const result = await run('winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements', 600000)
      if (result.exitCode === 0) return { success: true }
      return { success: false, error: result.error || 'Node.js 安装失败。请手动从 https://nodejs.org 下载安装' }
    }
    case 'npm': {
      // npm ships with Node.js — try to find it in known paths
      const npmPath = await findNpm()
      if (npmPath) {
        // npm exists but wasn't in PATH; verify it works
        const r = await runCommand(`& "${npmPath}" --version`)
        if (r.exitCode === 0) {
          return { success: true }
        }
      }
      // npm truly not found — need Node.js reinstall
      const nodeCheck = await runCommand('node --version')
      if (nodeCheck.exitCode === 0) {
        return {
          success: false,
          error: 'Node.js 已安装但 npm 未找到。请重新安装 Node.js（确保勾选 npm），然后重启本安装器',
        }
      }
      return { success: false, error: '请先安装 Node.js（npm 随 Node.js 一起安装）' }
    }
    case 'claude-cli': {
      // Find npm first
      let npmCmd = 'npm'
      const npmPath = await findNpm()
      if (npmPath) npmCmd = `& "${npmPath}"`

      const registryFlag = useMirror
        ? ' --registry https://registry.npmmirror.com'
        : ''
      const result = await run(`${npmCmd} install -g @anthropic-ai/claude-code${registryFlag}`)
      if (result.exitCode === 0) return { success: true }

      // Check for common errors
      const errMsg = result.error || result.output || ''
      if (errMsg.includes('EPERM') || errMsg.includes('permission') || errMsg.includes('access')) {
        return { success: false, error: '权限不足。请以管理员身份运行安装器，或手动执行: npm install -g @anthropic-ai/claude-code' }
      }
      if (errMsg.includes('ECONNRESET') || errMsg.includes('ETIMEDOUT') || errMsg.includes('network')) {
        return { success: false, error: '网络错误。请检查网络连接后重试，或返回上一步选择镜像加速' }
      }
      return { success: false, error: errMsg.slice(0, 200) || 'Claude CLI 安装失败' }
    }
    default:
      return { success: false, error: '未知依赖' }
  }
}

export async function checkNetworkSpeed(): Promise<boolean> {
  try {
    const result = await runCommand(
      `$sw = [System.Diagnostics.Stopwatch]::StartNew(); ` +
      `try { (Invoke-WebRequest -Uri 'https://registry.npmjs.org' -Method HEAD -TimeoutSec 5 -UseBasicParsing).StatusCode } ` +
      `catch { 0 }; ` +
      `$sw.Stop(); $sw.ElapsedMilliseconds`
    )
    const ms = parseInt(result.output.split('\n').pop()?.trim() || '9999', 10)
    return ms > 3000 // true = slow
  } catch {
    return true
  }
}
