import { useRef, useEffect } from 'react'
import { PageLayout } from '../components/PageLayout'
import { useAppState, useDispatch } from '../store'
import { UrlMode, URL_PRESETS } from '../types'

const URL_OPTIONS: { mode: UrlMode; label: string; url?: string }[] = [
  { mode: 'ppio', label: 'PPIO', url: URL_PRESETS.ppio },
  { mode: 'aiproxy', label: 'AI Proxy', url: URL_PRESETS.aiproxy },
  { mode: 'custom', label: '自定义' },
]

export function APIKeyInput() {
  const state = useAppState()
  const dispatch = useDispatch()
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  function setUrlMode(mode: UrlMode) {
    const baseUrl = mode === 'custom' ? '' : URL_PRESETS[mode]
    dispatch({ type: 'UPDATE', payload: { urlMode: mode, baseUrl } })
  }

  const isKeyValid = state.urlMode === 'ppio'
    ? state.apiKey.startsWith('sk_') && state.apiKey.length >= 20
    : state.apiKey.length >= 10

  const isUrlValid = state.urlMode === 'custom'
    ? state.baseUrl.startsWith('http') && state.baseUrl.length >= 10
    : true

  const canProceed = isKeyValid && isUrlValid

  return (
    <PageLayout
      title={
        <div>
          <div style={{ fontSize: 16, fontWeight: 500 }}>API 配置</div>
          <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 4 }}>
            选择服务端点并输入 API Key
          </div>
        </div>
      }
      content={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* URL Mode Selector */}
          <div>
            <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginBottom: 8 }}>服务端点</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {URL_OPTIONS.map((opt) => (
                <button
                  key={opt.mode}
                  onClick={() => setUrlMode(opt.mode)}
                  style={{
                    flex: 1, padding: '6px 0', fontSize: 12, borderRadius: 6, cursor: 'pointer',
                    border: state.urlMode === opt.mode
                      ? '1px solid var(--color-primary)'
                      : '0.5px solid var(--color-border)',
                    background: state.urlMode === opt.mode
                      ? 'rgba(99,102,241,0.08)'
                      : 'var(--color-surface)',
                    color: state.urlMode === opt.mode
                      ? 'var(--color-primary)'
                      : 'var(--color-secondary)',
                    fontWeight: state.urlMode === opt.mode ? 500 : 400,
                  }}
                >
                  {opt.label}
                </button>
              ))}
            </div>
            {/* Show preset URL */}
            {state.urlMode !== 'custom' && (
              <div style={{ fontSize: 10, color: 'var(--color-tertiary)', marginTop: 6, fontFamily: 'var(--font-mono)' }}>
                {state.baseUrl}
              </div>
            )}
            {/* Custom URL input */}
            {state.urlMode === 'custom' && (
              <input
                type="text"
                placeholder="https://your-proxy.example.com"
                value={state.baseUrl}
                onChange={(e) => dispatch({ type: 'UPDATE', payload: { baseUrl: e.target.value } })}
                style={{
                  width: '100%', padding: '6px 10px', fontSize: 12, marginTop: 8,
                  fontFamily: 'var(--font-mono)', borderRadius: 6,
                  border: '0.5px solid var(--color-border)',
                  background: 'var(--color-surface)',
                }}
              />
            )}
          </div>

          {/* API Key Input */}
          <div>
            <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginBottom: 8 }}>API Key</div>
            <input
              ref={inputRef}
              type="password"
              placeholder={state.urlMode === 'ppio' ? 'sk_...' : 'your-api-key'}
              value={state.apiKey}
              onChange={(e) => dispatch({ type: 'UPDATE', payload: { apiKey: e.target.value } })}
              style={{
                width: '100%', padding: '8px 12px', fontSize: 14,
                fontFamily: 'var(--font-mono)', borderRadius: 6,
                border: '0.5px solid var(--color-border)',
                background: 'var(--color-surface)',
              }}
            />
            {state.apiKey && !isKeyValid && (
              <div style={{ fontSize: 11, color: 'rgba(239,68,68,0.8)', marginTop: 6 }}>
                {state.urlMode === 'ppio'
                  ? 'API Key 需以 "sk_" 开头，且长度不少于 20 位'
                  : 'API Key 长度不少于 10 位'}
              </div>
            )}
          </div>
        </div>
      }
      actions={
        <div style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
          <button className="btn-secondary" onClick={() => dispatch({ type: 'GO_BACK' })}>上一步</button>
          <button className="btn-primary" disabled={!canProceed} onClick={() => dispatch({ type: 'GO_NEXT' })}>
            继续
          </button>
        </div>
      }
    />
  )
}
