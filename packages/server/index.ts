'use strict'

export function handler (event: Object, context: Object, callback: (error: Error | null, response: Object) => void) {
  const response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8'
    },
    body: `<p>Hello world!</p><pre>${JSON.stringify({event}, null, 2)}</pre>`
  }
  callback(null, response)
}
