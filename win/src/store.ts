import { useReducer, createContext, useContext } from 'react'
import { AppState, initialState, Step, STEPS } from './types'

type Action =
  | { type: 'GO_NEXT' }
  | { type: 'GO_BACK' }
  | { type: 'SET_STEP'; step: Step }
  | { type: 'UPDATE'; payload: Partial<AppState> }
  | { type: 'UPDATE_DEPENDENCY'; id: string; payload: Partial<AppState['dependencies'][0]> }

function reducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case 'GO_NEXT': {
      const idx = STEPS.indexOf(state.step)
      if (idx < STEPS.length - 1) return { ...state, step: STEPS[idx + 1] }
      return state
    }
    case 'GO_BACK': {
      const idx = STEPS.indexOf(state.step)
      if (idx > 0) return { ...state, step: STEPS[idx - 1] }
      return state
    }
    case 'SET_STEP':
      return { ...state, step: action.step }
    case 'UPDATE':
      return { ...state, ...action.payload }
    case 'UPDATE_DEPENDENCY':
      return {
        ...state,
        dependencies: state.dependencies.map((d) =>
          d.id === action.id ? { ...d, ...action.payload } : d
        ),
      }
    default:
      return state
  }
}

export type Dispatch = React.Dispatch<Action>

export const StateContext = createContext<AppState>(initialState)
export const DispatchContext = createContext<Dispatch>(() => {})

export function useAppState() {
  return useContext(StateContext)
}

export function useDispatch() {
  return useContext(DispatchContext)
}

export function useStore() {
  return useReducer(reducer, initialState)
}
