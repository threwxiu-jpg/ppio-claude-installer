import { useState } from 'react'
import { PartyPopper, CheckCircle2, XCircle, AlertTriangle } from 'lucide-react'
import { PageLayout } from '../components/PageLayout'
import { useAppState } from '../store'
import type { DiagnosticResult, DiagnosticStatus } from '../types'

const steps = [
  { num: '1', text: '打开 PowerShell' },
  { num: '2', text: '输入', code: 'claude', suffix: '并回车' },
  { num: '3', text: '开始用 AI 写代码吧！' },
]

export function Completion() {
  const state = useAppState()
  const [diagStatus, setDiagStatus] = useState<DiagnosticStatus>('idle')
  const [diagResults, setDiagResults] = useState<DiagnosticResult[]>([])

  const effectiveModelId = state.useCustomModel && state.customModelId
    ? state.customModelId
    : state.selectedModelId

  async function runDiag() {
    setDiagStatus('running')
    try {
      const results = await window.electronAPI.runDiagnostics(state.apiKey, effectiveModelId, state.baseUrl)
      setDiagResults(results)
    } catch (err: any) {
      setDiagResults([{ name: '诊断失败', level: 'critical', status: 'fail', message: err.message || '未知错误' }])
    }
    setDiagStatus('done')
  }

  const criticals = diagResults.filter(r => r.level === 'critical')
  const optionals = diagResults.filter(r => r.level === 'optional')
  const critFail = criticals.filter(r => r.status === 'fail').length

  return (
    <PageLayout
      title={
        <div>
          <div style={{ fontSize: 16, fontWeight: 500 }}>配置完成</div>
          <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 4 }}>
            Claude Code 已准备就绪
          </div>
        </div>
      }
      content={
        diagStatus === 'done' ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {/* Summary */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, justifyContent: 'center' }}>
              {critFail === 0 ? (
                <><CheckCircle2 size={18} color="#22c55e" /><span style={{ fontSize: 13, fontWeight: 500 }}>核心配置正常</span></>
              ) : (
                <><XCircle size={18} color="#ef4444" /><span style={{ fontSize: 13, fontWeight: 500 }}>{critFail} 个必须项需修复</span></>
              )}
            </div>
            {/* Results */}
            <div style={{ maxHeight: 200, overflow: 'auto', fontSize: 11 }}>
              {criticals.length > 0 && (
                <>
                  <div style={{ color: 'var(--color-secondary)', fontFamily: 'var(--font-mono)', marginBottom: 4 }}>必须</div>
                  {criticals.map((r, i) => <DiagRow key={i} item={r} />)}
                </>
              )}
              {optionals.length > 0 && (
                <>
                  <div style={{ color: 'var(--color-secondary)', fontFamily: 'var(--font-mono)', marginTop: 8, marginBottom: 4 }}>可选</div>
                  {optionals.map((r, i) => <DiagRow key={i} item={r} />)}
                </>
              )}
            </div>
          </div>
        ) : diagStatus === 'running' ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
            <div className="spinner" />
            <span style={{ fontSize: 13, color: 'var(--color-secondary)' }}>正在检查环境...</span>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20 }}>
            <PartyPopper size={36} color="var(--color-secondary)" />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {steps.map((s) => (
                <div key={s.num} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-secondary)', width: 18, textAlign: 'right' }}>
                    {s.num}.
                  </span>
                  <span style={{ fontSize: 13 }}>{s.text}</span>
                  {s.code && (
                    <span style={{
                      fontSize: 13, fontFamily: 'var(--font-mono)',
                      padding: '2px 6px', borderRadius: 4,
                      background: 'rgba(0,0,0,0.04)',
                    }}>
                      {s.code}
                    </span>
                  )}
                  {s.suffix && <span style={{ fontSize: 13 }}>{s.suffix}</span>}
                </div>
              ))}
            </div>
          </div>
        )
      }
      actions={
        <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
          <button className="btn-secondary" onClick={() => window.electronAPI.quitApp()}>退出</button>
          {diagStatus === 'done' ? (
            <button className="btn-secondary" onClick={runDiag}>重新检查</button>
          ) : diagStatus !== 'running' ? (
            <button className="btn-secondary" onClick={runDiag}>环境诊断</button>
          ) : null}
          <button className="btn-primary" onClick={() => window.electronAPI.openPowerShell()}>
            打开 PowerShell
          </button>
        </div>
      }
    />
  )
}

function DiagRow({ item }: { item: DiagnosticResult }) {
  const Icon = item.status === 'pass' ? CheckCircle2 : item.status === 'fail' ? XCircle : AlertTriangle
  const color = item.status === 'pass' ? '#22c55e' : item.status === 'fail' ? '#ef4444' : '#eab308'
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '2px 0' }}>
      <Icon size={12} color={color} />
      <span style={{ fontFamily: 'var(--font-mono)', width: 140, flexShrink: 0 }}>{item.name}</span>
      <span style={{ color: 'var(--color-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.message}</span>
    </div>
  )
}
