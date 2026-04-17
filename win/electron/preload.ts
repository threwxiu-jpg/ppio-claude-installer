import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('electronAPI', {
  runCommand: (command: string) => ipcRenderer.invoke('run-command', command),
  checkDependency: (id: string) => ipcRenderer.invoke('check-dependency', id),
  installDependency: (id: string, useMirror: boolean) => ipcRenderer.invoke('install-dependency', id, useMirror),
  checkNetworkSpeed: () => ipcRenderer.invoke('check-network-speed'),
  validateAPI: (apiKey: string, modelID: string, baseUrl: string) => ipcRenderer.invoke('validate-api', apiKey, modelID, baseUrl),
  writeConfig: (apiKey: string, modelID: string, baseUrl: string) => ipcRenderer.invoke('write-config', apiKey, modelID, baseUrl),
  detectConflicts: () => ipcRenderer.invoke('detect-conflicts'),
  runDiagnostics: (apiKey: string, modelID: string, baseUrl: string) => ipcRenderer.invoke('run-diagnostics', apiKey, modelID, baseUrl),
  openPowerShell: () => ipcRenderer.invoke('open-powershell'),
  quitApp: () => ipcRenderer.invoke('quit-app'),
  openExternal: (url: string) => ipcRenderer.invoke('open-external', url),
  onInstallProgress: (cb: (data: { id: string; line: string }) => void) => {
    const handler = (_e: any, data: any) => cb(data)
    ipcRenderer.on('install-progress', handler)
    return () => { ipcRenderer.removeListener('install-progress', handler) }
  },
})
