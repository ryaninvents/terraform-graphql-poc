import * as server from 'apollo-server-lambda'
import {makeExecutableSchema} from 'graphql-tools'

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

console.log('hello')

export function handler (event, context, callback) {
  console.log(JSON.stringify(event))
  const details = {
    resource: event.resource,
    path: event.path,
    headers: event.headers,
    queryStringParameters: event.queryStringParameters
  }
  const response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8'
    },
    body: `<p>Hello world!</p><pre>${JSON.stringify(details, null, 2)}</pre>`
  }
  callback(null, response)
}
