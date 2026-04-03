import { StateContext, DispatchContext, useStore, useAppState } from './store'
import { StepIndicator } from './components/StepIndicator'
import { Welcome } from './pages/Welcome'
import { DependencyCheck } from './pages/DependencyCheck'
import { NetworkSelection } from './pages/NetworkSelection'
import { APIKeyInput } from './pages/APIKeyInput'
import { ModelSelection } from './pages/ModelSelection'
import { Validation } from './pages/Validation'
import { InstallConfig } from './pages/InstallConfig'
import { Completion } from './pages/Completion'

function StepRouter() {
  const state = useAppState()
  switch (state.step) {
    case 'welcome': return <Welcome />
    case 'dependencyCheck': return <DependencyCheck />
    case 'networkSelection': return <NetworkSelection />
    case 'apiKeyInput': return <APIKeyInput />
    case 'modelSelection': return <ModelSelection />
    case 'validation': return <Validation />
    case 'installConfig': return <InstallConfig />
    case 'completion': return <Completion />
  }
}

function AppContent() {
  const state = useAppState()
  const showIndicator = !['welcome', 'networkSelection', 'completion'].includes(state.step)

  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      {showIndicator && (
        <div style={{ paddingTop: 16, flexShrink: 0 }}>
          <StepIndicator currentStep={state.step} />
        </div>
      )}
      <div style={{ flex: 1, overflow: 'hidden' }}>
        <StepRouter />
      </div>
    </div>
  )
}

export default function App() {
  const [state, dispatch] = useStore()

  return (
    <StateContext.Provider value={state}>
      <DispatchContext.Provider value={dispatch}>
        <AppContent />
      </DispatchContext.Provider>
    </StateContext.Provider>
  )
}
