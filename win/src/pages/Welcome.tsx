import { Zap, Shield, Settings, Terminal } from 'lucide-react'
import { PageLayout } from '../components/PageLayout'
import { useDispatch } from '../store'

const features = [
  { icon: <Zap size={13} />, text: '自动检测并安装依赖' },
  { icon: <Shield size={13} />, text: '验证 API 连接' },
  { icon: <Settings size={13} />, text: '写入配置文件' },
  { icon: <Terminal size={13} />, text: '即刻开始使用 Claude Code' },
]

export function Welcome() {
  const dispatch = useDispatch()

  return (
    <PageLayout
      title={
        <div>
          <div style={{ fontSize: 22, fontWeight: 600 }}>PP Claude Installer</div>
          <div style={{ fontSize: 13, color: 'var(--color-secondary)', marginTop: 4 }}>
            安装助手 · v1.0.0
          </div>
        </div>
      }
      content={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {features.map((f, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, color: 'var(--color-secondary)' }}>
              <span style={{ flexShrink: 0 }}>{f.icon}</span>
              <span style={{ fontSize: 13 }}>{f.text}</span>
            </div>
          ))}
        </div>
      }
      actions={
        <button className="btn-primary" onClick={() => dispatch({ type: 'GO_NEXT' })}>
          开始安装
        </button>
      }
    />
  )
}
