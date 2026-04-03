import { PageLayout } from '../components/PageLayout'
import { useAppState, useDispatch } from '../store'
import { BUILTIN_MODELS } from '../types'

export function ModelSelection() {
  const state = useAppState()
  const dispatch = useDispatch()

  const canContinue = !state.useCustomModel || state.customModelId.trim() !== ''

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
          {BUILTIN_MODELS.map((model) => {
            const selected = !state.useCustomModel && state.selectedModelId === model.id
            return (
              <button key={model.id} onClick={() => dispatch({
                type: 'UPDATE',
                payload: { selectedModelId: model.id, useCustomModel: false },
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

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '0 4px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
              <input
                type="checkbox"
                checked={state.useCustomModel}
                onChange={(e) => dispatch({ type: 'UPDATE', payload: { useCustomModel: e.target.checked } })}
              />
              自定义模型 ID：
            </label>
            <input
              placeholder="e.g. pa/my-model"
              value={state.customModelId}
              disabled={!state.useCustomModel}
              onChange={(e) => dispatch({ type: 'UPDATE', payload: { customModelId: e.target.value } })}
              style={{
                flex: 1, padding: '4px 8px', fontSize: 11,
                fontFamily: 'var(--font-mono)', borderRadius: 4,
                border: '0.5px solid var(--color-border)',
                background: state.useCustomModel ? 'white' : 'var(--color-surface)',
                opacity: state.useCustomModel ? 1 : 0.5,
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
