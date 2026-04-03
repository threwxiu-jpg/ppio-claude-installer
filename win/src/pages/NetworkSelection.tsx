import { useEffect, useState } from 'react'
import { Globe, Zap, CheckCircle, AlertCircle } from 'lucide-react'
import { PageLayout } from '../components/PageLayout'
import { useAppState, useDispatch } from '../store'

export function NetworkSelection() {
  const state = useAppState()
  const dispatch = useDispatch()
  const [checking, setChecking] = useState(true)

  useEffect(() => {
    checkNetwork()
  }, [])

  async function checkNetwork() {
    setChecking(true)
    try {
      const slow = await window.electronAPI.checkNetworkSpeed()
      dispatch({ type: 'UPDATE', payload: { networkSlow: slow, useMirror: slow } })
    } catch {
      dispatch({ type: 'UPDATE', payload: { networkSlow: true, useMirror: true } })
    }
    setChecking(false)
  }

  return (
    <PageLayout
      title={
        <div>
          <div style={{ fontSize: 16, fontWeight: 500 }}>网络环境</div>
          <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 4 }}>
            检测到有依赖需要安装
          </div>
        </div>
      }
      content={
        checking ? (
          <div style={{ textAlign: 'center' }}>
            <div className="spinner" />
            <div style={{ fontSize: 12, color: 'var(--color-secondary)', marginTop: 12 }}>正在测试网络连接...</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 20, alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--color-secondary)' }}>
              {state.networkSlow
                ? <><AlertCircle size={12} /> 网络连接较慢，建议使用镜像</>
                : <><CheckCircle size={12} /> 网络连接正常</>
              }
            </div>

            <div style={{ display: 'flex', gap: 12 }}>
              <NetworkCard
                title="直连安装" subtitle="官方源" icon={<Globe size={18} />}
                selected={!state.useMirror}
                onClick={() => dispatch({ type: 'UPDATE', payload: { useMirror: false } })}
              />
              <NetworkCard
                title="镜像加速" subtitle="npmmirror" icon={<Zap size={18} />}
                selected={state.useMirror}
                onClick={() => dispatch({ type: 'UPDATE', payload: { useMirror: true } })}
              />
            </div>

            <div style={{ fontSize: 11, color: 'var(--color-tertiary)' }}>
              仅在本次安装过程中生效，不修改全局配置
            </div>
          </div>
        )
      }
      actions={
        !checking ? (
          <div style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
            <button className="btn-secondary" onClick={() => dispatch({ type: 'GO_BACK' })}>上一步</button>
            <button className="btn-primary" onClick={() => {
              dispatch({ type: 'UPDATE', payload: { networkChecked: true } })
              dispatch({ type: 'GO_NEXT' })
            }}>
              继续
            </button>
          </div>
        ) : undefined
      }
    />
  )
}

function NetworkCard({ title, subtitle, icon, selected, onClick }: {
  title: string; subtitle: string; icon: React.ReactNode; selected: boolean; onClick: () => void
}) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', flexDirection: 'row', alignItems: 'stretch',
      width: 160, border: `0.5px solid ${selected ? 'rgba(59,130,246,0.3)' : 'var(--color-border)'}`,
      borderRadius: 8, background: selected ? 'var(--color-primary-bg)' : 'var(--color-surface)',
      cursor: 'pointer', padding: 0, overflow: 'hidden', transition: 'all 0.15s',
    }}>
      <div style={{
        width: 2, background: selected ? 'var(--color-primary)' : 'transparent',
        borderRadius: 1, margin: '8px 0', transition: 'background 0.15s',
      }} />
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
        padding: '16px 0', gap: 4,
      }}>
        <span style={{ color: selected ? 'var(--color-primary)' : 'var(--color-secondary)' }}>{icon}</span>
        <span style={{ fontSize: 13, fontWeight: 500, color: 'var(--color-text)' }}>{title}</span>
        <span style={{ fontSize: 11, color: 'var(--color-secondary)' }}>{subtitle}</span>
      </div>
    </button>
  )
}
