export type Step =
  | 'welcome'
  | 'dependencyCheck'
  | 'networkSelection'
  | 'apiKeyInput'
  | 'modelSelection'
  | 'validation'
  | 'installConfig'
  | 'completion'

export const STEPS: Step[] = [
  'welcome',
  'networkSelection',
  'dependencyCheck',
  'apiKeyInput',
  'modelSelection',
  'validation',
  'installConfig',
  'completion',
]

export type DependencyStatus = 'unchecked' | 'checking' | 'installed' | 'missing' | 'installing' | 'failed'
export type ValidationStatus = 'idle' | 'validating' | 'success' | 'failed'
export type InstallStatus = 'idle' | 'installing' | 'success' | 'failed'

export interface DependencyItem {
  id: string
  name: string
  status: DependencyStatus
  version?: string
  error?: string
}

export interface PPIOModel {
  id: string
  displayName: string
}

export const BUILTIN_MODELS: PPIOModel[] = [
  { id: 'pa/claude-opus-4-6', displayName: 'Claude Opus 4.6' },
  { id: 'pa/claude-sonnet-4-6', displayName: 'Claude Sonnet 4.6' },
  { id: 'pa/gt-4.1', displayName: 'GPT-4.1' },
  { id: 'pa/gt-4.1-m', displayName: 'GPT-4.1 Mini' },
  { id: 'pa/gmn-2.5-fls', displayName: 'Gemini 2.5 Flash' },
  { id: 'deepseek/deepseek-v3.2', displayName: 'DeepSeek V3.2' },
  { id: 'deepseek/deepseek-r1-0528', displayName: 'DeepSeek R1' },
  { id: 'pa/grk-4', displayName: 'Grok 4' },
  { id: 'minimax/minimax-m2.1', displayName: 'MiniMax M2.1' },
  { id: 'pa/doubao-seed-1.6', displayName: 'Doubao Seed 1.6' },
]

export interface ConflictingExport {
  variable: string
  source: string
}

export interface DiagnosticResult {
  name: string
  level: 'critical' | 'optional'
  status: 'pass' | 'fail' | 'warn'
  message: string
}

export type DiagnosticStatus = 'idle' | 'running' | 'done'

export type UrlMode = 'ppio' | 'aiproxy' | 'custom'

export const URL_PRESETS: Record<Exclude<UrlMode, 'custom'>, string> = {
  ppio: 'https://api.ppio.com/anthropic',
  aiproxy: 'https://apiproxy.paigod.work',
}

export interface AppState {
  step: Step
  dependencies: DependencyItem[]
  useMirror: boolean
  networkChecked: boolean
  networkSlow: boolean
  needsInstall: boolean
  urlMode: UrlMode
  baseUrl: string
  apiKey: string
  selectedModelId: string
  useCustomModel: boolean
  customModelId: string
  validationStatus: ValidationStatus
  validationError?: string
  conflicts: ConflictingExport[]
  conflictsAcknowledged: boolean
  installStatus: InstallStatus
  installError?: string
}

export const initialState: AppState = {
  step: 'welcome',
  dependencies: [
    { id: 'git', name: 'Git (含 Git Bash)', status: 'unchecked' },
    { id: 'nodejs', name: 'Node.js (≥18)', status: 'unchecked' },
    { id: 'npm', name: 'npm', status: 'unchecked' },
    { id: 'claude-cli', name: 'Claude Code CLI', status: 'unchecked' },
  ],
  useMirror: false,
  networkChecked: false,
  networkSlow: false,
  needsInstall: false,
  urlMode: 'ppio',
  baseUrl: 'https://api.ppio.com/anthropic',
  apiKey: '',
  selectedModelId: 'pa/claude-sonnet-4-6',
  useCustomModel: false,
  customModelId: '',
  validationStatus: 'idle',
  validationError: undefined,
  conflicts: [],
  conflictsAcknowledged: false,
  installStatus: 'idle',
  installError: undefined,
}

// Electron API type
declare global {
  interface Window {
    electronAPI: {
      runCommand: (command: string) => Promise<{ exitCode: number; output: string; error: string }>
      checkDependency: (id: string) => Promise<{ installed: boolean; version?: string }>
      installDependency: (id: string, useMirror: boolean) => Promise<{ success: boolean; error?: string }>
      checkNetworkSpeed: () => Promise<boolean>
      validateAPI: (apiKey: string, modelID: string, baseUrl: string) => Promise<{ success: boolean; error?: string }>
      writeConfig: (apiKey: string, modelID: string, baseUrl: string) => Promise<{ success: boolean; error?: string }>
      detectConflicts: () => Promise<ConflictingExport[]>
      runDiagnostics: (apiKey: string, modelID: string, baseUrl: string) => Promise<DiagnosticResult[]>
      openPowerShell: () => Promise<boolean>
      quitApp: () => Promise<void>
      onInstallProgress: (cb: (data: { id: string; line: string }) => void) => () => void
    }
  }
}
