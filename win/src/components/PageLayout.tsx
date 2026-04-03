import React from 'react'

interface PageLayoutProps {
  title: React.ReactNode
  content: React.ReactNode
  actions?: React.ReactNode
}

export function PageLayout({ title, content, actions }: PageLayoutProps) {
  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      height: '100%',
    }}>
      {/* Title area */}
      <div style={{
        textAlign: 'center',
        paddingTop: 32,
        paddingBottom: 20,
        flexShrink: 0,
      }}>
        {title}
      </div>

      {/* Content area — flex grow, vertically centered */}
      <div style={{
        flex: 1,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'auto',
      }}>
        <div style={{ maxWidth: 420, width: '100%', padding: '0 20px' }}>
          {content}
        </div>
      </div>

      {/* Actions area */}
      {actions && (
        <div style={{
          textAlign: 'center',
          paddingBottom: 32,
          flexShrink: 0,
        }}>
          {actions}
        </div>
      )}
    </div>
  )
}
