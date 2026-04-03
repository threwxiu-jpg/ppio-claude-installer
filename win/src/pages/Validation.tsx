import { useEffect } from 'react'
import { CheckCircle, XCircle, Loader } from 'lucide-react'
import { PageLayout } from '../components/PageLayout'
import { useAppState, useDispatch } from '../store'

export function Validation() {
  const state = useAppState()
  const dispatch = useDispatch()

  const effectiveModelId = state.useCustomModel ? state.customModelId : state.selectedModelId
  const maskedKey = state.apiKey.length > 10
    ? state.apiKey.slice(0, 6) + '...' + state.apiKey.slice(-4)
    : '***'

  useEffect(() => {
    validate()
  }, [])

  async function validate() {
    dispatch({ type: 'UPDATE', payload: { validationStatus: 'validating', validationError: undefined } })
    try {
      const result = await window.electronAPI.validateAPI(state.apiKey, effectiveModelId, state.baseUrl)
      dispatch({
        type: 'UPDATE',
        payload: {
          validationStatus: result.success ? 'success' : 'failed',
          validationError: result.error,
        },
      })
    } catch (err: any) {
      dispatch({
        type: 'UPDATE',
        payload: { validationStatus: 'failed', validationError: err.message },
      })
    }
  }

  return (
    <PageLayout
      title={
        <div>
          <div style={{ fontSize: 16, fontWeight: 500 }}>验证连接</div>
          <div style={{
            display: 'flex', gap: 8, justifyContent: 'center', marginTop: 4,
            fontSize: 11, color: 'var(--color-secondary)', fontFamily: 'var(--font-mono)',
          }}>
            <span>{maskedKey}</span>
            <span>·</span>
            <span>{effectiveModelId}</span>
          </div>
        </div>
      }
      content={
        <div style={{ textAlign: 'center' }}>
          {(state.validationStatus === 'idle' || state.validationStatus === 'validating') && (
            <>
              <Loader size={24} color="var(--color-secondary)" style={{ animation: 'spin 1s linear infinite' }} />
              <div style={{ fontSize: 13, color: 'var(--color-secondary)', marginTop: 12 }}>正在验证...</div>
            </>
          )}
          {state.validationStatus === 'success' && (
            <>
              <CheckCircle size={32} color="var(--color-success)" />
              <div style={{ fontSize: 13, fontWeight: 500, marginTop: 8 }}>连接验证成功</div>
            </>
          )}
          {state.validationStatus === 'failed' && (
            <>
              <XCircle size={32} color="var(--color-error)" />
              <div style={{ fontSize: 13, fontWeight: 500, marginTop: 8 }}>验证失败</div>
              {state.validationError && (
                <div style={{ fontSize: 11, color: 'var(--color-secondary)', marginTop: 4 }}>
                  {state.validationError}
                </div>
              )}
            </>
          )}
          <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
        </div>
      }
      actions={
        <div style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
          <button className="btn-secondary" onClick={() => dispatch({ type: 'GO_BACK' })}>上一步</button>
          {state.validationStatus === 'success' && (
            <button className="btn-primary" onClick={() => dispatch({ type: 'GO_NEXT' })}>继续</button>
          )}
          {state.validationStatus === 'failed' && (
            <button className="btn-bordered" onClick={validate}>重试</button>
          )}
        </div>
      }
    />
  )
}
