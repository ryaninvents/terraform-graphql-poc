import * as server from 'apollo-server-lambda'
import {makeExecutableSchema} from 'graphql-tools'
import fetch from 'node-fetch'
import redis from 'redis'

// Construct a schema, using GraphQL schema language
const typeDefs = `
  type Query {
    hello: String
    now: String
  }
`

// Provide resolver functions for your schema fields
const resolvers = {
  Query: {
    hello: () => 'Hello world!',
    now: () => new Date().toISOString()
  }
}

const schema = makeExecutableSchema({
  typeDefs,
  resolvers
})

const graphqlHandler = server.graphqlLambda({schema})
export const graphql = (event, context, callback) => {
  const originMatch = event.headers.origin === process.env.FRONTEND_ORIGIN
  console.log(JSON.stringify({
    event,
    context,
    env: process.env,
    originMatch,
    acao: originMatch ? event.headers.FRONTEND_ORIGIN : 'no_match'
  }))
  graphqlHandler(event, context, (err, response) => {
    if (err) {
      callback(err)
      return
    }
    callback(null, {
      ...response,
      headers: {
        ...response.headers,
        ...(originMatch ? {'Access-Control-Allow-Origin': event.headers.origin} : {})
      }
    })
  })
}
export const graphiql = server.graphiqlLambda({
  endpointURL: `' + (document.location.pathname.indexOf('/test') === 0 ? '/test' : '') + '/graphql`
})

export async function handler (event, context, callback) {
  const client = redis.createClient({
    host: process.env.REDIS_HOST,
    port: Number(process.env.REDIS_PORT)
  })

  console.log({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
  })

  function setCache (key, val) {
    return new Promise((resolve, reject) => {
      client.set(key, val, (error, data) => {
        if (error) {
          console.log(error)
          reject(error)
          return
        }
        resolve(data)
      })
    })
  }

  function getCache (key) {
    return new Promise((resolve, reject) => {
      client.get(key, (error, data) => {
        if (error) {
          console.log(error)
          reject(error)
          return
        }
        if (!data) {
          resolve(null)
          return
        }
        resolve(data.toString())
      })
    })
  }

  try {
    const count = Number((await getCache('visitcount')) || 0)
    console.log({count})
    await setCache('visitcount', count + 1)

    const json = await (
      await fetch('https://raw.githubusercontent.com/ryaninvents/ng-notable/master/package.json')
    ).json()

    let sessionId
    let sessionIdMatch = /session=([0-9a-f]+)/.exec(event.headers.Cookie)
    if (sessionIdMatch) {
      sessionId = sessionIdMatch[1]
    } else {
      sessionId = Math.random().toString(16).slice(2)
    }

    const details = {
      visits: count + 1,
      resource: event.resource,
      path: event.path,
      headers: event.headers,
      queryStringParameters: event.queryStringParameters,
      json
    }
    const response = {
      statusCode: 200,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Set-Cookie': `session=${sessionId}; domain=ryaninvents.com; expires=${new Date().toISOString()}`
      },
      body: `<p>Hello world!</p><pre>${JSON.stringify(details, null, 2)}</pre>`
    }
    callback(null, response)
  } catch (error) {
    callback(error)
  } finally {
    client.quit()
  }
}
