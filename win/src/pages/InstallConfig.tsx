import { useEffect } from 'react'
import { CheckCircle, XCircle, AlertTriangle, Loader } from 'lucide-react'
import { PageLayout } from '../components/PageLayout'
import { useAppState, useDispatch } from '../store'

export function InstallConfig() {
  const state = useAppState()
  const dispatch = useDispatch()

  const effectiveModelId = state.useCustomModel ? state.customModelId : state.selectedModelId

  useEffect(() => {
    checkAndInstall()
  }, [])

  async function checkAndInstall() {
    try {
      const conflicts = await window.electronAPI.detectConflicts()
      dispatch({ type: 'UPDATE', payload: { conflicts } })
      if (conflicts.length === 0) await install()
    } catch {
      await install()
    }
  }

  async function install() {
    dispatch({ type: 'UPDATE', payload: { installStatus: 'installing', installError: undefined } })
    try {
      const result = await window.electronAPI.writeConfig(state.apiKey, effectiveModelId, state.baseUrl)
      dispatch({
        type: 'UPDATE',
        payload: {
          installStatus: result.success ? 'success' : 'failed',
          installError: result.error,
        },
      })
    } catch (err: any) {
      dispatch({ type: 'UPDATE', payload: { installStatus: 'failed', installError: err.message } })
    }
  }

  // Conflict warning
  if (state.conflicts.length > 0 && !state.conflictsAcknowledged) {
    return (
      <PageLayout
        title={
          <div>
            <div style={{ fontSize: 16, fontWeight: 500 }}>安装配置</div>
            <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 4 }}>
              写入 Claude Code 配置文件
            </div>
          </div>
        }
        content={
          <div style={{ textAlign: 'center', display: 'flex', flexDirection: 'column', gap: 16, alignItems: 'center' }}>
            <AlertTriangle size={28} color="var(--color-warning)" />
            <div style={{ fontSize: 13, fontWeight: 500 }}>检测到已有配置</div>
            <div style={{ fontSize: 11, color: 'var(--color-secondary)' }}>
              以下环境变量可能覆盖新配置，建议先清除。
            </div>
            <div style={{ display: 'flex', alignItems: 'stretch', gap: 0 }}>
              <div style={{ width: 2, borderRadius: 1, background: 'var(--color-warning)', opacity: 0.6 }} />
              <div style={{ paddingLeft: 10, display: 'flex', flexDirection: 'column', gap: 4 }}>
                {state.conflicts.map((c, i) => (
                  <div key={i} style={{ display: 'flex', gap: 4, fontSize: 10, fontFamily: 'var(--font-mono)' }}>
                    <span style={{ color: 'var(--color-secondary)' }}>{c.source}:</span>
                    <span style={{ color: 'var(--color-warning)' }}>{c.variable}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        }
        actions={
          <div style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
            <button className="btn-secondary" onClick={async () => {
              const conflicts = await window.electronAPI.detectConflicts()
              dispatch({ type: 'UPDATE', payload: { conflicts } })
            }}>
              重新检测
            </button>
            <button className="btn-primary" onClick={() => {
              dispatch({ type: 'UPDATE', payload: { conflictsAcknowledged: true } })
              install()
            }}>
              仍然继续
            </button>
          </div>
        }
      />
    )
  }

  return (
    <PageLayout
      title={
        <div>
          <div style={{ fontSize: 16, fontWeight: 500 }}>安装配置</div>
          <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 4 }}>
            写入 Claude Code 配置文件
          </div>
        </div>
      }
      content={
        <div style={{ textAlign: 'center' }}>
          {(state.installStatus === 'idle' || state.installStatus === 'installing') && (
            <>
              <Loader size={24} color="var(--color-secondary)" style={{ animation: 'spin 1s linear infinite' }} />
              <div style={{ fontSize: 13, color: 'var(--color-secondary)', marginTop: 12 }}>正在写入配置...</div>
            </>
          )}
          {state.installStatus === 'success' && (
            <>
              <CheckCircle size={32} color="var(--color-success)" />
              <div style={{ fontSize: 13, fontWeight: 500, marginTop: 8 }}>配置保存成功</div>
              <div style={{
                display: 'flex', flexDirection: 'column', gap: 6, marginTop: 16,
                fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-secondary)',
              }}>
                <span>~/.claude/.env</span>
                <span>~/.claude/settings.json</span>
              </div>
            </>
          )}
          {state.installStatus === 'failed' && (
            <>
              <XCircle size={32} color="var(--color-error)" />
              <div style={{ fontSize: 13, fontWeight: 500, marginTop: 8 }}>配置写入失败</div>
              {state.installError && (
                <div style={{ fontSize: 11, color: 'var(--color-secondary)', marginTop: 4 }}>{state.installError}</div>
              )}
            </>
          )}
          <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
        </div>
      }
      actions={
        <div style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
          {state.installStatus === 'success' && (
            <button className="btn-primary" onClick={() => dispatch({ type: 'GO_NEXT' })}>完成</button>
          )}
          {state.installStatus === 'failed' && (
            <>
              <button className="btn-secondary" onClick={() => dispatch({ type: 'GO_BACK' })}>上一步</button>
              <button className="btn-bordered" onClick={install}>重试</button>
            </>
          )}
        </div>
      }
    />
  )
}
