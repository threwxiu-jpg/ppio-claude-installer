import { useEffect } from 'react'
import { PageLayout } from '../components/PageLayout'
import { useAppState, useDispatch } from '../store'
import { PPIO_MODELS, AIPROXY_MODELS } from '../types'

export function ModelSelection() {
  const state = useAppState()
  const dispatch = useDispatch()
  const isCustomMode = state.urlMode === 'custom'

  // Custom URL mode always uses a manual model input
  useEffect(() => {
    if (isCustomMode) {
      dispatch({ type: 'UPDATE', payload: { useCustomModel: true } })
    }
  }, [isCustomMode])

  const models = state.urlMode === 'aiproxy' ? AIPROXY_MODELS : PPIO_MODELS

  const canContinue = isCustomMode
    ? state.customModelId.trim() !== ''
    : !state.useCustomModel || state.customModelId.trim() !== ''

  if (isCustomMode) {
    return (
      <PageLayout
        title={
          <div>
            <div style={{ fontSize: 16, fontWeight: 500 }}>选择模型</div>
            <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 4 }}>
              输入自定义服务使用的模型 ID
            </div>
          </div>
        }
        content={
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={{ fontSize: 12, color: 'var(--color-secondary)' }}>模型 ID</div>
            <input
              autoFocus
              placeholder="e.g. claude-3-5-sonnet-20241022"
              value={state.customModelId}
              onChange={(e) => dispatch({
                type: 'UPDATE',
                payload: { customModelId: e.target.value, useCustomModel: true },
              })}
              style={{
                width: '100%', padding: '8px 12px', fontSize: 13,
                fontFamily: 'var(--font-mono)', borderRadius: 6,
                border: '0.5px solid var(--color-border)',
                background: 'var(--color-surface)',
              }}
            />
            <div style={{ fontSize: 11, color: 'var(--color-tertiary)' }}>
              请输入自定义服务支持的模型名称
            </div>
          </div>
        }
        actions={
          <div style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
            <button className="btn-secondary" onClick={() => dispatch({ type: 'GO_BACK' })}>上一步</button>
            <button className="btn-primary" disabled={!canContinue} onClick={() => dispatch({ type: 'GO_NEXT' })}>
              继续
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
          <div style={{ fontSize: 16, fontWeight: 500 }}>选择模型</div>
          <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 4 }}>
            Claude Code 默认使用的 AI 模型
          </div>
        </div>
      }
      content={
        <div style={{ maxWidth: 440, maxHeight: 240, overflowY: 'auto' }}>
          {models.map((model) => {
            const selected = !state.useCustomModel && state.selectedModelId === model.id
            return (
              <button key={model.id} onClick={() => dispatch({
                type: 'UPDATE',
                payload: { selectedModelId: model.id, useCustomModel: false, customModelId: '' },
              })} style={{
                width: '100%', display: 'flex', alignItems: 'stretch',
                border: 'none', background: selected ? 'var(--color-primary-bg)' : 'transparent',
                borderRadius: 6, cursor: 'pointer', padding: 0, transition: 'background 0.15s',
              }}>
                <div style={{
                  width: 2, borderRadius: 1, margin: '4px 0',
                  background: selected ? 'var(--color-primary)' : 'transparent',
                  transition: 'background 0.15s',
                }} />
                <div style={{ padding: '6px 10px', display: 'flex', flexDirection: 'column', alignItems: 'flex-start' }}>
                  <span style={{ fontSize: 13 }}>{model.displayName}</span>
                  <span style={{ fontSize: 10, color: 'var(--color-tertiary)', fontFamily: 'var(--font-mono)' }}>{model.id}</span>
                </div>
              </button>
            )
          })}

          <div style={{ height: 0.5, background: 'var(--color-border)', margin: '8px 0' }} />

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '4px 4px 0' }}>
            <span style={{ fontSize: 12, color: 'var(--color-secondary)', flexShrink: 0, whiteSpace: 'nowrap' }}>手动输入：</span>
            <input
              placeholder="e.g. pa/my-model"
              value={state.customModelId}
              onChange={(e) => {
                const val = e.target.value
                dispatch({ type: 'UPDATE', payload: { customModelId: val, useCustomModel: val.trim() !== '' } })
              }}
              style={{
                flex: 1, padding: '4px 8px', fontSize: 11,
                fontFamily: 'var(--font-mono)', borderRadius: 4,
                border: `0.5px solid ${state.useCustomModel ? 'var(--color-primary)' : 'var(--color-border)'}`,
                background: 'var(--color-surface)',
              }}
            />
          </div>
        </div>
      }
      actions={
        <div style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
          <button className="btn-secondary" onClick={() => dispatch({ type: 'GO_BACK' })}>上一步</button>
          <button className="btn-primary" disabled={!canContinue} onClick={() => dispatch({ type: 'GO_NEXT' })}>
            继续
          </button>
        </div>
      }
    />
  )
}
