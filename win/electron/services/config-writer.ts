import fs from 'fs'
import path from 'path'
import os from 'os'
import { runCommand } from './shell'

const CLAUDE_DIR = path.join(os.homedir(), '.claude')
const ENV_FILE = path.join(CLAUDE_DIR, '.env')
const SETTINGS_FILE = path.join(CLAUDE_DIR, 'settings.json')

export interface ConflictingExport {
  variable: string
  source: string
}

export async function writeConfig(apiKey: string, modelID: string, baseUrl: string): Promise<{ success: boolean; error?: string }> {
  try {
    if (!fs.existsSync(CLAUDE_DIR)) {
      fs.mkdirSync(CLAUDE_DIR, { recursive: true })
    }

    // Backup existing .env
    if (fs.existsSync(ENV_FILE)) {
      fs.copyFileSync(ENV_FILE, ENV_FILE + '.backup')
    }

    const envContent = [
      `ANTHROPIC_BASE_URL=${baseUrl}`,
      `ANTHROPIC_AUTH_TOKEN=${apiKey}`,
      `ANTHROPIC_MODEL=${modelID}`,
      `ANTHROPIC_SMALL_FAST_MODEL=${modelID}`,
      `CLAUDE_CODE_SKIP_AUTH_LOGIN=1`,
    ].join('\n') + '\n'

    fs.writeFileSync(ENV_FILE, envContent, 'utf-8')

    // Write Windows user environment variables (persistent across sessions)
    const envVars: Record<string, string> = {
      ANTHROPIC_BASE_URL: baseUrl,
      ANTHROPIC_AUTH_TOKEN: apiKey,
      ANTHROPIC_MODEL: modelID,
      ANTHROPIC_SMALL_FAST_MODEL: modelID,
      CLAUDE_CODE_SKIP_AUTH_LOGIN: '1',
    }
    for (const [key, value] of Object.entries(envVars)) {
      await runCommand(`[Environment]::SetEnvironmentVariable('${key}', '${value}', 'User')`)
    }
    // Broadcast WM_SETTINGCHANGE so new processes pick up the env vars immediately
    await runCommand(
      `Add-Type -TypeDefinition @"\nusing System; using System.Runtime.InteropServices;\npublic class WinEnv {\n  [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);\n}\n"@\n$r=[UIntPtr]::Zero; [WinEnv]::SendMessageTimeout([IntPtr]0xFFFF,0x001A,[UIntPtr]::Zero,"Environment",2,5000,[ref]$r)`
    )

    // Always write settings.json with model config (merge with existing)
    let settings: Record<string, any> = {}
    if (fs.existsSync(SETTINGS_FILE)) {
      try {
        settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, 'utf-8'))
      } catch { /* overwrite if corrupt */ }
    }
    settings.model = modelID
    settings.smallModel = modelID
    settings.skipDangerousModePermissionPrompt = true
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2) + '\n', 'utf-8')

    return { success: true }
  } catch (err: any) {
    return { success: false, error: err.message }
  }
}

export async function detectConflicts(): Promise<ConflictingExport[]> {
  const conflicts: ConflictingExport[] = []
  const vars = [
    'ANTHROPIC_BASE_URL',
    'ANTHROPIC_API_KEY',
    'ANTHROPIC_AUTH_TOKEN',
    'ANTHROPIC_MODEL',
    'ANTHROPIC_SMALL_FAST_MODEL',
    'CLAUDE_CODE_SKIP_AUTH_LOGIN',
  ]

  // Check Windows user environment variables
  const result = await runCommand('reg query "HKCU\\Environment" 2>$null')
  if (result.exitCode === 0) {
    for (const v of vars) {
      if (result.output.includes(v)) {
        conflicts.push({ variable: v, source: 'Windows 用户环境变量' })
      }
    }
  }

  // Check system environment variables
  const sysResult = await runCommand('reg query "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" 2>$null')
  if (sysResult.exitCode === 0) {
    for (const v of vars) {
      if (sysResult.output.includes(v)) {
        conflicts.push({ variable: v, source: 'Windows 系统环境变量' })
      }
    }
  }

  return conflicts
}
