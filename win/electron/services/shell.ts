import { spawn } from 'child_process'
import path from 'path'
import os from 'os'

export interface ShellResult {
  exitCode: number
  output: string
  error: string
}

const EXTRA_PATHS = [
  path.join(os.homedir(), 'AppData', 'Roaming', 'npm'),
  'C:\\Program Files\\nodejs',
  'C:\\Program Files (x86)\\nodejs',
  path.join(os.homedir(), '.npm-global'),
  path.join(os.homedir(), '.npm-global', 'bin'),
  'C:\\Program Files\\Git\\bin',
  'C:\\Program Files\\Git\\cmd',
  'C:\\Program Files (x86)\\Git\\bin',
]

export function runCommandWithProgress(
  command: string,
  onData: (line: string) => void,
  timeoutMs = 300000,
): Promise<ShellResult> {
  return new Promise((resolve) => {
    const env = { ...process.env }
    const currentPath = env.PATH || env.Path || ''
    const missing = EXTRA_PATHS.filter(p => !currentPath.includes(p))
    if (missing.length > 0) {
      env.PATH = missing.join(';') + ';' + currentPath
    }

    const utf8Prefix = '[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; '
    const proc = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', utf8Prefix + command], {
      windowsHide: true,
      env,
    })

    let stdout = ''
    let stderr = ''

    proc.stdout.on('data', (data) => {
      const text = data.toString()
      stdout += text
      const line = text.trim()
      if (line) onData(line)
    })
    proc.stderr.on('data', (data) => {
      const text = data.toString()
      stderr += text
      const line = text.trim()
      if (line) onData(line)
    })

    const timer = setTimeout(() => {
      proc.kill()
      resolve({ exitCode: 1, output: stdout.trim(), error: '安装超时（5分钟）' })
    }, timeoutMs)

    proc.on('close', (code) => {
      clearTimeout(timer)
      resolve({ exitCode: code ?? 1, output: stdout.trim(), error: stderr.trim() })
    })

    proc.on('error', (err) => {
      clearTimeout(timer)
      resolve({ exitCode: 1, output: '', error: err.message })
    })
  })
}

export function runCommand(command: string): Promise<ShellResult> {
  return new Promise((resolve) => {
    const env = { ...process.env }
    const currentPath = env.PATH || env.Path || ''
    const missing = EXTRA_PATHS.filter(p => !currentPath.includes(p))
    if (missing.length > 0) {
      env.PATH = missing.join(';') + ';' + currentPath
    }

    const utf8Prefix = '[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; '
    const proc = spawn('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', utf8Prefix + command], {
      windowsHide: true,
      env,
    })

    let stdout = ''
    let stderr = ''

    proc.stdout.on('data', (data) => { stdout += data.toString() })
    proc.stderr.on('data', (data) => { stderr += data.toString() })

    proc.on('close', (code) => {
      resolve({
        exitCode: code ?? 1,
        output: stdout.trim(),
        error: stderr.trim(),
      })
    })

    proc.on('error', (err) => {
      resolve({ exitCode: 1, output: '', error: err.message })
    })
  })
}
