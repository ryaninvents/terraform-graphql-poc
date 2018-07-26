const PERMITTED_HEADERS = [
  'Content-Type',
  'X-Amz-Date',
  'Authorization',
  'X-Api-Key',
  'X-Amz-Security-Token',
  'Cookie'
].join(',')

exports.cors = function cors (event, context, callback) {
  console.log(JSON.stringify({
    what: 'cors',
    event,
    context
  }))

  const origin = event.headers.Origin || event.headers.origin || ''
  const originMatch = origin === process.env.FRONTEND_ORIGIN || origin.indexOf('http://localhost') === 0

  try {
    callback(null, {
      statusCode: 200,
      headers: {
        ...(originMatch ? {
          'Access-Control-Allow-Origin': origin,
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'POST,OPTIONS',
          'Access-Control-Allow-Headers': PERMITTED_HEADERS
        } : {})
      }
    })
  } catch (error) {
    console.log(error)
    callback(error)
  }
}
