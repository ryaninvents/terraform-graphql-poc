import express from 'express'
import passport from 'passport'
import serverless from 'serverless-http'
import session from 'express-session'
import createRedisStore from 'connect-redis'

import getHandler from 'serverless-http/lib/get-handler'
import cleanUpEvent from 'serverless-http/lib/clean-up-event'
import finishHttp from 'serverless-http/lib/finish'
import ExpressRequest from 'serverless-http/lib/request'
import ExpressResponse from 'serverless-http/lib/response'

import './config'
import {generateAllowPolicy} from './generatePolicy'

const app = express()

const RedisStore = createRedisStore(session)

app.use((...args) => {
  const [, res] = args

  const store = new RedisStore({
    host: process.env.REDIS_HOST,
    port: Number(process.env.REDIS_PORT)
  })

  res.on('finish', () => {
    store.client.quit()
  })

  const useSession = session({
    store,
    secret: 'keyboard catz',
    resave: false
  })

  useSession(...args)
})

app.use(passport.initialize())
app.use(passport.session())

function authenticate (req, res, next) {
  passport.authenticate('auth0', {
    domain: process.env.AUTH0_DOMAIN,
    clientID: process.env.AUTH0_CLIENT_ID,
    clientSecret: process.env.AUTH0_CLIENT_SECRET,
    callbackURL: process.env.CALLBACK_URL,
    audience: `https://${process.env.AUTH0_DOMAIN}/userinfo`,
    responseType: 'code',
    scope: 'openid profile email'
  }, (err, user, info) => {
    if (err) {
      next(err)
      return
    }
    console.log(user)
    req.session.user = user
    res.redirect(process.env.FRONTEND_ORIGIN)
  })(req, res, next)
}

app.get('/login', authenticate)

export const login = serverless(app)

const appHandler = getHandler(app)

export async function authorizer (event, context, callback) {
  try {
    const cleanEvent = cleanUpEvent({...event})
    cleanEvent.headers.Cookie = event.authorizationToken
    console.log(JSON.stringify({what: 'authorizer', event, cleanEvent}))

    const request = new ExpressRequest(cleanEvent, {})
    await finishHttp(request, cleanEvent, context)

    const response = new ExpressResponse(request)
    appHandler(request, response)
    await finishHttp(response, event, context)

    const user = request.session && request.session.user

    const policy = generateAllowPolicy({
      principalId: user ? user.id : 'anonymous',
      resource: event.methodArn,
      user
    })

    console.log(JSON.stringify({user, session: request.session, policy}))

    callback(null, policy)
  } catch (error) {
    console.log('Critical error!')
    console.log(error)
    callback(new Error('Server error'))
  }
}
