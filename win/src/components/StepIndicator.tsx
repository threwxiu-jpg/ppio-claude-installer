import { Wrench, Key, Cpu, ShieldCheck, Settings } from 'lucide-react'
import { Step, STEPS } from '../types'

const INDICATOR_STEPS: { step: Step; icon: React.ReactNode }[] = [
  { step: 'dependencyCheck', icon: <Wrench size={9} /> },
  { step: 'apiKeyInput', icon: <Key size={9} /> },
  { step: 'modelSelection', icon: <Cpu size={9} /> },
  { step: 'validation', icon: <ShieldCheck size={9} /> },
  { step: 'installConfig', icon: <Settings size={9} /> },
]

interface StepIndicatorProps {
  currentStep: Step
}

export function StepIndicator({ currentStep }: StepIndicatorProps) {
  const currentIdx = STEPS.indexOf(currentStep)

  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 0,
      padding: '0 80px',
    }}>
      {INDICATOR_STEPS.map((s, i) => {
        const stepIdx = STEPS.indexOf(s.step)
        const isActive = stepIdx <= currentIdx
        const isCurrent = s.step === currentStep

        return (
          <div key={s.step} style={{ display: 'flex', alignItems: 'center' }}>
            {i > 0 && (
              <div style={{
                width: 32,
                height: 1,
                background: isActive ? 'var(--color-primary)' : 'var(--color-border)',
                transition: 'background 0.3s',
              }} />
            )}
            <div style={{
              width: 22,
              height: 22,
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: isActive ? 'var(--color-primary)' : 'var(--color-surface)',
              color: isActive ? 'white' : 'var(--color-tertiary)',
              border: isActive ? 'none' : '1px solid var(--color-border)',
              transition: 'all 0.3s',
              transform: isCurrent ? 'scale(1.1)' : 'scale(1)',
            }}>
              {s.icon}
            </div>
          </div>
        )
      })}
    </div>
  )
}
