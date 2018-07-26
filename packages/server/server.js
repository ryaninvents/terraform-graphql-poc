import {ApolloServer} from 'apollo-server-lambda'

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

const graphqlHandler = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({event, context}) => ({
    event,
    context,
    user: (event.requestContext && event.requestContext.authorizer && event.requestContext.authorizer.userData) ? JSON.parse(event.requestContext.authorizer.userData) : null
  })
}).createHandler()

export const graphql = async (event, context, callback) => {
  try {
    console.log(JSON.stringify({event, context}))

    const origin = event.headers.Origin || event.headers.origin || ''
    const originMatch = origin === process.env.FRONTEND_ORIGIN || origin.indexOf('http://localhost') === 0

    const response = await new Promise((resolve, reject) => {
      graphqlHandler(event, context, (err, response) => {
        if (err) {
          reject(err)
          return
        }
        resolve(response)
      })
    })

    console.log(JSON.stringify({response}))

    callback(null, {
      ...response,
      headers: {
        ...response.headers,
        ...(originMatch ? {
          'Access-Control-Allow-Origin': origin,
          'Access-Control-Allow-Credentials': 'true'
        } : {})
      }
    })
  } catch (error) {
    console.log(error)
    callback(error)
  }
}
