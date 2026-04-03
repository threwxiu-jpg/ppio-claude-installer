import https from 'https'
import http from 'http'

export async function validateAPI(apiKey: string, modelID: string, baseUrl: string): Promise<{ success: boolean; error?: string }> {
  return new Promise((resolve) => {
    const body = JSON.stringify({
      model: modelID,
      max_tokens: 5,
      messages: [{ role: 'user', content: 'hi' }],
    })

    let parsed: URL
    try {
      parsed = new URL(baseUrl + '/v1/messages')
    } catch {
      return resolve({ success: false, error: 'Base URL 格式无效' })
    }

    const isHttps = parsed.protocol === 'https:'
    const transport = isHttps ? https : http

    const req = transport.request({
      hostname: parsed.hostname,
      port: parsed.port || (isHttps ? 443 : 80),
      path: parsed.pathname + parsed.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Length': Buffer.byteLength(body),
      },
      timeout: 30000,
    }, (res) => {
      let data = ''
      res.on('data', (chunk) => { data += chunk })
      res.on('end', () => {
        const status = res.statusCode || 0
        if (status === 200) {
          resolve({ success: true })
        } else if (status === 401) {
          resolve({ success: false, error: 'API Key 无效' })
        } else if (status === 403) {
          resolve({ success: false, error: '访问被拒绝' })
        } else if (status === 404) {
          resolve({ success: false, error: '模型不存在' })
        } else if (status === 429) {
          resolve({ success: false, error: '请求过于频繁' })
        } else if (status >= 500) {
          resolve({ success: false, error: `服务端错误 (${status})` })
        } else {
          resolve({ success: false, error: `未知错误 (${status})` })
        }
      })
    })

    req.on('error', (err) => {
      if (err.message.includes('ETIMEDOUT') || err.message.includes('timeout')) {
        resolve({ success: false, error: '连接超时' })
      } else {
        resolve({ success: false, error: err.message })
      }
    })

    req.on('timeout', () => {
      req.destroy()
      resolve({ success: false, error: '连接超时（30s）' })
    })

    req.write(body)
    req.end()
  })
}
