import * as server from 'apollo-server-lambda'
import {makeExecutableSchema} from 'graphql-tools'
import fetch from 'node-fetch'
import redis from 'redis'

// Construct a schema, using GraphQL schema language
const typeDefs = `
  type Query {
    hello: String
    now: String
    loggedIn: Boolean!
    whoami: String
  }
`

// Provide resolver functions for your schema fields
const resolvers = {
  Query: {
    hello: () => 'Hello world!',
    now: () => new Date().toISOString(),
    loggedIn: (obj, args, context) => Boolean(context.user),
    whoami: (obj, args, context) => context.user ? context.user.displayName : null
  }
}

const schema = makeExecutableSchema({
  typeDefs,
  resolvers
})

const graphqlHandler = server.graphqlLambda({
  schema,
  context: ({event, context}) => ({
    event,
    context,
    user: event.requestContext.authorizer.userData ? JSON.parse(event.requestContext.authorizer.userData) : null
  })
})
export const graphql = (event, context, callback) => {
  console.log(JSON.stringify({event, context}))
  const originMatch = event.headers.origin === process.env.FRONTEND_ORIGIN || event.headers.origin === 'http://localhost:8080'

  graphqlHandler(event, context, (err, response) => {
    if (err) {
      callback(err)
      return
    }
    callback(null, {
      ...response,
      headers: {
        ...response.headers,
        ...(originMatch ? {
          'Access-Control-Allow-Origin': event.headers.origin,
          'Access-Control-Allow-Credentials': 'true'
        } : {})
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
    const originMatch = event.headers.origin === process.env.FRONTEND_ORIGIN || event.headers.origin === 'http://localhost:8080'

    const count = Number((await getCache('visitcount')) || 0)
    console.log({count})
    await setCache('visitcount', count + 1)

    const json = await (
      await fetch('https://raw.githubusercontent.com/ryaninvents/ng-notable/master/package.json')
    ).json()

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
        'Content-Type': 'application/json',
        ...(originMatch ? {
          'Access-Control-Allow-Origin': event.headers.origin,
          'Access-Control-Allow-Credentials': 'true'
        } : {})
      },
      body: JSON.stringify(details, null, 2)
    }
    callback(null, response)
  } catch (error) {
    callback(error)
  } finally {
    client.quit()
  }
}
